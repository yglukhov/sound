import jnim
import math, times, logging, posix, strutils
import opensl
import android/ndk/aasset_manager
import android/app/activity
import android/content/res/asset_manager
import android/content/context

type
  Flag = enum
    fLooping
    fAssetOrFile # true if android asset, false if regular file

  Sound* = ref object
    player: SLObjectItf
    path: string
    mGain: float32
    fd: cint
    pausePosition: SLmillisecond
    flags: set[Flag]
    mState: State

  State = enum
    sStopped
    sPlaying
    sPaused
    sPlayingPastEnd
    sPausedPastEnd

var engineInited = false

var gJAssetManager: AssetManager # Used to keep the reference alive
var gAssetManager : AAssetManager
var gEngine : SLEngineItf
var gOutputMix : SLObjectItf

const TRASH_TIMEOUT = 0.1
var gTrash: seq[tuple[item: SLObjectItf, fd: cint, time: float]]

proc setFlag[T](s: var set[T], v: T, f: bool) {.inline.} =
  if f: s.incl(v)
  else: s.excl(v)

proc initSoundEngineWithActivity(a: Activity) =
  gJAssetManager = a.getApplication().getAssets()
  gAssetManager = gJAssetManager.getNative()

proc initSoundEngineWithActivity*(a: jobject) =
  initSoundEngineWithActivity(Activity.fromJObject(a))

proc initEngine() =
  if engineInited: return
  if gAssetManager.isNil:
    let a = currentActivityIfPresent()
    if not a.isNil:
      initSoundEngineWithActivity(a)
    if gAssetManager.isNil:
      raise newException(Exception, "Sound engine on Android should be initialized by initSoundEngineWithActivity.")
  engineInited = true
  var engine: SLObjectItf
  var res = slCreateEngine(engine, [], [SL_IID_ENGINE], [SL_TRUE])
  if res != SL_RESULT_SUCCESS: return
  assert(not engine.isNil)
  res = engine.realize()
  if res != SL_RESULT_SUCCESS: return
  res = engine.getInterface(gEngine)
  res = gEngine.createOutputMix(gOutputMix, [], [])
  res = gOutputMix.realize()

proc newSoundWithURL*(url: string): Sound =
  ## Play sound from inside APK file
  initEngine()
  result = Sound(mGain: 1, fd: -1)
  if url.startsWith("android_asset://"):
    result.path = url.substr("android_asset://".len)
    result.flags.incl(fAssetOrFile)
  elif url.startsWith("file://"):
    result.path = url.substr("file://".len)
  else:
    raise newException(Exception, "Unknown URL: " & url)

proc newSoundWithFile*(path: string): Sound = # Deprecated... kinda...
  ## Play sound from inside APK file
  initEngine()
  Sound(path: path, flags: {fAssetOrFile}, mGain: 1, fd: -1)

type ResourseDescriptor {.exportc.} = object
  descriptor: int32
  start: int
  length: int

proc loadResourceDescriptorFromAndroidAsset(path: string): ResourseDescriptor =
  var loaded = false
  let asset = gAssetManager.open(path, AASSET_MODE_UNKNOWN)
  if not asset.isNil:
    result.descriptor = asset.openFileDescriptor(addr result.start, addr result.length)
    asset.close()
    if result.descriptor >= 0:
      loaded = true
  if not loaded:
    raise newException(Exception, "File " & $path & " could not be loaded")

proc loadResourceDescriptorFromFilePath(path: string): ResourseDescriptor =
  result.descriptor = open(path, O_RDONLY)
  result.start = 0
  result.length = lseek(result.descriptor, 0, SEEK_END).int32
  discard lseek(result.descriptor, 0, SEEK_SET)

proc gainToAttenuation(gain: float): float {.inline.} =
  if gain < 0.01: -96.0 else: 20 * log10(gain)

proc setGain(pl: SLObjectItf, v: float) =
  assert(not pl.isNil)
  var volume: SLVolumeItf
  let res = pl.getInterface(volume)
  if res == SL_RESULT_SUCCESS:
    let a = gainToAttenuation(v)
    discard volume.setVolumeLevel(SLmillibel(a * 100))

proc setLooping(pl: SLObjectItf, flag: bool) =
  assert(not pl.isNil)
  var seek: SLSeekItf
  let res = pl.getInterface(seek)
  if res == SL_RESULT_SUCCESS:
    discard seek.setLoop(flag, 0, SL_TIME_UNKNOWN)

proc setLooping*(s: Sound, flag: bool) =
  s.flags.setFlag(fLooping, flag)
  let pl = s.player
  if not pl.isNil:
    pl.setLooping(flag)

var activeSounds: seq[Sound]

proc playState(pl: SLObjectItf): SLPlayState =
  assert(not pl.isNil)
  var player: SLPlayItf
  discard pl.getInterface(player)
  discard player.getPlayState(result)

proc restart(pl: SLObjectItf) {.inline.} =
  assert(not pl.isNil)
  var player: SLPlayItf
  discard pl.getInterface(player)
  discard player.setPlayState(SL_PLAYSTATE_STOPPED)
  discard player.setPlayState(SL_PLAYSTATE_PLAYING)

proc setPlayState(pl: SLObjectItf, state: SLPlayState) =
  assert(not pl.isNil)
  var player: SLPlayItf
  discard pl.getInterface(player)
  discard player.setPlayState(state)

proc getPlayState(pl: SLPlayItf): SLPlayState {.inline.} =
  discard pl.getPlayState(result)

# Destroying OpenSL players may cause dead lock.
# It's a system issue :(
# For more information:
# https://groups.google.com/forum/#!msg/android-ndk/zANdS2n2cQI/AT6q1F3nNGIJ
# The best workaround we could find for now is deleting players in background
# threads, and if they hang just ignore it. Timeouts and and waiting for
# stopped-state still do not guarantee success, but somehow may reduce
# reproducibility, so we do it anyway.

var deletionThreads = 0

{.push stackTrace: off.}
proc deletionThread(p: pointer): pointer {.noconv.} =
  atomicInc deletionThreads
  let item = cast[SLObjectItf](p)
  item.destroy()
  discard atomicDec deletionThreads
{.pop.}

proc collectTrash() {.inline.} =
  let dt = deletionThreads
  if dt > 0:
    warn "OpenSL PlayerDestroy threads: ", dt

  let curTime = epochTime()
  var i = 0
  while i < gTrash.len:
    var (item, fd, time) = gTrash[i]
    if abs(time - curTime) > TRASH_TIMEOUT:
      var player: SLPlayItf
      discard item.getInterface(player)
      if getPlayState(player) == SL_PLAYSTATE_STOPPED:
        if fd >= 0:
          discard close(fd)
        var t: Pthread
        discard pthread_create(addr t, nil, deletionThread, item)
        discard pthread_detach(t)
        gTrash.del(i)
      else:
        discard setPlayState(player, SL_PLAYSTATE_STOPPED)
        inc i
    else:
      inc i

proc destroy(pl: SLObjectItf, fd: cint) =
  assert(not pl.isNil)
  collectTrash()
  setPlayState(pl, SL_PLAYSTATE_STOPPED)
  gTrash.add( (item: pl, fd: fd, time: epochTime()) )

proc collectInactiveSounds() {.inline.} =
  for i in 0 ..< activeSounds.len:
    let s = activeSounds[i]
    let pl = s.player
    # Some Androids have an bug in OpenSLES that results in reporting
    # SL_PLAYSTATE_PAUSED for actually active looping players that have gone
    # through one loop and continue playing, so we cannot dispose looping
    # players here. Instead they may be disposed in stop().
    if not pl.isNil and fLooping notin s.flags and pl.playState != SL_PLAYSTATE_PLAYING:
      pl.destroy(s.fd)
      s.player = nil
      s.fd = -1
      s.mState = sPlayingPastEnd
      activeSounds.del(i)
      break

proc play*(s: Sound) =
  if s.mState == sPausedPastEnd:
    s.mState = sPlayingPastEnd
    return

  # Define which sound is stopped and can be reused
  var pl = s.player
  if pl.isNil:
    collectInactiveSounds()

    var rd: ResourseDescriptor
    if fAssetOrFile in s.flags:
      rd = loadResourceDescriptorFromAndroidAsset(s.path)
    else:
      rd = loadResourceDescriptorFromFilePath(s.path)
    s.fd = rd.descriptor
    var locatorIn = SLDataLocator_AndroidFD(
      locatorType: SL_DATALOCATOR_TYPE_ANDROIDFD,
      fd: rd.descriptor,
      offset: rd.start,
      length: rd.length)

    var dataFormat = SLDataFormat_MIME(
      formatType: SL_DATAFORMAT_TYPE_MIME,
      containerType: SL_CONTAINERTYPE_UNSPECIFIED)

    var audioSrc = SLDataSource(
      locator: addr locatorIn,
      format: addr dataFormat)

    var dataLocatorOut = SLDataLocator_OutputMix(
      locatorType: SL_DATALOCATOR_TYPE_OUTPUTMIX,
      outputMix: gOutputMix)

    var audioSnk = SLDataSink(locator: addr dataLocatorOut)
    let res = gEngine.createAudioPlayer(pl, addr audioSrc, addr audioSnk,
      [SL_IID_PLAY, SL_IID_SEEK, SL_IID_VOLUME], [SL_TRUE, SL_TRUE, SL_TRUE])

    if res == SL_RESULT_SUCCESS:
      discard pl.realize()
      s.player = pl
      if not pl.isNil:
        var seek: SLSeekItf
        if pl.getInterface(seek) == SL_RESULT_SUCCESS:
          discard seek.setLoop(fLooping in s.flags, 0, SL_TIME_UNKNOWN)
          if s.pausePosition != 0:
            discard seek.setPosition(s.pausePosition, SL_SEEKMODE_FAST)
        s.pausePosition = 0

        pl.setGain(s.mGain)

      activeSounds.add(s)
    else:
      pl = nil
      if s.fd >= 0:
        discard close(s.fd)
        s.fd = -1
      return

  case s.mState
  of sPaused, sStopped:
    pl.setPlayState(SL_PLAYSTATE_PLAYING)
    s.mState = sPlaying
  of sPlaying, sPlayingPastEnd:
    pl.restart()
    s.mState = sPlaying
  of sPausedPastEnd:
    # Should not get here. Tested at the beginning of this proc.
    s.mState = sPlayingPastEnd

proc clear(s: Sound) =
  let pl = s.player
  assert(not pl.isNil)

  for i in 0 ..< activeSounds.len:
    if s == activeSounds[i]:
      activeSounds.del(i)
      break
  pl.destroy(s.fd)
  s.player = nil
  s.fd = -1

proc stop*(s: Sound) =
  let pl = s.player
  if not pl.isNil:
    pl.setPlayState(SL_PLAYSTATE_STOPPED)
    s.clear()
  s.pausePosition = 0
  s.mState = sStopped

proc pause*(s: Sound) =
  case s.mState
  of sStopped:
    s.mState = sPaused
    s.pausePosition = 0
  of sPaused, sPausedPastEnd:
    discard
  of sPlayingPastEnd:
    s.mState = sPausedPastEnd
  of sPlaying:
    assert(not s.player.isNil)
    var player: SLPlayItf
    discard s.player.getInterface(player)
    let slState = player.getPlayState()
    var pos: SLmillisecond
    discard player.getPosition(pos)
    discard player.setPlayState(SL_PLAYSTATE_STOPPED)
    if slState != SL_PLAYSTATE_PLAYING and fLooping notin s.flags:
      s.mState = sPausedPastEnd
    else:
      s.mState = sPaused
      s.pausePosition = pos
    s.clear()

proc state*(s: Sound): SoundState =
  case s.mState
  of sPaused, sPausedPastEnd: result = paused
  of sPlaying:
    if s.player.playState != SL_PLAYSTATE_PLAYING and fLooping notin s.flags:
      s.mState = sPlayingPastEnd
      result = complete
    else:
      result = playing
  of sStopped: result = stopped
  of sPlayingPastEnd: result = complete

proc duration*(s: Sound): float =
  let pl = s.player
  if not pl.isNil:
    var msDuration = SL_TIME_UNKNOWN
    var player: SLPlayItf
    var res = pl.getInterface(player)

    if res == SL_RESULT_SUCCESS:
      var st = 0.0
      while msDuration == SL_TIME_UNKNOWN and res == SL_RESULT_SUCCESS:
        res = player.getDuration(msDuration)
        if res == SL_RESULT_SUCCESS and msDuration == SL_TIME_UNKNOWN:
          if st == 0.0:
            st = epochTime()
          elif epochTime() - st > 0.2:
            msDuration = 1000

            break
    result = float(msDuration) * 0.001

#[
proc attenuationToGain(a: float): float {.inline.} =
  if a <= -96.0: return 0
  result = a / 20
  result = pow(10, result)
]#

proc `gain=`*(s: Sound, v: float) =
  s.mGain = v
  let pl = s.player
  if not pl.isNil:
    pl.setGain(v)

proc gain*(s: Sound): float {.inline.} = s.mGain

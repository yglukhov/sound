import openal, data_source_al
import streams, logging, strutils

type
  Flag = enum
    fLooping

  Sound* = ref object
    mDataSource: DataSource
    src: ALuint
    pauseOffset: ALint
    mGain: ALfloat
    mState: State
    flags: set[Flag]

  State = enum
    sStopped
    sPlaying
    sPaused
    sPlayingPastEnd
    sPausedPastEnd

var activeSounds: seq[Sound]

proc setFlag[T](s: var set[T], v: T, f: bool) {.inline.} =
  if f: s.incl(v)
  else: s.excl(v)

proc newSound(): Sound = Sound(mGain: 1)

proc `dataSource=`(s: Sound, ds: DataSource) = # Private for now. Should be public eventually
  s.mDataSource = ds

proc newSoundWithPCMData*(data: pointer, dataLength, channels, bitsPerSample, samplesPerSecond: int): Sound =
  ## This function is only availbale for openal for now. Sorry.
  result = newSound()
  result.dataSource = newDataSourceWithPCMData(data, dataLength, channels, bitsPerSample, samplesPerSecond)

proc newSoundWithPCMData*(data: openarray[byte], channels, bitsPerSample, samplesPerSecond: int): Sound {.inline.} =
  ## This function is only availbale for openal for now. Sorry.
  newSoundWithPCMData(unsafeAddr data[0], data.len, channels, bitsPerSample, samplesPerSecond)

proc newSoundWithPath*(path: string): Sound =
  result = newSound()
  result.dataSource = newDataSourceWithFile(path)

proc newSoundWithFile*(path: string): Sound = newSoundWithPath(path)

proc newSoundWithURL*(url: string): Sound =
  if url.startsWith("file://"):
    result = newSoundWithPath(url.substr("file://".len))
  else:
    raise newException(Exception, "Unknown URL: " & url)

proc newSoundWithStream*(s: Stream): Sound =
  result = newSound()
  result.dataSource = newDataSourceWithStream(s)

proc sourceState(src: ALuint): ALenum {.inline.} =
  alGetSourcei(src, AL_SOURCE_STATE, addr result)

proc sourceOffset(src: ALuint): ALint {.inline.} =
  alGetSourcei(src, AL_BYTE_OFFSET, addr result)

proc setSourceOffset(src: ALuint, offset: ALint) {.inline.} =
  alSourcei(src, AL_BYTE_OFFSET, offset)

proc duration*(s: Sound): float {.inline.} = s.mDataSource.mDuration

proc setLooping*(s: Sound, flag: bool) =
  s.flags.setFlag(fLooping, flag)
  if s.src != 0:
    alSourcei(s.src, AL_LOOPING, ALint(flag))

proc reclaimInactiveSource(): ALuint {.inline.} =
  for i in 0 ..< activeSounds.len:
    let s = activeSounds[i]
    let src = s.src
    if src.sourceState != AL_PLAYING:
      result = src
      s.src = 0
      case s.mState
      of sPlaying:
        s.mState = sPlayingPastEnd
      else:
        discard
      activeSounds.del(i)
      break

proc stop*(s: Sound) =
  if s.src != 0:
    alSourceStop(s.src)
  s.mState = sStopped
  s.pauseOffset = 0

proc play*(s: Sound) =
  if s.mDataSource.mBuffer != 0:
    if s.mState == sPausedPastEnd:
      s.mState = sPlayingPastEnd
      return

    var src = s.src
    if src == 0:
      src = reclaimInactiveSource()
      if src == 0:
        alGenSources(1, addr src)
      alSourcei(src, AL_BUFFER, cast[ALint](s.mDataSource.mBuffer))
      alSourcef(src, AL_GAIN, s.mGain)
      alSourcei(src, AL_LOOPING, ALint(fLooping in s.flags))
      if s.pauseOffset != 0:
        setSourceOffset(src, s.pauseOffset)
        s.pauseOffset = 0
      s.src = src
      activeSounds.add(s)

    case s.mState
    of sPaused, sStopped:
      alSourcePlay(src)
      s.mState = sPlaying
    of sPlaying, sPlayingPastEnd:
      alSourceStop(src)
      alSourcePlay(src)
      s.mState = sPlaying
    of sPausedPastEnd:
      # Should not get here. Tested at the beginning of this proc.
      s.mState = sPlayingPastEnd

proc pause*(s: Sound) =
  case s.mState
  of sStopped:
    s.mState = sPaused
    s.pauseOffset = 0
  of sPaused, sPausedPastEnd:
    discard
  of sPlayingPastEnd:
    s.mState = sPausedPastEnd
  of sPlaying:
    assert(s.src != 0)
    let alState = s.src.sourceState
    alSourcePause(s.src)
    if alState == AL_STOPPED:
      s.mState = sPausedPastEnd
    else:
      assert(alState == AL_PLAYING)
      s.mState = sPaused
      s.pauseOffset = s.src.sourceOffset

proc state*(s: Sound): SoundState =
  case s.mState
  of sPaused, sPausedPastEnd: result = paused
  of sPlaying:
    let alState = s.src.sourceState
    if alState == AL_STOPPED:
      s.mState = sPlayingPastEnd
      result = complete
    else:
      assert(alState == AL_PLAYING)
      result = playing
  of sStopped: result = stopped
  of sPlayingPastEnd: result = complete

proc `gain=`*(s: Sound, v: float) =
  s.mGain = v
  if s.src != 0:
    alSourcef(s.src, AL_GAIN, v)

proc gain*(s: Sound): float {.inline.} = s.mGain

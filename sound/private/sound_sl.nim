import jnim
import math
import times
import logging
import opensl

{.emit: """/*INCLUDESECTION*/
#include <android/asset_manager_jni.h>
""".}

jclassDef android.content.res.AssetManager of JVMObject

jclass android.app.Application of JVMObject:
    proc getAssets: AssetManager

jclass android.app.Activity of JVMObject:
    proc getApplication: Application

type
    AAssetManager {.importc, incompleteStruct.} = object
    AssetManagerPtr = ptr AAssetManager

type Sound* = ref object
    player: SLObjectItf
    path: string
    mGain: float
    mLooping: bool
    fd: cint

var engineInited = false

var gAssetManager : AssetManagerPtr = nil
var gEngine : SLEngineItf # = nil
var gOutputMix : SLObjectItf

const TRASH_TIMEOUT = 0.5
var gTrash = newSeq[tuple[item: SLObjectItf, fd: cint, time: float]]()

proc initSoundEngineWithActivity*(a: jobject) =
    var am = Activity.fromJObject(a).getApplication().getAssets().get()
    let env = jnim.theEnv
    {.emit: "`gAssetManager` = AAssetManager_fromJava(`env`, `am`);".}

proc initEngine() =
    if engineInited: return
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

proc newSoundWithFile*(path: string): Sound =
    ## Play sound from inside APK file
    initEngine()
    result.new
    result.path = path
    result.player = nil
    result.mGain = 1
    result.fd = -1

type ResourseDescriptor {.exportc.} = object
    descriptor: int32
    start: int32
    length: int32

proc loadResourceDescriptor(path: cstring): ResourseDescriptor =
    var loaded = false
    {.emit: """
    AAsset* asset = AAssetManager_open(`gAssetManager`, `path`, AASSET_MODE_UNKNOWN);
    if (asset) {
        `result`.descriptor = AAsset_openFileDescriptor(asset, &`result`.start, &`result`.length);
        AAsset_close(asset);
        if (`result`.descriptor >= 0) {
            `loaded` = 1;
        }
    }
    """.}
    if not loaded:
        raise newException(Exception, "File " & $path & " could not be loaded")

proc gainToAttenuation(gain: float): float {.inline.} =
    return if gain < 0.01: -96.0 else: 20 * log10(gain)

proc setGain(pl: SLObjectItf not nil, v: float) =
    let a = gainToAttenuation(v)
    var volume: SLVolumeItf
    let res = pl.getInterface(volume)
    if res == SL_RESULT_SUCCESS:
        discard volume.setVolumeLevel(SLmillibel(a * 100))

proc setLooping(pl: SLObjectItf not nil, flag: bool) =
    var seek: SLSeekItf
    let res = pl.getInterface(seek)
    if res == SL_RESULT_SUCCESS:
        discard seek.setLoop(flag, 0, SL_TIME_UNKNOWN)

proc setLooping*(s: Sound, flag: bool) =
    s.mLooping = flag
    let pl = s.player
    if not pl.isNil:
        pl.setLooping(flag)

var activeSounds: seq[Sound]

proc playState(pl: SLObjectItf): SLPlayState =
    if not pl.isNil:
        var player: SLPlayItf
        discard pl.getInterface(player)
        discard player.getPlayState(result)

proc setPlayState(pl: SLObjectItf not nil, state: SLPlayState) =
    var player: SLPlayItf
    discard pl.getInterface(player)
    var seek: SLSeekItf
    discard pl.getInterface(seek)
    discard seek.setLoop(false, 0, SL_TIME_UNKNOWN)
    discard player.setPlayState(state)

proc getPlayState(pl: SLObjectItf): SLPlayState =
    var player: SLPlayItf
    discard pl.getInterface(player)
    discard player.getPlayState(result)

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
proc deletionThread(p: pointer) {.cdecl.} =
    atomicInc deletionThreads
    let item = cast[SLObjectItf](p)
    item.destroy()
    atomicDec deletionThreads
{.pop.}

proc collectTrash()=
    let dt = deletionThreads
    if dt > 0:
        warn "OpenSL PlayerDestroy threads: ", dt

    let curTime = epochTime()
    var i = 0
    while i < gTrash.len:
        var (item, fd, time) = gTrash[i]
        if abs(time - curTime) > TRASH_TIMEOUT:
            if getPlayState(item) == SL_PLAYSTATE_STOPPED:
                {.emit: """
                if (`fd` >= 0) {
                    close(`fd`);
                }
                pthread_t t;
                pthread_create(&t, NULL, `deletionThread`, `item`);
                """.}
                gTrash.del(i)
            else:
                if not item.isNil:
                    setPlayState(item, SL_PLAYSTATE_STOPPED)
                inc i
        else:
            inc i

proc destroy(pl: SLObjectItf not nil, fd: cint) =
    collectTrash()
    setPlayState(pl, SL_PLAYSTATE_STOPPED)
    gTrash.add( (item: pl, fd: fd, time: epochTime()) )

proc stop*(s: Sound) =
    let pl = s.player
    if not pl.isNil:
        pl.setPlayState(SL_PLAYSTATE_STOPPED)
        for i in 0 ..< activeSounds.len:
            if s == activeSounds[i]:
                activeSounds.del(i)
                break
        pl.destroy(s.fd)
        s.player = nil

proc collectInactiveSounds() =
    for i in 0 ..< activeSounds.len:
        let s = activeSounds[i]
        let pl = s.player
        # Some Androids have an bug in OpenSLES that results in reporting
        # SL_PLAYSTATE_PAUSED for actually active looping players that have gone
        # through one loop and continue playing, so we cannot dispose looping
        # players here. Instead they may be disposed in stop().
        if not pl.isNil and not s.mLooping and pl.playState != SL_PLAYSTATE_PLAYING:
            pl.destroy(s.fd)
            s.player = nil
            activeSounds.del(i)
            break

proc assumeNotNil[T](v: T): T not nil {.inline.} =
    ## Workaround for nim bug #5781
    assert(not v.isNil)
    result = cast[T not nil](v)

proc play*(s: Sound) =
    # Define which sound is stopped and can be reused
    var pl = s.player
    if pl.isNil:
        collectInactiveSounds()
    else:
        assumeNotNil(pl).destroy(s.fd)
        s.player = nil
        pl = nil

    let rd = loadResourceDescriptor(s.path)
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
    var slres = gEngine.createAudioPlayer(pl, addr audioSrc, addr audioSnk,
        [SL_IID_PLAY, SL_IID_SEEK, SL_IID_VOLUME], [SL_TRUE, SL_TRUE, SL_TRUE])

    if slres == SL_RESULT_SUCCESS:
        discard pl.realize()
        s.player = pl
        if not pl.isNil:
            pl.assumeNotNil.setLooping(s.mLooping)
            pl.assumeNotNil.setGain(s.mGain)
            pl.assumeNotNil.setPlayState(SL_PLAYSTATE_PLAYING)
        if activeSounds.isNil: activeSounds = @[]
        activeSounds.add(s)
    else:
        s.player = nil

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

proc gain*(s: Sound): float = s.mGain

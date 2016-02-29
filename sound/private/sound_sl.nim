import jnim
import math

{.emit: """/*INCLUDESECTION*/
#include <SLES/OpenSLES_Android.h>
#include <android/asset_manager_jni.h>
""".}

jnimport:
    import android.app.Activity
    import android.app.Application
    import android.content.res.AssetManager

    proc getApplication(a: Activity): Application
    proc getAssets(a: Application): AssetManager

type
    AAssetManager {.importc, incompleteStruct.} = object
    AssetManagerPtr = ptr AAssetManager
    SLObjectItfImpl {.importc: "struct SLObjectItf_", header: "<SLES/OpenSLES.h>", incompleteStruct.} = object
    SLObjectItf {.importc: "SLObjectItf", header: "<SLES/OpenSLES.h>", incompleteStruct.} = ptr ptr SLObjectItfImpl
    SLEngineItf {.importc, header: "<SLES/OpenSLES.h>", incompleteStruct.} = object

type Sound* = ref object
    player: SLObjectItf
    path: string

var engineInited = false

var gAssetManager : AssetManagerPtr = nil
var gEngine : SLEngineItf # = nil
var gOutputMix : SLObjectItf

proc initSoundEngineWithActivity*(a: jobject) =
    var am = Activity(a).getApplication().getAssets()
    let env = jnim.currentEnv
    {.emit: "`gAssetManager` = AAssetManager_fromJava(`env`, `am`);".}

proc initEngine() =
    if engineInited: return
    if gAssetManager.isNil:
        raise newException(Exception, "Sound engine on Android should be initialized by initSoundEngineWithActivity.")
    engineInited = true

    {.emit:"""
    SLObjectItf engine;
    const SLInterfaceID pIDs[1] = {SL_IID_ENGINE};
    const SLboolean pIDsRequired[1]  = {SL_BOOLEAN_TRUE};
    SLresult result = slCreateEngine(&engine, 0, NULL, 1, pIDs, pIDsRequired);

    if(result != SL_RESULT_SUCCESS){
        //LOGE("Error after slCreateEngine");
        return;
    }

    result = (*engine)->Realize(engine, SL_BOOLEAN_FALSE);

    if(result != SL_RESULT_SUCCESS){
        //LOGE("Error after Realize engine");
        return;
    }

    result = (*engine)->GetInterface(engine, SL_IID_ENGINE, &`gEngine`);

    const SLInterfaceID pOutputMixIDs[] = {};
    const SLboolean pOutputMixRequired[] = {};
    result = (*`gEngine`)->CreateOutputMix(`gEngine`, &`gOutputMix`, 0, pOutputMixIDs, pOutputMixRequired);
    result = (*`gOutputMix`)->Realize(`gOutputMix`, SL_BOOLEAN_FALSE);
    """.}

proc newSoundWithFile*(path: string): Sound =
    ## Play sound from inside APK file
    initEngine()
    result.new
    result.path = path
    result.player = nil

type ResourseDescriptor {.exportc.} = object
    decriptor: int32
    start: int32
    length: int32

proc loadResourceDescriptor(path: cstring): ResourseDescriptor =
    var loaded = false
    {.emit: """
    AAsset* asset = AAssetManager_open(`gAssetManager`, path, AASSET_MODE_UNKNOWN);
    if (asset) {
        `loaded` = 1;
        `result`.decriptor = AAsset_openFileDescriptor(asset, &`result`.start, &`result`.length);
        AAsset_close(asset);
    }
    """.}
    if not loaded:
        raise newException(Exception, "File " & $path & " could not be loaded")

proc setLooping*(s: Sound, flag: bool) =
    if not s.player.isNil:
        let pl = s.player
        {.emit: """
        SLSeekItf seek;
        SLresult res = (*`pl`)->GetInterface(`pl`, SL_IID_SEEK, &seek);
        if (res == SL_RESULT_SUCCESS) {
            (*seek)->SetLoop(seek, `flag`, 0, SL_TIME_UNKNOWN);
        }
        """.}

type PlayerPool = seq[SLObjectItf]

var playerPool: PlayerPool = @[]

const
    SL_PLAYSTATE_STOPPED = 0x00000001'u32
    SL_PLAYSTATE_PAUSED = 0x00000002'u32
    SL_PLAYSTATE_PLAYING = 0x00000003'u32

proc playState(pl: SLObjectItf): uint32 =
    if not pl.isNil:
        var state: uint32
        {.emit: """
        SLPlayItf player;
        int res = (*`pl`)->GetInterface(`pl`, SL_IID_PLAY, &player);
        res = (*player)->GetPlayState(player, &`state`);
        """.}
        return state

proc playState*(s: Sound): uint32 =
    return s.player.playState()

proc isPlaying*(s: Sound): bool =
    return s.player.playState() == SL_PLAYSTATE_PLAYING

proc isPaused*(s: Sound): bool =
    return s.player.playState() == SL_PLAYSTATE_PAUSED

proc isStopped*(s: Sound): bool =
    return s.player.playState() == SL_PLAYSTATE_STOPPED

proc canBeFree(p: SLObjectItf): bool =
    return p.playState() != SL_PLAYSTATE_PLAYING

proc setPlayState(pl: SLObjectItf, state: uint32) =
    if not pl.isNil():
        {.emit: """
        SLPlayItf player;
        int res = (*`pl`)->GetInterface(`pl`, SL_IID_PLAY, &player);
        SLSeekItf seek;
        res = (*`pl`)->GetInterface(`pl`, SL_IID_SEEK, &seek);
        (*seek)->SetLoop(seek, SL_BOOLEAN_FALSE, 0, SL_TIME_UNKNOWN);
        (*player)->SetPlayState(player, `state`);
        """.}

proc setPlayState(s: Sound, state: uint32) =
    if not s.player.isNil:
        let pl = s.player
        pl.setPlayState(state)

proc stop*(s: Sound) {.inline.} =
    s.setPlayState(SL_PLAYSTATE_STOPPED)

proc play*(s: Sound) =
    # Define which sound is stopped and can be reused
    var sindex = -1
    var pl: SLObjectItf
    var slres = 0'u32

    for i in 0 ..< playerPool.len():
        if canBeFree(playerPool[i]):
            sindex = i
            break
    if sindex != -1:
        pl = playerPool[sindex]
        s.stop()
        {.emit: """
            (*`pl`)->Destroy(`pl`);
        """.}

    let rd = loadResourceDescriptor(s.path)

    {.emit: """
    SLDataLocator_AndroidFD locatorIn = {
        SL_DATALOCATOR_ANDROIDFD,
        `rd`.decriptor,
        `rd`.start,
        `rd`.length
    };

    SLDataFormat_MIME dataFormat = {
        SL_DATAFORMAT_MIME,
        NULL,
        SL_CONTAINERTYPE_UNSPECIFIED
    };

    SLDataSource audioSrc = {&locatorIn, &dataFormat};

    SLDataLocator_OutputMix dataLocatorOut = {
        SL_DATALOCATOR_OUTPUTMIX,
        `gOutputMix`
    };

    SLDataSink audioSnk = {&dataLocatorOut, NULL};
    const SLInterfaceID pIDs[] = {SL_IID_PLAY, SL_IID_SEEK, SL_IID_VOLUME};
    const SLboolean pIDsRequired[] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
    `slres` = (*`gEngine`)->CreateAudioPlayer(`gEngine`, &`pl`, &audioSrc, &audioSnk, 3, pIDs, pIDsRequired);
    if (`slres` == SL_RESULT_SUCCESS) {
        `slres` = (*`pl`)->Realize(`pl`, SL_BOOLEAN_FALSE);
    }
    """.}
    s.player = pl

    if sindex == -1:
        playerPool.add(pl)

    s.setPlayState(SL_PLAYSTATE_PLAYING)

proc duration*(s: Sound): float =
    if not s.player.isNil:
        var msDuration : uint32
        let pl = s.player
        {.emit: """
        SLPlayItf player;
        int res = (*`pl`)->GetInterface(`pl`, SL_IID_PLAY, &player);
        if (res == SL_RESULT_SUCCESS) {
            res = (*player)->GetDuration(player, &`msDuration`);
        }
        """.}
        result = float(msDuration) * 0.001

proc gainToAttenuation(gain: float): float {.inline.} =
    return if gain < 0.01: -96.0 else: 20 * log10(gain)

proc attenuationToGain(a: float): float {.inline.} =
    if a <= -96.0: return 0
    result = a / 20
    result = pow(10, result)

proc `gain=`*(s: Sound, v: float) =
    if not s.isNil and not s.player.isNil:
        let a = gainToAttenuation(v)
        let pl = s.player
        {.emit: """
        SLVolumeItf volume;
        int res = (*`pl`)->GetInterface(`pl`, SL_IID_VOLUME, &volume);
        if (res == SL_RESULT_SUCCESS) {
            (*volume)->SetVolumeLevel(volume, `a` * 100.0);
        }
        """.}

proc gain*(s: Sound): float =
    if not s.player.isNil:
        let pl = s.player
        var mb : int16
        {.emit: """
        SLVolumeItf volume;
        int res = (*`pl`)->GetInterface(`pl`, SL_IID_VOLUME, &volume);
        if (res == SL_RESULT_SUCCESS) {
            (*volume)->GetVolumeLevel(volume, &`mb`);
        }
        """.}
        result = attenuationToGain(mb.float / 100)

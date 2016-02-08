import jnim

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
    SLObjectItf {.importc, header: "<SLES/OpenSLES.h>", incompleteStruct.} = object
    SLEngineItf {.importc, header: "<SLES/OpenSLES.h>", incompleteStruct.} = object

type Sound* = ref object
    player: SLObjectItf

var engineInited = false

var gAssetManager : AssetManagerPtr = nil
var gEngine : SLEngineItf # = nil
var gOutputMix : SLObjectItf

proc initSoundEngineWithActivity*(a: jobject) =
    var am = Activity(a).getApplication().getAssets()
    let env = jnim.currentEnv
    {.emit: """
    `gAssetManager` = AAssetManager_fromJava(`env`, `am`);
    """.}

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

proc newSoundWithFile*(path: string): Sound =
    initEngine()
    result.new()
    var pl : SLObjectItf

    let rd = loadResourceDescriptor(path)

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
    const SLInterfaceID pIDs[2] = {SL_IID_PLAY, SL_IID_SEEK};
    const SLboolean pIDsRequired[2] = {SL_BOOLEAN_TRUE, SL_BOOLEAN_TRUE};
    SLresult res = (*`gEngine`)->CreateAudioPlayer(`gEngine`, &`pl`, &audioSrc, &audioSnk, 2, pIDs, pIDsRequired);
    res = (*`pl`)->Realize(`pl`, SL_BOOLEAN_FALSE);
    """.}
    result.player = pl

proc setLooping*(s: Sound, flag: bool) =
    let pl = s.player
    {.emit: """
    SLPlayItf player;
    SLresult res = (*`pl`)->GetInterface(`pl`, SL_IID_PLAY, &player);
    if (res == SL_RESULT_SUCCESS) {
        SLmillisecond duration;
        res = player->GetDuration(player, &duration);
        if (res == SL_RESULT_SUCCESS) {
            SLSeekItf seek;
            res = (*`pl`)->GetInterface(`pl`, SL_IID_SEEK, &seek);
            if (res == SL_RESULT_SUCCESS) {
                (*seek)->SetLoop(seek, `flag`, 0, duration);
            }
        }
    }
    """.}

proc play*(s: Sound) =
    let pl = s.player
    {.emit: """
    SLPlayItf player;
    int res = (*`pl`)->GetInterface(`pl`, SL_IID_PLAY, &player);
    SLSeekItf seek;
    res = (*`pl`)->GetInterface(`pl`, SL_IID_SEEK, &seek);
    (*seek)->SetLoop(seek, SL_BOOLEAN_FALSE, 0, SL_TIME_UNKNOWN);
    (*player)->SetPlayState(player, SL_PLAYSTATE_PLAYING);
    """.}

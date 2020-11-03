# Reference: https://www.khronos.org/registry/OpenSL-ES/api/1.0.1/OpenSLES.h
# https://www.khronos.org/registry/OpenSL-ES/specs/OpenSL_ES_Specification_1.1.pdf

type
  SLboolean* {.size: sizeof(uint32).} = enum
    SL_FALSE
    SL_TRUE

  SLmillibel* = int16
  SLpermille* = int16
  SLmillisecond* = uint32

  SLObjectCallback* = proc(caller: SLObjectItf, pContext: pointer, event: uint32, res: SLresult, param: uint32, pInterface: pointer) {.cdecl.}

  SLInterfaceID* = distinct pointer
  SLObjectItf* = ptr ptr object
    Realize*: proc(self: SLObjectItf, async: SLboolean): SLresult {.cdecl.}
    Resume*: proc(self: SLObjectItf, async: SLboolean): SLresult {.cdecl.}

    GetState*: proc(self: SLObjectItf, pState: var uint32): SLresult {.cdecl.}
    GetInterface*: proc(self: SLObjectItf, iid: SLInterfaceID, pInterface: ptr pointer): SLresult {.cdecl.}

    RegisterCallback*: proc(self: SLObjectItf, callback: SLObjectCallback, pContext: pointer): SLresult {.cdecl.}
    AbortAsyncOperation*: proc(self: SLObjectItf) {.cdecl.}

    Destroy*: proc(self: SLObjectItf) {.cdecl.}
    SetPriority*: proc(self: SLObjectItf, priority: int32, preemptable: SLBoolean): SLresult {.cdecl.}
    GetPriority*: proc(self: SLObjectItf, priority: var int32, preemptable: var SLBoolean): SLresult {.cdecl.}
    SetLossOfControlInterfaces*: proc(self: SLObjectItf, numInterfaces: int16, pInterfaceIDs: ptr SLInterfaceID, enabled: SLboolean): SLresult {.cdecl.}

  SLDataSource* = object
    locator*: pointer
    format*: pointer

  SLDataSink* = object
    locator*: pointer
    format*: pointer

  SLEngineItf* = ptr ptr object
    CreateLEDDevice*: proc(self: SLEngineItf, pDevice: var SLObjectItf,
                deviceID: uint32, numInterfaces: uint32,
                pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateVibraDevice*: proc(self: SLEngineItf, pDevice: var SLObjectItf,
                deviceID: uint32, numInterfaces: uint32,
                pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateAudioPlayer*: proc(self: SLEngineItf, pPlayer: var SLObjectItf,
                pAudioSrc: ptr SLDataSource, pAudioSnk: ptr SLDataSink,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateAudioRecorder*: proc(self: SLEngineItf, pRecorder: var SLObjectItf,
                pAudioSrc: ptr SLDataSource, pAudioSnk: ptr SLDataSink,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateMidiPlayer*: proc(self: SLEngineItf, pPlayer: var SLObjectItf,
                pMIDISrc, pBankSrc: ptr SLDataSource,
                pAudioOutput, pVibra, pLEDArray: ptr SLDataSink,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateListener*: proc(self: SLEngineItf, pListener: var SLObjectItf,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    Create3DGroup*: proc(self: SLEngineItf, pGroup: var SLObjectItf,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateOutputMix*: proc(self: SLEngineItf, pMix: var SLObjectItf,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateMetadataExtractor*: proc(self: SLEngineItf, pMetadataExtractor: var SLObjectItf,
                pDataSource: ptr SLDataSource,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    CreateExtensionObject*: proc(self: SLEngineItf, pObject: var SLObjectItf,
                pParameters: pointer, objectID: uint32,
                numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID,
                pInterfaceRequired: ptr SLboolean): SLresult {.cdecl.}

    QueryNumSupportedInterfaces*: proc(self: SLEngineItf, objectID: uint32,
                pNumSupportedInterfaces: var uint32): SLresult {.cdecl.}

    QuerySupportedInterfaces*: proc(self: SLEngineItf, objectID, index: uint32,
                pInterfaceId: var SLInterfaceID): SLresult {.cdecl.}

    QueryNumSupportedExtensions*: proc(self: SLEngineItf,
                pNumExtensions: var uint32): SLresult {.cdecl.}

    QuerySupportedExtension*: proc(self: SLEngineItf, index: uint32,
                pExtensionName: ptr char,
                pNameLength: ptr int16): SLresult {.cdecl.}

    IsExtensionSupported*: proc(self: SLEngineItf, pExtensionName: cstring,
                pSupported: var SLboolean): SLresult {.cdecl.}

  SLVolumeItf* = ptr ptr object
    SetVolumeLevel*: proc(self: SLVolumeItf, level: SLmillibel): SLresult {.cdecl.}
    GetVolumeLevel*: proc(self: SLVolumeItf, level: var SLmillibel): SLresult {.cdecl.}
    GetMaxVolumeLevel*: proc(self: SLVolumeItf, maxLevel: var SLmillibel): SLresult {.cdecl.}
    SetMute*: proc(self: SLVolumeItf, mute: SLboolean): SLresult {.cdecl.}
    GetMute*: proc(self: SLVolumeItf, mute: var SLboolean): SLresult {.cdecl.}

    EnableStereoPosition*: proc(self: SLVolumeItf, enable: SLboolean): SLresult {.cdecl.}
    IsEnabledStereoPosition*: proc(self: SLVolumeItf, enable: var SLboolean): SLresult {.cdecl.}

    SetStereoPosition*: proc(self: SLVolumeItf, stereoPosition: SLpermille): SLresult {.cdecl.}
    GetStereoPosition*: proc(self: SLVolumeItf, stereoPosition: var SLpermille): SLresult {.cdecl.}

  SLSeekMode* {.size: sizeof(uint32).} = enum
    SL_SEEKMODE_FAST = 0x00000001
    SL_SEEKMODE_ACCURATE = 0x00000002

  SLSeekItf* = ptr ptr object
    SetPosition*: proc(self: SLSeekItf, pos: SLmillisecond, seekMode: SLSeekMode): SLresult {.cdecl.}
    SetLoop*: proc(self: SLSeekItf, loopEnable: SLboolean, startPos, endPos: SLmillisecond): SLresult {.cdecl.}
    GetLoop*: proc(self: SLSeekItf, loopEnable: var SLboolean, startPos, endPos: var SLmillisecond): SLresult {.cdecl.}

  SLPlayState* {.size: sizeof(uint32).} = enum
    SL_PLAYSTATE_STOPPED = 0x00000001
    SL_PLAYSTATE_PAUSED = 0x00000002
    SL_PLAYSTATE_PLAYING = 0x00000003

  SLPlayCallback* = proc(caller: SLPlayItf, context: pointer, event: uint32) {.cdecl.}

  SLPlayItf* = ptr ptr object
    SetPlayState*: proc(self: SLPlayItf, state: SLPlayState): SLresult {.cdecl.}
    GetPlayState*: proc(self: SLPlayItf, state: var SLPlayState): SLresult {.cdecl.}
    GetDuration*: proc(self: SLPlayItf, msec: var SLmillisecond): SLresult {.cdecl.}
    GetPosition*: proc(self: SLPlayItf, msec: var SLmillisecond): SLresult {.cdecl.}

    RegisterCallback*: proc(self: SLPlayItf, callback: SLPlayCallback, context: pointer): SLresult {.cdecl.}
    SetCallbackEventsMask*: proc(self: SLPlayItf, eventFlags: uint32): SLresult {.cdecl.}
    GetCallbackEventsMask*: proc(self: SLPlayItf, eventFlags: var uint32): SLresult {.cdecl.}

    SetMarkerPosition*: proc(self: SLPlayItf, mSec: SLmillisecond): SLresult {.cdecl.}
    ClearMarkerPosition*: proc(self: SLPlayItf): SLresult {.cdecl.}
    GetMarkerPosition*: proc(self: SLPlayItf, mSec: var SLmillisecond): SLresult {.cdecl.}

    SetPositionUpdatePeriod*: proc(self: SLPlayItf, mSec: SLmillisecond): SLresult {.cdecl.}
    GetPositionUpdatePeriod*: proc(self: SLPlayItf, mSec: var SLmillisecond): SLresult {.cdecl.}

  SLEngineOption* = object
    feature*: uint32
    data*: uint32

  SLresult* {.size: sizeof(uint32).} = enum
    SL_RESULT_SUCCESS        = 0x00000000
    SL_RESULT_PRECONDITIONS_VIOLATED = 0x00000001
    SL_RESULT_PARAMETER_INVALID    = 0x00000002
    SL_RESULT_MEMORY_FAILURE     = 0x00000003
    SL_RESULT_RESOURCE_ERROR     = 0x00000004
    SL_RESULT_RESOURCE_LOST      = 0x00000005
    SL_RESULT_IO_ERROR         = 0x00000006
    SL_RESULT_BUFFER_INSUFFICIENT  = 0x00000007
    SL_RESULT_CONTENT_CORRUPTED    = 0x00000008
    SL_RESULT_CONTENT_UNSUPPORTED  = 0x00000009
    SL_RESULT_CONTENT_NOT_FOUND    = 0x0000000A
    SL_RESULT_PERMISSION_DENIED    = 0x0000000B
    SL_RESULT_FEATURE_UNSUPPORTED  = 0x0000000C
    SL_RESULT_INTERNAL_ERROR     = 0x0000000D
    SL_RESULT_UNKNOWN_ERROR      = 0x0000000E
    SL_RESULT_OPERATION_ABORTED    = 0x0000000F
    SL_RESULT_CONTROL_LOST       = 0x00000010

  SLDataLocatorType* = distinct uint32

  # URI-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_URI
  SLDataLocator_URI* = object
    locatorType*: SLDataLocatorType
    URI*: cstring

  # Address-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_ADDRESS
  SLDataLocator_Address* = object
    locatorType*: SLDataLocatorType
    address*: pointer
    length*: uint32

  SLIODeviceType* = distinct uint32

  # IODevice-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_IODEVICE
  SLDataLocator_IODevice* = object
    locatorType*: SLDataLocatorType
    deviceType*: SLIODeviceType
    deviceID*: uint32
    device*: SLObjectItf


  # OutputMix-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_OUTPUTMIX
  SLDataLocator_OutputMix* = object
    locatorType*: SLDataLocatorType
    outputMix*: SLObjectItf

  # BufferQueue-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_BUFFERQUEUE
  SLDataLocator_BufferQueue* = object
    locatorType*: SLDataLocatorType
    numBuffers*: uint32

  # MidiBufferQueue-based data locator definition where locatorType must be SL_DATALOCATOR_TYPE_MIDIBUFFERQUEUE
  SLDataLocator_MIDIBufferQueue* = object
    locatorType*: SLDataLocatorType
    tpqn*: uint32
    numBuffers*: uint32


  SLDataLocator_AndroidFD* = object # OpenSLES_Android.h
    locatorType*: SLDataLocatorType
    fd*: int32
    offset*: int64
    length*: int64

  SLDataFormatType* = distinct uint32
  SLContainerType* = distinct uint32

  SLDataFormat_MIME* = object
    formatType*: SLDataFormatType
    mimeType*: cstring
    containerType*: SLContainerType

var
  SL_IID_ENGINE* {.importc.}: SLInterfaceID
  SL_IID_SEEK* {.importc.}: SLInterfaceID
  SL_IID_VOLUME* {.importc.}: SLInterfaceID
  SL_IID_PLAY* {.importc.}: SLInterfaceID

const
  SL_TIME_UNKNOWN* = SLmillisecond(0xFFFFFFFF'u32)

  SL_DATALOCATOR_TYPE_URI* = SLDataLocatorType(0x00000001'u32)
  SL_DATALOCATOR_TYPE_ADDRESS* = SLDataLocatorType(0x00000002'u32)
  SL_DATALOCATOR_TYPE_IODEVICE* = SLDataLocatorType(0x00000003'u32)
  SL_DATALOCATOR_TYPE_OUTPUTMIX* = SLDataLocatorType(0x00000004'u32)
  SL_DATALOCATOR_TYPE_RESERVED5* = SLDataLocatorType(0x00000005'u32)
  SL_DATALOCATOR_TYPE_BUFFERQUEUE* = SLDataLocatorType(0x00000006'u32)
  SL_DATALOCATOR_TYPE_MIDIBUFFERQUEUE* = SLDataLocatorType(0x00000007'u32)
  SL_DATALOCATOR_TYPE_RESERVED8* = SLDataLocatorType(0x00000008'u32)

  SL_DATALOCATOR_TYPE_ANDROIDFD* = SLDataLocatorType(0x800007BC'u32) # OpenSLES_Android.h

  SL_DATAFORMAT_TYPE_MIME* = SLDataFormatType(0x00000001'u32)
  SL_DATAFORMAT_PCM* = SLDataFormatType(0x00000002'u32)
  SL_DATAFORMAT_RESERVED3* = SLDataFormatType(0x00000003'u32)

  # Container type
  SL_CONTAINERTYPE_UNSPECIFIED* = SLContainerType(0x00000001'u32)
  SL_CONTAINERTYPE_RAW* = SLContainerType(0x00000002'u32)
  SL_CONTAINERTYPE_ASF* = SLContainerType(0x00000003'u32)
  SL_CONTAINERTYPE_AVI* = SLContainerType(0x00000004'u32)
  SL_CONTAINERTYPE_BMP* = SLContainerType(0x00000005'u32)
  SL_CONTAINERTYPE_JPG* = SLContainerType(0x00000006'u32)
  SL_CONTAINERTYPE_JPG2000* = SLContainerType(0x00000007'u32)
  SL_CONTAINERTYPE_M4A* = SLContainerType(0x00000008'u32)
  SL_CONTAINERTYPE_MP3* = SLContainerType(0x00000009'u32)
  SL_CONTAINERTYPE_MP4* = SLContainerType(0x0000000A'u32)
  SL_CONTAINERTYPE_MPEG_ES* = SLContainerType(0x0000000B'u32)
  SL_CONTAINERTYPE_MPEG_PS* = SLContainerType(0x0000000C'u32)
  SL_CONTAINERTYPE_MPEG_TS* = SLContainerType(0x0000000D'u32)
  SL_CONTAINERTYPE_QT* = SLContainerType(0x0000000E'u32)
  SL_CONTAINERTYPE_WAV* = SLContainerType(0x0000000F'u32)
  SL_CONTAINERTYPE_XMF_0* = SLContainerType(0x00000010'u32)
  SL_CONTAINERTYPE_XMF_1* = SLContainerType(0x00000011'u32)
  SL_CONTAINERTYPE_XMF_2* = SLContainerType(0x00000012'u32)
  SL_CONTAINERTYPE_XMF_3* = SLContainerType(0x00000013'u32)
  SL_CONTAINERTYPE_XMF_GENERIC* = SLContainerType(0x00000014'u32)
  SL_CONTAINERTYPE_AMR* = SLContainerType(0x00000015'u32)
  SL_CONTAINERTYPE_AAC* = SLContainerType(0x00000016'u32)
  SL_CONTAINERTYPE_3GPP* = SLContainerType(0x00000017'u32)
  SL_CONTAINERTYPE_3GA* = SLContainerType(0x00000018'u32)
  SL_CONTAINERTYPE_RM* = SLContainerType(0x00000019'u32)
  SL_CONTAINERTYPE_DMF* = SLContainerType(0x0000001A'u32)
  SL_CONTAINERTYPE_SMF* = SLContainerType(0x0000001B'u32)
  SL_CONTAINERTYPE_MOBILE_DLS* = SLContainerType(0x0000001C'u32)
  SL_CONTAINERTYPE_OGG* = SLContainerType(0x0000001D'u32)

  # IODevice-types
  SL_IODEVICE_AUDIOINPUT* = SLIODeviceType(0x00000001'u32)
  SL_IODEVICE_LEDARRAY* = SLIODeviceType(0x00000002'u32)
  SL_IODEVICE_VIBRA* = SLIODeviceType(0x00000003'u32)
  SL_IODEVICE_RESERVED4* = SLIODeviceType(0x00000004'u32)
  SL_IODEVICE_RESERVED5* = SLIODeviceType(0x00000005'u32)

proc slCreateEngineImpl(pEngine: var SLObjectItf,
  numOptions: uint32, pEngineOptions: ptr SLEngineOption,
  numInterfaces: uint32, pInterfaceIds: ptr SLInterfaceID, pInterfaceRequired: ptr SLBoolean): SLresult {.importc: "slCreateEngine".}

template numInterfaces: uint32 =
  assert(interfaces.len == interfaceRequired.len)
  uint32(interfaces.len)

template pInterfaces: ptr SLInterfaceID =
  if interfaces.len == 0: nil else: unsafeAddr interfaces[0]

template pInterfaceRequired: ptr SLboolean =
  if interfaceRequired.len == 0: nil else: unsafeAddr interfaceRequired[0]

{.push inline, stackTrace: off.}

proc slCreateEngine*(pEngine: var SLObjectItf, options: openarray[SLEngineOption], interfaces: openarray[SLInterfaceID], interfaceRequired: openarray[SLBoolean]): SLresult =
  let pOptions = if options.len == 0: nil else: unsafeAddr options[0]
  slCreateEngineImpl(pEngine, uint32(options.len), pOptions, numInterfaces, pInterfaces, pInterfaceRequired)

# SLObjectItf wrappers
proc realize*(self: SLObjectItf, async: bool = false): SLresult = self.Realize(self, SLboolean(async))
proc resume*(self: SLObjectItf, async: bool = false): SLresult = self.Resume(self, SLboolean(async))
proc getState*(self: SLObjectItf, pState: var uint32): SLresult = self.GetState(self, pState)
proc getInterface*(self: SLObjectItf, iid: SLInterfaceID, pInterface: ptr pointer): SLresult = self.GetInterface(self, iid, pInterface)
proc registerCallback*(self: SLObjectItf, callback: SLObjectCallback, pContext: pointer): SLresult = self.RegisterCallback(self, callback, pContext)
proc abortAsyncOperation*(self: SLObjectItf) = self.AbortAsyncOperation(self)
proc destroy*(self: SLObjectItf) = self.Destroy(self)
proc setPriority*(self: SLObjectItf, priority: int32, preemptable: bool): SLresult = self.SetPriority(self, priority, SLboolean(preemptable))
proc getPriority*(self: SLObjectItf, priority: var int32, preemptable: var bool): SLresult =
  var res: SLboolean
  result = self.GetPriority(self, priority, res)
  preemptable = bool(res)
proc setLossOfControlInterfaces*(self: SLObjectItf, interfaces: openarray[SLInterfaceID], enabled: bool): SLresult =
  let pInterfaces = if interfaces.len == 0: nil else: unsafeAddr interfaces[0]
  self.SetLossOfControlInterfaces(self, interfaces.len.int16, pInterfaces, SLboolean(enabled))


proc getInterface*(obj: SLObjectItf, engine: var SLEngineItf): SLresult =
  obj.getInterface(SL_IID_ENGINE, cast[ptr pointer](addr engine))
proc getInterface*(obj: SLObjectItf, vol: var SLVolumeItf): SLresult =
  obj.getInterface(SL_IID_VOLUME, cast[ptr pointer](addr vol))
proc getInterface*(obj: SLObjectItf, seek: var SLSeekItf): SLresult =
  obj.getInterface(SL_IID_SEEK, cast[ptr pointer](addr seek))
proc getInterface*(obj: SLObjectItf, play: var SLPlayItf): SLresult =
  obj.getInterface(SL_IID_PLAY, cast[ptr pointer](addr play))

# SLEngineItf wrappers
proc createLEDDevice*(self: SLEngineItf, pDevice: var SLObjectItf,
                deviceID: uint32, interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateLEDDevice(self, pDevice, deviceID, numInterfaces, pInterfaces, pInterfaceRequired)

proc createVibraDevice*(self: SLEngineItf, pDevice: var SLObjectItf,
                deviceID: uint32, interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateVibraDevice(self, pDevice, deviceID, numInterfaces, pInterfaces, pInterfaceRequired)

proc createAudioPlayer*(self: SLEngineItf, pPlayer: var SLObjectItf,
                pAudioSrc: ptr SLDataSource, pAudioSnk: ptr SLDataSink,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateAudioPlayer(self, pPlayer, pAudioSrc, pAudioSnk, numInterfaces, pInterfaces, pInterfaceRequired)

proc createAudioRecorder*(self: SLEngineItf, pRecorder: var SLObjectItf,
                pAudioSrc: ptr SLDataSource, pAudioSnk: ptr SLDataSink,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateAudioRecorder(self, pRecorder, pAudioSrc, pAudioSnk, numInterfaces, pInterfaces, pInterfaceRequired)

proc createMidiPlayer*(self: SLEngineItf, pPlayer: var SLObjectItf,
                pMIDISrc, pBankSrc: ptr SLDataSource,
                pAudioOutput, pVibra, pLEDArray: ptr SLDataSink,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateMidiPlayer(self, pPlayer, pMIDISrc, pBankSrc, pAudioOutput, pVibra, pLEDArray, numInterfaces, pInterfaces, pInterfaceRequired)

proc createListener*(self: SLEngineItf, pListener: var SLObjectItf,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateListener(self, pListener, numInterfaces, pInterfaces, pInterfaceRequired)

proc create3DGroup*(self: SLEngineItf, pGroup: var SLObjectItf,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.Create3DGroup(self, pGroup, numInterfaces, pInterfaces, pInterfaceRequired)

proc createOutputMix*(self: SLEngineItf, pMix: var SLObjectItf,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateOutputMix(self, pMix, numInterfaces, pInterfaces, pInterfaceRequired)

proc createMetadataExtractor*(self: SLEngineItf, pMetadataExtractor: var SLObjectItf,
                pDataSource: ptr SLDataSource,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateMetadataExtractor(self, pMetadataExtractor, pDataSource, numInterfaces, pInterfaces, pInterfaceRequired)

proc createExtensionObject*(self: SLEngineItf, pObject: var SLObjectItf,
                pParameters: pointer, objectID: uint32,
                interfaces: openarray[SLInterfaceID],
                interfaceRequired: openarray[SLboolean]): SLresult =
  self.CreateExtensionObject(self, pObject, pParameters, objectID, numInterfaces, pInterfaces, pInterfaceRequired)

proc queryNumSupportedInterfaces*(self: SLEngineItf, objectID: uint32,
                pNumSupportedInterfaces: var uint32): SLresult =
  self.QueryNumSupportedInterfaces(self, objectID, pNumSupportedInterfaces)

proc querySupportedInterfaces*(self: SLEngineItf, objectID, index: uint32,
                pInterfaceId: var SLInterfaceID): SLresult =
  self.QuerySupportedInterfaces(self, objectID, index, pInterfaceId)

proc queryNumSupportedExtensions*(self: SLEngineItf, pNumExtensions: var uint32): SLresult =
  self.QueryNumSupportedExtensions(self, pNumExtensions)

proc querySupportedExtension*(self: SLEngineItf, index: uint32,
                pExtensionName: ptr char,
                pNameLength: ptr int16): SLresult =
  self.QuerySupportedExtension(self, index, pExtensionName, pNameLength)

proc isExtensionSupported*(self: SLEngineItf, pExtensionName: cstring,
                pSupported: var bool): SLresult =
  var res: SLboolean
  result = self.IsExtensionSupported(self, pExtensionName, res)
  pSupported = bool(res)

# SLVolumeItf wrappers
proc setVolumeLevel*(self: SLVolumeItf, level: SLmillibel): SLresult = self.SetVolumeLevel(self, level)
proc getVolumeLevel*(self: SLVolumeItf, level: var SLmillibel): SLresult = self.GetVolumeLevel(self, level)
proc getMaxVolumeLevel*(self: SLVolumeItf, maxLevel: var SLmillibel): SLresult = self.GetMaxVolumeLevel(self, maxLevel)
proc setMute*(self: SLVolumeItf, mute: bool): SLresult = self.SetMute(self, SLboolean(mute))
proc getMute*(self: SLVolumeItf, mute: var bool): SLresult =
  var res: SLboolean
  result = self.GetMute(self, res)
  mute = bool(res)
proc enableStereoPosition*(self: SLVolumeItf, enable: bool): SLresult = self.EnableStereoPosition(self, SLboolean(enable))
proc isEnabledStereoPosition*(self: SLVolumeItf, enable: var bool): SLresult =
  var res: SLboolean
  result = self.IsEnabledStereoPosition(self, res)
  enable = bool(res)
proc setStereoPosition*(self: SLVolumeItf, stereoPosition: SLpermille): SLresult = self.SetStereoPosition(self, stereoPosition)
proc getStereoPosition*(self: SLVolumeItf, stereoPosition: var SLpermille): SLresult = self.GetStereoPosition(self, stereoPosition)

# SLSeekItf wrappers
proc setPosition*(self: SLSeekItf, pos: SLmillisecond, seekMode: SLSeekMode): SLresult = self.SetPosition(self, pos, seekMode)
proc setLoop*(self: SLSeekItf, loopEnable: bool, startPos, endPos: SLmillisecond): SLresult = self.SetLoop(self, SLboolean(loopEnable), startPos, endPos)
proc getLoop*(self: SLSeekItf, loopEnable: var bool, startPos, endPos: var SLmillisecond): SLresult =
  var enable: SLboolean
  result = self.GetLoop(self, enable, startPos, endPos)
  loopEnable = bool(enable)

# SLPlayItf wrappers
proc setPlayState*(self: SLPlayItf, state: SLPlayState): SLresult = self.SetPlayState(self, state)
proc getPlayState*(self: SLPlayItf, state: var SLPlayState): SLresult = self.GetPlayState(self, state)
proc getDuration*(self: SLPlayItf, msec: var SLmillisecond): SLresult = self.GetDuration(self, msec)
proc getPosition*(self: SLPlayItf, msec: var SLmillisecond): SLresult = self.GetPosition(self, msec)
proc registerCallback*(self: SLPlayItf, callback: SLPlayCallback, context: pointer): SLresult = self.RegisterCallback(self, callback, context)
proc setCallbackEventsMask*(self: SLPlayItf, eventFlags: uint32): SLresult = self.SetCallbackEventsMask(self, eventFlags)
proc getCallbackEventsMask*(self: SLPlayItf, eventFlags: var uint32): SLresult = self.GetCallbackEventsMask(self, eventFlags)
proc setMarkerPosition*(self: SLPlayItf, mSec: SLmillisecond): SLresult = self.SetMarkerPosition(self, mSec)
proc clearMarkerPosition*(self: SLPlayItf): SLresult = self.ClearMarkerPosition(self)
proc getMarkerPosition*(self: SLPlayItf, mSec: var SLmillisecond): SLresult = self.GetMarkerPosition(self, mSec)
proc setPositionUpdatePeriod*(self: SLPlayItf, mSec: SLmillisecond): SLresult = self.SetPositionUpdatePeriod(self, mSec)
proc getPositionUpdatePeriod*(self: SLPlayItf, mSec: var SLmillisecond): SLresult = self.GetPositionUpdatePeriod(self, mSec)

{.pop.}

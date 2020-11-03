import winlean


type
  IXAudio2* = ptr ptr object
    QueryInterface*: pointer
    AddRef*: pointer
    Release*: pointer
    GetDeviceCount*: pointer
    GetDeviceDetails*: pointer
  # STDMETHOD(QueryInterface) (THIS_ REFIID riid, __deref_out void** ppvInterface) PURE;

  # // NAME: IXAudio2::AddRef
  # // DESCRIPTION: Adds a reference to the XAudio2 object.
  # //
  # STDMETHOD_(ULONG, AddRef) (THIS) PURE;

  # // NAME: IXAudio2::Release
  # // DESCRIPTION: Releases a reference to the XAudio2 object.
  # //
  # STDMETHOD_(ULONG, Release) (THIS) PURE;

  # // NAME: IXAudio2::GetDeviceCount
  # // DESCRIPTION: Returns the number of audio output devices available.
  # //
  # // ARGUMENTS:
  # //  pCount - Returns the device count.
  # //
  # STDMETHOD(GetDeviceCount) (THIS_ __out UINT32* pCount) PURE;

  # // NAME: IXAudio2::GetDeviceDetails
  # // DESCRIPTION: Returns information about the device with the given index.
  # //
  # // ARGUMENTS:
  # //  Index - Index of the device to be queried.
  # //  pDeviceDetails - Returns the device details.
  # //
  # STDMETHOD(GetDeviceDetails) (THIS_ UINT32 Index, __out XAUDIO2_DEVICE_DETAILS* pDeviceDetails) PURE;


    Initialize*: proc(self: IXAudio2, flags: uint32, processor: XAUDIO2_PROCESSOR): HRESULT {.stdcall.}
    RegisterForCallbacks*: pointer
    UnregisterForCallbacks*: pointer
    CreateSourceVoice*: proc(self: IXAudio2, ppSourceVoice: ptr IXAudio2SourceVoice, pSourceFormat: ptr WAVEFORMATEX, falgs: uint32, MaxFrequencyRatio: cfloat, pCallback: IXAudio2VoiceCallback, pSendList: pointer, pEffectChain: pointer): HRESULT {.stdcall.}
    CreateSubmixVoice*: pointer
    CreateMasteringVoice*: proc(self: IXAudio2, ppMasteringVoice: ptr IXAudio2MasteringVoice, InputChannels, InputSampleRate, Flags, DeviceIndex: uint32, pEffectChain: pointer = nil): HRESULT {.stdcall.}
    StartEngine*: proc(self: IXAudio2): HRESULT {.stdcall.}

  # // NAME: IXAudio2::StopEngine
  # // DESCRIPTION: Stops and destroys the audio processing thread.
  # //
  # STDMETHOD_(void, StopEngine) (THIS) PURE;

  # // NAME: IXAudio2::CommitChanges
  # // DESCRIPTION: Atomically applies a set of operations previously tagged
  # //        with a given identifier.
  # //
  # // ARGUMENTS:
  # //  OperationSet - Identifier of the set of operations to be applied.
  # //
  # STDMETHOD(CommitChanges) (THIS_ UINT32 OperationSet) PURE;

  # // NAME: IXAudio2::GetPerformanceData
  # // DESCRIPTION: Returns current resource usage details: memory, CPU, etc.
  # //
  # // ARGUMENTS:
  # //  pPerfData - Returns the performance data structure.
  # //
  # STDMETHOD_(void, GetPerformanceData) (THIS_ __out XAUDIO2_PERFORMANCE_DATA* pPerfData) PURE;

  # // NAME: IXAudio2::SetDebugConfiguration
  # // DESCRIPTION: Configures XAudio2's debug output (in debug builds only).
  # //
  # // ARGUMENTS:
  # //  pDebugConfiguration - Structure describing the debug output behavior.
  # //  pReserved - Optional parameter; must be NULL.
  # //
  # STDMETHOD_(void, SetDebugConfiguration) (THIS_ __in_opt const XAUDIO2_DEBUG_CONFIGURATION* pDebugConfiguration,
  #                      __in_opt __reserved void* pReserved X2DEFAULT(NULL)) PURE;

  IXAudio2VoiceObj {.pure, inheritable.} = object
    GetVoiceDetails*: pointer
    SetOutputVoices*: pointer
    SetEffectChain*: pointer
    EnableEffect*: pointer
    DisableEffect*: pointer
    GetEffectState*: pointer
    SetEffectParameters*: pointer
    GetEffectParameters*: pointer
    SetFilterParameters*: pointer
    GetFilterParameters*: pointer
    SetOutputFilterParameters*: pointer
    GetOutputFilterParameters*: pointer
    SetVolume*: proc(self: IXAudio2SourceVoice, Volume: cfloat, OperationSet: uint32): HRESULT {.stdcall.}
    GetVolume*: pointer
    SetChannelVolumes*: pointer
    GetChannelVolumes*: pointer
    SetOutputMatrix*: pointer
    GetOutputMatrix*: pointer
    DestroyVoice*: proc(self: IXAudio2SourceVoice): HRESULT {.stdcall.}

  IXAudio2Voice* = ptr ptr IXAudio2VoiceObj

  IXAudio2MasteringVoice* = ptr ptr object of IXAudio2Voice

  IXAudio2SourceVoice* = ptr ptr object of IXAudio2Voice
    Start*: proc(self: IXAudio2SourceVoice, Flags: uint32, OperationSet: uint32): HRESULT {.stdcall.}
    Stop*: proc(self: IXAudio2SourceVoice, Flags: uint32, OperationSet: uint32): HRESULT {.stdcall.}
    SubmitSourceBuffer*: proc(self: IXAudio2SourceVoice, buf: ptr XAUDIO2_BUFFER, pBufferWMA: pointer = nil): HRESULT {.stdcall.}
    FlushSourceBuffers*: pointer
    Discontinuity*: pointer
    ExitLoop*: pointer
    GetState*: proc(self: IXAudio2SourceVoice, pVoiceState: var XAUDIO2_VOICE_STATE, Flags: uint32): HRESULT {.stdcall.}
    SetFrequencyRatio*: pointer
    GetFrequencyRatio*: pointer
    SetSourceSampleRate*: pointer


  WAVEFORMATEX* = object
    wFormatTag*: WORD
    nChannels*: WORD
    nSamplesPerSec*: DWORD
    nAvgBytesPerSec*: DWORD
    nBlockAlign*: WORD
    wBitsPerSample*: WORD
    cbSize*: WORD

  XAUDIO2_BUFFER* = object
    Flags*: uint32
    AudioBytes*: uint32
    pAudioData*: pointer
    PlayBegin*: uint32
    PlayLength*: uint32
    LoopBegin*: uint32
    LoopLength*: uint32
    LoopCount*: uint32
    pContext*: pointer

  XAUDIO2_VOICE_STATE* = object
    pCurrentBufferContext*: pointer
    BuffersQueued*: uint32
    SamplesPlayed*: uint64

  IXAudio2VoiceCallback = ptr ptr object

  WORD* = int16
  XAUDIO2_PROCESSOR = uint32
  HRESULT* = int32

const
  XAUDIO2_VOICE_NOSAMPLESPLAYED* = 0x0100
  XAUDIO2_LOOP_INFINITE* = 255

var CLSID_XAudio2*: GUID = GUID(D1: 0x5a508685, D2: 0xa254'i16, D3: 0x4fba, D4: [
  0x9b'i8, 0x82'i8, 0x9a'i8, 0x24'i8, 0xb0'i8, 0x03'i8, 0x06'i8, 0xaf'i8])

var IID_XAudio2*: GUID = GUID(D1: 0x8bcf1f58'i32, D2: 0x9fe7'i16, D3: 0x4583, D4: [
  0x8a'i8, 0xc6'i8, 0xe2'i8, 0xad'i8, 0xc4'i8, 0x65'i8, 0xc8'i8, 0xbb'i8])



proc CoInitialize*(P1: pointer): HRESULT {.stdcall, dynlib: "ole32", importc.}
proc CoCreateInstance*(P1: ptr GUID, P2: pointer, P3: int32, P4: ptr GUID, P5: pointer): HRESULT {.stdcall, dynlib: "ole32", importc.}

var contextCreated = false
var ixaudio2*: IXAudio2

proc createContext*() =
  if contextCreated: return
  contextCreated = true

  when defined(xbox):
    discard
  else:
    proc XAudio2Create(pXAudio: var IXAudio2, flags: uint32, processor: XAUDIO2_PROCESSOR = 0xffffffff'u32): HRESULT =
      discard CoInitialize(nil)

      result = CoCreateInstance(addr CLSID_XAudio2,
                    nil, 1, addr IID_XAudio2, addr pXAudio);
      if result >= 0:
        echo "initialize: ", pXAudio.Initialize(pXAudio, flags, processor)
    # if (SUCCEEDED(hr))
    # {
    #   hr = pXAudio2->lpVtbl->Initialize(pXAudio2, Flags, XAudio2Processor);

    #   if (SUCCEEDED(hr))
    #   {
    #     *ppXAudio2 = pXAudio2;
    #   }
    #   else
    #   {
    #     pXAudio2->lpVtbl->Release(pXAudio2);
    #   }
    # }



  # var XAudio2Create: proc(pXAudio: ptr IXAudio2, flags: uint32, processor: XAUDIO2_PROCESSOR): HRESULT {.stdcall.}
  # XAudio2Create = cast[type(XAudio2Create)](xaudioLib.symAddr("XAudio2Create"))
  # if XAudio2Create.isNil:
  #   echo "Could not load"
  #   return

  discard XAudio2Create(ixaudio2, 0)

  var pMasterVoice: IXAudio2MasteringVoice
  echo "master: ", ixaudio2.CreateMasteringVoice(ixaudio2, addr pMasterVoice, 0, 0, 0, 0)

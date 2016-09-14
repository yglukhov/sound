import async_http_request

import jsbind

type
    AudioContext = ref object of JSObj
    AudioNode = ref object of JSObj
    GainNode = ref object of AudioNode
    AudioBufferSourceNode = ref object of AudioNode
    AudioBuffer = ref object of JSObj
    ArrayBuffer* = ref object of JSObj
    AudioParam = ref object of JSObj

proc newAudioContext(): AudioContext {.jsimportgWithName: "function(){AudioContext = (window.AudioContext || window.webkitAudioContext || null); return (AudioContext)?(new AudioContext):null;}".}

proc createGain(a: AudioContext): GainNode {.jsimport.}
proc createBufferSource(a: AudioContext): AudioBufferSourceNode {.jsimport.}
proc decodeAudioData(a: AudioContext, ab: JSObj, handler: proc(b: AudioBuffer), onErr: proc(b: JSObj)) {.jsimport.}

proc connect(n1, n2: AudioNode) {.jsimport.}

proc destination(a: AudioContext): AudioNode {.jsimportProp.}

proc buffer(n: AudioBufferSourceNode): AudioBuffer {.jsimportProp.}
proc loop(n: AudioBufferSourceNode): bool {.jsimportProp.}
proc `buffer=`(n: AudioBufferSourceNode, b: AudioBuffer) {.jsimportProp.}
proc `loop=`(n: AudioBufferSourceNode, b: bool) {.jsimportProp.}
proc `onended=`*(n: AudioBufferSourceNode, p: proc()) {.jsimportProp.}

proc duration(b: AudioBuffer): cfloat {.jsimportProp.}

proc start(s: AudioBufferSourceNode) {.jsimport.}
proc stop(s: AudioBufferSourceNode) {.jsimport.}

proc gain(g: GainNode): AudioParam {.jsimportProp.}
proc value(g: AudioParam): cfloat {.jsimportProp.}
proc `value=`(g: AudioParam, v: cfloat) {.jsimportProp.}

type Sound* = ref object
    source*: AudioBufferSourceNode
    gain: GainNode
    freshSource: bool

var context: AudioContext
var mainVolume: GainNode

proc createContext() =
    context = newAudioContext()

    # Create a AudioGainNode to control the main volume.
    mainVolume = context.createGain()
    # Connect the main volume node to the context destination.
    mainVolume.connect(context.destination)

template createContextIfNeeded() =
    if context.isNil:
        createContext()

proc initWithArrayBuffer(s: Sound, ab: ArrayBuffer, handler: proc() = nil) =
    createContextIfNeeded()
    s.freshSource = true
    s.source = context.createBufferSource()
    s.gain = context.createGain()
    s.source.connect(s.gain)
    s.gain.connect(mainVolume)

    var onSuccess : proc(b: AudioBuffer)
    var onError : proc(e: JSObj)

    onSuccess = proc(b: AudioBuffer) =
        handleJSExceptions:
            jsUnref(onSuccess)
            jsUnref(onError)
            s.source.buffer = b
            if not handler.isNil: handler()

    onError = proc(e: JSObj) =
        handleJSExceptions:
            jsUnref(onSuccess)
            jsUnref(onError)
            echo "Error decoding audio data"
            if not handler.isNil: handler()

    jsRef(onSuccess)
    jsRef(onError)

    context.decodeAudioData(ab, onSuccess, onError)

proc newSoundWithArrayBuffer*(ab: ArrayBuffer): Sound =
    result.new()
    result.initWithArrayBuffer(ab)

proc newSoundWithArrayBufferAsync*(ab: ArrayBuffer, handler: proc(s: Sound)) =
    let s = Sound.new()
    s.initWithArrayBuffer(ab, proc() =
        handler(s))

proc newSoundWithURL*(url: string): Sound =
    result.new()
    let req = newXMLHTTPRequest()
    req.open("GET", url)
    req.responseType = "arraybuffer"

    let snd = result
    var reqListener : proc()
    reqListener = proc() =
        handleJSExceptions:
            jsUnref(reqListener)
            snd.initWithArrayBuffer(cast[ArrayBuffer](req.response))
    jsRef(reqListener)

    req.addEventListener("load", reqListener)
    req.send()

proc setLooping*(s: Sound, flag: bool) =
    s.source.loop = flag

proc recreateSource(s: Sound) =
    var source = s.source
    let newSource = context.createBufferSource()
    newSource.connect(s.gain)
    newSource.buffer = s.source.buffer
    newSource.loop = s.source.loop
    s.source = newSource
    s.freshSource = true

proc duration*(s: Sound): float = s.source.buffer.duration

proc play*(s: Sound) =
    if not s.freshSource:
        if not s.source.isNil: s.source.stop()
        s.recreateSource()
    s.source.start()
    s.freshSource = false

proc stop*(s: Sound) =
    if not s.freshSource:
        s.source.stop()
        s.recreateSource()

proc `gain=`*(s: Sound, v: float) = s.gain.gain.value = v
proc gain*(s: Sound): float = s.gain.gain.value

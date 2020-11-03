import async_http_request
import logging
import jsbind

type
  AudioContext = ref object of JSObj
  AudioNode = ref object of JSObj
  GainNode = ref object of AudioNode
  AudioBufferSourceNode = ref object of AudioNode
  AudioBuffer = ref object of JSObj
  ArrayBuffer* = ref object of JSObj
  AudioParam = ref object of JSObj

# Changed autoplay behavior according to https://developers.google.com/web/updates/2017/09/autoplay-policy-changes#webaudio
proc newAudioContext(): AudioContext {.jsimportgWithName: """
  function() {
    var AudioContext = (window.AudioContext || window.webkitAudioContext || null);
    if (AudioContext) {
      var context = new AudioContext();
      if (context.state == "suspended") {
        function onClick() {
          context.resume();
          document.body.removeEventListener("click", onClick, false);
        }
        function onLoad() {
          document.body.addEventListener("click", onClick, false);
        }
        if (document.body) {
          onLoad();
        } else {
          document.addEventListener("DOMContentLoaded", onLoad);
        }
      }
      return context;
    } else {
      return null;
    };
  }
""".}

proc createGain(a: AudioContext): GainNode {.jsimport.}
proc createBufferSource(a: AudioContext): AudioBufferSourceNode {.jsimport.}
proc decodeAudioData(a: AudioContext, ab: JSObj, handler: proc(b: AudioBuffer), onErr: proc(b: JSObj)) {.jsimport.}

proc connect(n1, n2: AudioNode) {.jsimport.}
proc disconnect(n1: AudioNode) {.jsimport.}

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
  when defined(emscripten):
    completionHandler: proc()

var context: AudioContext
var mainVolume: GainNode

proc createContext() =
  context = newAudioContext()
  if not context.isNil:
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
  if not context.isNil:
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
        s.source = nil
        error "Error decoding audio data"
        if not handler.isNil: handler()

    jsRef(onSuccess)
    jsRef(onError)

    context.decodeAudioData(ab, onSuccess, onError)

when defined(emscripten):
  import jsbind.emscripten
  import sets
  var activeCompletionHandlers = initSet[pointer]()

  proc nimSoundCompletionHandler(s: pointer) {.EMSCRIPTEN_KEEPALIVE.} =
    if s in activeCompletionHandlers:
      let snd = cast[Sound](s)
      snd.completionHandler()

  proc finalizeSound(s: Sound) =
    activeCompletionHandlers.excl(cast[pointer](s))

  template newSound(): Sound =
    var s: Sound
    s.new(finalizeSound)
    s
else:
  template newSound(): Sound =
    var s: Sound
    s.new()
    s

proc newSoundWithArrayBuffer*(ab: ArrayBuffer): Sound =
  result = newSound()
  result.initWithArrayBuffer(ab)

proc newSoundWithArrayBufferAsync*(ab: ArrayBuffer, handler: proc(s: Sound)) =
  let s = newSound()
  s.initWithArrayBuffer(ab) do():
    handler(s)

proc newSoundWithURL*(url: string): Sound =
  result = newSound()
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
  if not s.source.isNil:
    s.source.loop = flag

proc recreateSource(s: Sound) =
  var source = s.source
  let newSource = context.createBufferSource()
  newSource.connect(s.gain)
  newSource.buffer = s.source.buffer
  newSource.loop = s.source.loop
  s.source.disconnect()
  s.source = newSource
  s.freshSource = true

proc duration*(s: Sound): float =
  if not s.source.isNil:
    result = s.source.buffer.duration

proc play*(s: Sound) =
  if not s.source.isNil:
    if not s.freshSource:
      s.recreateSource()
    s.source.start()
    s.freshSource = false

proc stop*(s: Sound) =
  if not s.source.isNil and not s.freshSource:
    s.source.stop()
    s.recreateSource()

proc `gain=`*(s: Sound, v: float) =
  let g = s.gain
  if not g.isNil: g.gain.value = v

proc gain*(s: Sound): float =
  let g = s.gain
  if not g.isNil: result = g.gain.value

proc onComplete*(s: Sound, h: proc()) =
  ## This function is only availbale for js and emscripten for now. Sorry.
  if not s.source.isNil:
    when defined(js):
      s.source.onended = h
    else:
      s.completionHandler = h
      if h.isNil:
        discard EM_ASM_INT("""
        _nimem_o[$0].onended = null;
        """, s.source.p)
        activeCompletionHandlers.excl(cast[pointer](s))
      else:
        activeCompletionHandlers.incl(cast[pointer](s))
        discard EM_ASM_INT("""
        var src = _nimem_o[$1];
        src.onended = function() {
          _nimSoundCompletionHandler($0);
        }
        """, cast[pointer](s), s.source.p)

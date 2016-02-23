import async_http_request

type Sound* = ref object
    source: ref RootObj
    gain: ref RootObj
    freshSource: bool

var contextInited = false

proc createContext() =
    {.emit: """
    window.AudioContext = (
        window.AudioContext ||
        window.webkitAudioContext ||
        null
    );

    window.__nimsound_context = null;
    window.__nimsound_gain = null;

    if (AudioContext) {
        var ctx = new AudioContext();
        // Create a AudioGainNode to control the main volume.
        var mainVolume = ctx.createGain();
        // Connect the main volume node to the context destination.
        mainVolume.connect(ctx.destination);

        window.__nimsound_context = ctx;
        window.__nimsound_gain = mainVolume;
    }
    else {
        console.log("Audio is not supported in your browser");
    }
    """.}

template createContextIfNeeded() =
    if not contextInited:
        createContext()
        contextInited = true

proc initWithArrayBuffer(s: Sound, ab: ref RootObj, handler: proc() = nil) =
    createContextIfNeeded()

    var source : ref RootObj
    var gain : ref RootObj
    {.emit: """
    `source` = window.__nimsound_context.createBufferSource();
    `gain` = window.__nimsound_context.createGain();

    `source`.connect(`gain`);
    `gain`.connect(window.__nimsound_gain);

    window.__nimsound_context.decodeAudioData(`ab`, function(buffer) {
        `source`.buffer = buffer;
        if (`handler` != null) `handler`();
      },

      function(e) {
        if (`handler` != null) `handler`();
        console.log("Error with decoding audio data" + e.err);
        });
    """.}
    s.source = source
    s.gain = gain
    s.freshSource = true

proc newSoundWithArrayBuffer*(ab: ref RootObj): Sound =
    result.new()
    result.initWithArrayBuffer(ab)

proc newSoundWithArrayBufferAsync*(ab: ref RootObj, handler: proc(s: Sound)) =
    let s = Sound.new()
    s.initWithArrayBuffer(ab, proc() =
        handler(s))

proc newSoundWithURL*(url: string): Sound =
    result.new()
    let req = newXMLHTTPRequest()
    req.open("GET", url)
    req.responseType = "arraybuffer"

    let snd = result
    let reqListener = proc(ev: ref RootObj) =
        var data : ref RootObj
        {.emit: "`data` = `ev`.target.response;".}
        snd.initWithArrayBuffer(data)

    req.addEventListener("load", reqListener)
    req.send()

proc setLooping*(s: Sound, flag: bool) =
    let source {.hint[XDeclaredButNotUsed]: off.} = s.source
    {.emit: "`source`.loop = `flag`;".}

proc recreateSource(s: Sound) =
    var source {.hint[XDeclaredButNotUsed]: off.} = s.source
    let gain {.hint[XDeclaredButNotUsed]: off.} = s.gain

    {.emit: """
    var newSource = window.__nimsound_context.createBufferSource();
    newSource.connect(`gain`);
    newSource.buffer = `source`.buffer;
    newSource.loop = `source`.loop;
    `source` = newSource;
    """.}
    s.source = source
    s.freshSource = true

proc duration*(s: Sound): float =
    let source = s.source
    {.emit: "`result` = `source`.buffer.duration;".}

proc play*(s: Sound) =
    if not s.freshSource: s.recreateSource()
    let source {.hint[XDeclaredButNotUsed]: off.} = s.source
    {.emit: "`source`.start();".}
    s.freshSource = false

proc stop*(s: Sound) =
    if not s.freshSource:
        let source {.hint[XDeclaredButNotUsed]: off.} = s.source
        {.emit: "`source`.stop();".}
        s.recreateSource()

proc `gain=`*(s: Sound, v: float) =
    let g = s.gain
    {.emit: "`g`.gain.value = `v`;".}

proc gain*(s: Sound): float =
    let g = s.gain
    {.emit: "`result` = `g`.gain.value;".}

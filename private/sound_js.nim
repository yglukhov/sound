import async_http_request

type Sound* = ref object
    source: ref RootObj
    gain: ref RootObj

var contextInited = false

proc createContext() =
    {.emit: """
    window.AudioContext = (
        window.AudioContext ||
        window.webkitAudioContext ||
        null
    );

    window.__nimx_audio_context = null;
    window.__nimx_audio_gain = null;

    if (AudioContext) {
        var ctx = new AudioContext();
        // Create a AudioGainNode to control the main volume.
        var mainVolume = ctx.createGain();
        // Connect the main volume node to the context destination.
        mainVolume.connect(ctx.destination);

        window.__nimx_audio_context = ctx;
        window.__nimx_audio_gain = mainVolume;
    }
    else {
        console.log("Audio is not supported in your browser");
    }
    """.}

template createContextIfNeeded() =
    if not contextInited:
        createContext()
        contextInited = true

proc initWithArrayBuffer(s: Sound, ab: ref RootObj) =
    var source : ref RootObj
    var gain : ref RootObj
    {.emit: """
    `source` = window.__nimx_audio_context.createBufferSource();
    `gain` = window.__nimx_audio_context.createGain();

    `source`.connect(`gain`);
    `gain`.connect(window.__nimx_audio_gain);

    window.__nimx_audio_context.decodeAudioData(`ab`, function(buffer) {
        `source`.buffer = buffer;
      },

      function(e){"Error with decoding audio data" + e.err});
    """.}
    s.source = source
    s.gain = gain

proc newSoundWithArrayBuffer*(ab: ref RootObj): Sound =
    createContextIfNeeded()
    result.new()
    result.initWithArrayBuffer(ab)

proc newSoundWithURL*(url: string): Sound =
    createContextIfNeeded()
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

proc play*(s: Sound) =
    let source = s.source
    {.emit: "`source`.start(0);".}

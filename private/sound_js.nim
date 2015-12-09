
type Sound* = ref object
    source: ref RootObj
    gain: ref RootObj

var contextInited = false

proc createContext() =
    if contextInited: return
    contextInited = true
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

proc newSoundWithArrayBuffer*(ab: ref RootObj): Sound =
    createContext()
    result.new()
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
    result.source = source
    result.gain = gain

proc play*(s: Sound) =
    let source = s.source
    {.emit: "`source`.start(0);".}

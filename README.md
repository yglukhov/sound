# sound [![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

Cross-platform sound mixer library

The library is using different "backends" depending on target platform:
- **Linux**, **MacOS**, **iOS**: OpenAL. Supported formats: ogg+vorbis
- **Windows**: XAudio2. Supported formats: ogg+vorbis
- **Android**: SLES. Supported formats: ogg+vorbis
- **JavaScript**, **Asm.js**: WebAudio. Supported formats: mp3 (and ogg+vorbis on some browsers)

Usage:
```nim
import sound.sound

when defined(android):
    var activity: jobject # You should get the reference to activity from somewhere.
    activity = androidGetActivity() # E.g. If you're using sdl.
    initSoundEngineWithActivity(activity)

var snd: Sound
when defined(android):
    # Supported URL schemes: android_asset, file
    snd = newSoundWithURL("android_asset://testfile.ogg") # The path is relative to assets folder
elif defined(js):
    snd = newSoundWithURL("testfile.ogg") # The url may be relative or absolute. The sound is loaded asynchronously.
else:
    # Supported URL schemes: file.
    snd = newSoundWithURL("file://" & getAppDir() & "/testfile.ogg")

snd.play()
```

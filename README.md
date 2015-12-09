# sound
Cross-platform sound mixer library

The library is using different "backends" depending on target platform:
- OpenAL + ogg + vorbis - Windows, Linux, Mac, iOS
- SLES - Android
- AudioContext - Web

Usage:
```nim
when defined(android):
    var activity: jobject # You should get the reference to activity from somewhere.
    activity = androidGetActivity() # E.g. If you're using sdl.
    initSoundEngineWithActivity(activity)

var snd: Sound
when defined(android):
    snd = newSoundWithPath("testfile.ogg") # The path is relative to assets folder
elif defined(js):
    snd = newSoundWithURL("testfile.ogg") # The url may be relative or absolute. The sound is loaded asynchronously.
else:
    snd = newSoundWithPath("testfile.ogg") # The path is relative to current dir.

snd.play()
```

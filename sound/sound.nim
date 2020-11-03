
type
  SoundState* = enum
    # Intial state
    # play() -> playing
    # pause() -> paused (at the beginning)
    # stop() -> nop -> stopped
    stopped

    # Playing state. Will occasionally transition to complete if not looping
    # play() -> restart -> playing
    # pause() -> paused
    # stop() -> stopped
    playing

    # Paused. Can only be entered through pause()
    # play() -> resume -> (playing if prev state is playing or stopped, complete if previous state is complete)
    # pause() -> nop -> paused
    # stop() -> stopped
    paused

    # Complete.
    # play() -> restart -> playing
    # pause() -> paused # the cursor is still at the end. play() will return to complete again
    # stop() -> stopped
    complete

when defined(macosx) or defined(ios):
  include private/sound_al
elif defined(windows):
  include private/sound_xaudio2
#  include private.sound_al
elif defined(android):
  include private/sound_sl
elif defined(js) or defined(emscripten):
  include private/sound_js
elif defined(linux):
  include private/sound_al

when isMainModule:
  import os
  let snd1 = newSoundWithFile("/Users/yglukhov/Downloads/0897.ogg")
  let snd2 = newSoundWithFile("/Users/yglukhov/Downloads/0910.ogg")
  snd1.play()
  snd2.play()
  sleep(5000)

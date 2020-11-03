import openal, logging

var contextInited = false
var alContext* : ALCcontext

proc createContext*() =
  if contextInited: return
  contextInited = true
  var listenerPos = [ALfloat(0.0),0.0,4.0]
  var listenerVel = [ALfloat(0.0),0.0,0.0]
  var listenerOri = [ALfloat(0.0),0.0,1.0, 0.0,1.0,0.0]

  let device = alcOpenDevice(nil)
  if device.isNil:
    warn "Could not open audio device"

  alContext = alcCreateContext(device, nil)
  if alContext.isNil:
    error "Could not create audio context"
  else:
    discard alcMakeContextCurrent(alContext)

    #alGetError(); // clear any error messages
    alListenerfv(AL_POSITION, addr listenerPos[0])
    alListenerfv(AL_VELOCITY, addr listenerVel[0])
    alListenerfv(AL_ORIENTATION, addr listenerOri[0])

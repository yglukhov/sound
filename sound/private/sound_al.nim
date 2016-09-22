import openal
import stb_vorbis
import streams
proc c_malloc(size: csize): pointer {.
  importc: "malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}
proc c_realloc(p: pointer, newsize: csize): pointer {.
  importc: "realloc", header: "<stdlib.h>".}


type Sound* = ref object
    buffer: ALuint
    src: ALuint
    mGain: ALfloat
    mLooping: bool
    mDuration: float

var contextInited = false
var alContext : ALCcontext

var activeSounds = newSeq[Sound]()

proc createContext() =
    if contextInited: return
    contextInited = true
    var listenerPos = [ALfloat(0.0),0.0,4.0]
    var listenerVel = [ALfloat(0.0),0.0,0.0]
    var listenerOri = [ALfloat(0.0),0.0,1.0, 0.0,1.0,0.0]

    let device = alcOpenDevice(nil)
    if device.isNil:
        echo "Could not open device"

    alContext = alcCreateContext(device, nil)
    if alContext.isNil:
        echo "ERROR: Could not create audio context"
    else:
        discard alcMakeContextCurrent(alContext)

        #alGetError(); // clear any error messages
        alListenerfv(AL_POSITION, addr listenerPos[0])
        alListenerfv(AL_VELOCITY, addr listenerVel[0])
        alListenerfv(AL_ORIENTATION, addr listenerOri[0])

proc finalizeSound(s: Sound) =
    if s.src != 0: alDeleteSources(1, addr s.src)
    if s.buffer != 0: alDeleteBuffers(1, addr s.buffer)

proc newSoundWithVorbis(v: Vorbis): Sound =
    ## v is consumed here.
    createContext()

    if v.isNil: return
    let i = stb_vorbis_get_info(v)

    var format : ALenum
    if i.channels == 1:
        format = AL_FORMAT_MONO16
    else:
        format = AL_FORMAT_STEREO16

    let freq = ALsizei(i.sample_rate)

    var buffer : ptr uint16
    #var buffer = newSeq[uint16]() # The sound buffer data from file

    #var endian: cint = 0 # 0 for Little-Endian, 1 for Big-Endian

    const OGG_BUFFER_SIZE = 32768

    var curOffset : uint
    while true:
        # Read up to a buffer's worth of decoded sound data
        if buffer.isNil:
            buffer = cast[ptr uint16](c_malloc(OGG_BUFFER_SIZE * 2))
        else:
            buffer = cast[ptr uint16](c_realloc(buffer, ((curOffset + OGG_BUFFER_SIZE) * 2).csize))
        let dataRead = stb_vorbis_get_samples_short_interleaved(v, i.channels, cast[ptr uint16](cast[uint](buffer) + curOffset * 2), OGG_BUFFER_SIZE) * i.channels
        curOffset += uint(dataRead)
        if dataRead < OGG_BUFFER_SIZE:
            break

    stb_vorbis_close(v)

    result.new(finalizeSound)
    result.mGain = 1

    if not alContext.isNil:
        alGenBuffers(1, addr result.buffer)
        # Upload sound data to buffer
        alBufferData(result.buffer, format, buffer, ALsizei(curOffset * 2), freq)

    result.mDuration = (curOffset.ALint / (freq.ALint * i.channels).ALint).float
    c_free(buffer)

proc newSoundWithFile*(path: string): Sound =
    result = newSoundWithVorbis(stb_vorbis_open_filename(path, nil, nil))

proc newSoundWithStream*(s: Stream): Sound =
    var data = s.readAll()
    result = newSoundWithVorbis(stb_vorbis_open_memory(addr data[0], cint(data.len), nil, nil))

proc isSourcePlaying(src: ALuint): bool =
    var state: ALenum
    alGetSourcei(src, AL_SOURCE_STATE, addr state)
    result = state == AL_PLAYING

proc duration*(s: Sound): float =
    return s.mDuration

proc setLooping*(s: Sound, flag: bool) =
    s.mLooping = flag
    if s.src != 0:
        alSourcei(s.src, AL_LOOPING, ALint(flag))

proc reclaimInactiveSource(): ALuint =
    for i in 0 ..< activeSounds.len:
        let src = activeSounds[i].src
        if not src.isSourcePlaying:
            result = src
            activeSounds[i].src = 0
            activeSounds.del(i)
            break

proc stop*(s: Sound) =
    if s.src != 0:
        alSourceStop(s.src)

proc play*(s: Sound) =
    if s.buffer != 0:
        if s.src == 0:
            s.src = reclaimInactiveSource()
            if s.src == 0:
                alGenSources(1, addr s.src)
            alSourcei(s.src, AL_BUFFER, cast[ALint](s.buffer))
            alSourcef(s.src, AL_GAIN, s.mGain)
            alSourcei(s.src, AL_LOOPING, ALint(s.mLooping))
            alSourcePlay(s.src)
            activeSounds.add(s)
        else:
            alSourceStop(s.src)
            alSourcePlay(s.src)

proc `gain=`*(s: Sound, v: float) =
    s.mGain = v
    if s.src != 0:
        alSourcef(s.src, AL_GAIN, v)

proc gain*(s: Sound): float = s.mGain

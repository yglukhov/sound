
type
    ALuint* = cuint
    ALint* = cint
    ALsizei* = cint
    ALenum* = cint
    ALfloat* = cfloat

{.pragma: alimport, importc, header: "<OpenAL/OpenAL.h>".}

when defined(macosx) or defined(ios):
    {.passL: "-framework OpenAL".}

const AL_FORMAT_MONO8* : cint =                          0x1100
const AL_FORMAT_MONO16* : cint =                         0x1101
const AL_FORMAT_STEREO8* : cint =                        0x1102
const AL_FORMAT_STEREO16* : cint =                       0x1103

const AL_BUFFER* : ALenum =                              0x1009

const AL_POSITION* : ALenum =                            0x1004

const AL_DIRECTION* : ALenum =                               0x1005

const AL_VELOCITY* : ALenum =                               0x1006
const AL_ORIENTATION* : ALenum =                            0x100F

proc alGenBuffers*(n: ALsizei , buffers: ptr ALuint) {.alimport.}
proc alGenSources*(n: ALsizei, sources: ptr ALuint) {.alimport.}

proc alSourcei*(sid: ALuint, param: ALenum, value: ALint) {.alimport.}

proc alSourcePlay*(sid: ALuint) {.alimport.}


proc alBufferData*(bid: ALuint, format: ALenum, data: pointer, size: ALsizei, freq: ALsizei) {.alimport.}
proc alListenerfv*(param: ALenum, values: ptr ALfloat) {.alimport.}

proc alDeleteSources*(n: ALsizei, sources: ptr ALuint) {.alimport.}
proc alDeleteBuffers*(n: ALsizei, buffers: ptr ALuint) {.alimport.}


# ALC

type
    ALCint* = cint
    ALCdevice* = pointer
    ALCcontext* = pointer
    ALCboolean* = int8

{.pragma: alcimport, importc, header: "<OpenAL/OpenAL.h>".}

proc alcOpenDevice*(devicename: cstring): ALCdevice {.alcimport.}
proc alcCreateContext*(device: ALCdevice, attrlist: ptr ALCint): ALCcontext {.alcimport.}

proc alcMakeContextCurrent*(context: ALCcontext): ALCboolean {.alcimport.}

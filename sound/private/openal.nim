
type
  ALuint* = cuint
  ALint* = cint
  ALsizei* = cint
  ALenum* = cint
  ALfloat* = cfloat

when defined(linux):
  {.passL: "-lopenal"}
  {.pragma: alimport, importc.}
elif defined(windows):
  {.pragma: alimport, cdecl, dynlib: "OpenAL32.dll", importc.}
else:
  when defined(macosx) or defined(ios):
    {.passL: "-framework OpenAL".}
  {.pragma: alimport, importc.}

const
  AL_FORMAT_MONO8* : cint =              0x1100
  AL_FORMAT_MONO16* : cint =             0x1101
  AL_FORMAT_STEREO8* : cint =            0x1102
  AL_FORMAT_STEREO16* : cint =             0x1103

  AL_BUFFER* : ALenum =                0x1009

  AL_POSITION* : ALenum =              0x1004

  AL_DIRECTION* : ALenum =               0x1005

  AL_VELOCITY* : ALenum =              0x1006
  AL_ORIENTATION* : ALenum =             0x100F

  AL_LOOPING* : ALenum =               0x1007

  AL_FREQUENCY* : ALenum =               0x2001
  AL_BITS* : ALenum =                0x2002
  AL_CHANNELS* : ALenum =              0x2003
  AL_SIZE* : ALenum =                0x2004

  AL_GAIN* : ALenum =                0x100A

  AL_SOURCE_STATE* : ALenum =            0x1010
  AL_INITIAL* : ALenum =               0x1011
  AL_PLAYING* : ALenum =               0x1012
  AL_PAUSED* : ALenum =                0x1013
  AL_STOPPED* : ALenum =               0x1014

  AL_SEC_OFFSET* : ALenum =              0x1024
  AL_SAMPLE_OFFSET* : ALenum =           0x1025
  AL_BYTE_OFFSET* : ALenum =             0x1026

proc alGenBuffers*(n: ALsizei, buffers: ptr ALuint) {.alimport.}
proc alGenSources*(n: ALsizei, sources: ptr ALuint) {.alimport.}

proc alSourcei*(sid: ALuint, param: ALenum, value: ALint) {.alimport.}
proc alSourcef*(sid: ALuint, param: ALenum, value: ALfloat) {.alimport.}

proc alGetSourcef*(sid: ALuint, param: ALenum, value: ptr ALfloat) {.alimport.}
proc alGetSourcei*(sid: ALuint, param: ALenum, value: ptr ALint) {.alimport.}

proc alSourcePlay*(sid: ALuint) {.alimport.}
proc alSourceStop*(sid: ALuint) {.alimport.}
proc alSourcePause*(sid: ALuint) {.alimport.}

proc alGetBufferi*(bid: ALuint, param: ALenum, value: ptr ALint) {.alimport.}

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

when defined(windows):
  {.pragma: alcimport, cdecl, dynlib: "OpenAL32.dll", importc.}
else:
  {.pragma: alcimport, importc.}

proc alcOpenDevice*(devicename: cstring): ALCdevice {.alcimport.}
proc alcCreateContext*(device: ALCdevice, attrlist: ptr ALCint): ALCcontext {.alcimport.}

proc alcMakeContextCurrent*(context: ALCcontext): ALCboolean {.alcimport.}

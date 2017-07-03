import openal, context_al
import stb_vorbis
import streams

type
    DataSource* = ref object
        mDuration*: float
        mBuffer*: ALuint

proc finalizeDataSource(s: DataSource) =
    if s.mBuffer != 0: alDeleteSources(1, addr s.mBuffer)

proc newDataSource(): DataSource =
    createContext()
    result.new(finalizeDataSource)

proc c_malloc(size: csize): pointer {.
  importc: "malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}
proc c_realloc(p: pointer, newsize: csize): pointer {.
  importc: "realloc", header: "<stdlib.h>".}

proc newDataSourceWithPCMData*(data: pointer, dataLength, channels, bitsPerSample, samplesPerSecond: int): DataSource =
    result = newDataSource()

    var format : ALenum
    if channels == 1:
        if bitsPerSample == 16:
            format = AL_FORMAT_MONO16
        elif bitsPerSample == 8:
            format = AL_FORMAT_MONO8
    else:
        if bitsPerSample == 16:
            format = AL_FORMAT_STEREO16
        elif bitsPerSample == 8:
            format = AL_FORMAT_STEREO8

    let freq = ALsizei(samplesPerSecond)

    if not alContext.isNil:
        alGenBuffers(1, addr result.mBuffer)
        # Upload sound data to buffer
        alBufferData(result.mBuffer, format, data, ALsizei(dataLength), freq)

    let bytesPerSample = bitsPerSample div 8
    let samplesInChannel = dataLength div bytesPerSample
    result.mDuration = (samplesInChannel.ALint / (freq.ALint * channels).ALint).float

proc newDataSourceWithPCMData*(data: openarray[byte], channels, bitsPerSample, samplesPerSecond: int): DataSource {.inline.} =
    ## This function is only availbale for openal for now. Sorry.
    newDataSourceWithPCMData(unsafeAddr data[0], data.len, channels, bitsPerSample, samplesPerSecond)

proc newDataSourceWithVorbis(v: Vorbis): DataSource =
    ## v is consumed here.

    if v.isNil: return
    let i = stb_vorbis_get_info(v)
    const bytesPerSample = 2

    var buffer : ptr uint16
    #var buffer = newSeq[uint16]() # The sound buffer data from file

    #var endian: cint = 0 # 0 for Little-Endian, 1 for Big-Endian

    const OGG_BUFFER_SIZE = 32768

    var curOffset: uint
    while true:
        # Read up to a buffer's worth of decoded sound data
        if buffer.isNil:
            buffer = cast[ptr uint16](c_malloc(OGG_BUFFER_SIZE * bytesPerSample))
        else:
            buffer = cast[ptr uint16](c_realloc(buffer, ((curOffset + OGG_BUFFER_SIZE) * bytesPerSample).csize))
        let dataRead = stb_vorbis_get_samples_short_interleaved(v, i.channels, cast[ptr uint16](cast[uint](buffer) + curOffset * bytesPerSample), OGG_BUFFER_SIZE) * i.channels
        curOffset += uint(dataRead)
        if dataRead < OGG_BUFFER_SIZE:
            break

    stb_vorbis_close(v)
    result = newDataSourceWithPCMData(buffer, int(curOffset * bytesPerSample), i.channels, bytesPerSample * 8, int(i.sample_rate))
    c_free(buffer)

proc newDataSourceWithFile*(path: string): DataSource =
    result = newDataSourceWithVorbis(stb_vorbis_open_filename(path, nil, nil))

proc newDataSourceWithStream*(s: Stream): DataSource =
    var data = s.readAll()
    result = newDataSourceWithVorbis(stb_vorbis_open_memory(addr data[0], cint(data.len), nil, nil))

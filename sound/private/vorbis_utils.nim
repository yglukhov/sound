import stb_vorbis, streams

proc c_malloc(size: csize): pointer {.
  importc: "malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}
proc c_realloc(p: pointer, newsize: csize): pointer {.
  importc: "realloc", header: "<stdlib.h>".}

proc loadVorbis(v: Vorbis, outBuffer: var pointer, outLen, outChannels, outBitsPerSample, outSamplesPerSecond: var int) =
    ## v is consumed here.

    assert(not v.isNil)
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
    outBuffer = buffer
    outLen = int(curOffset * bytesPerSample)
    outChannels = i.channels
    outBitsPerSample = bytesPerSample * 8
    outSamplesPerSecond = int(i.sample_rate)

proc loadVorbisFile*(path: string, buffer: var pointer, len, channels, bitsPerSample, samplesPerSec: var int) =
    loadVorbis(stb_vorbis_open_filename(path, nil, nil), buffer, len, channels, bitsPerSample, samplesPerSec)

proc loadVorbisStream*(s: Stream, buffer: var pointer, len, channels, bitsPerSample, samplesPerSec: var int) =
    var data = s.readAll()
    loadVorbis(stb_vorbis_open_memory(addr data[0], cint(data.len), nil, nil), buffer, len, channels, bitsPerSample, samplesPerSec)

proc freeVorbisBuffer*(buffer: pointer) =
    c_free(buffer)

import stb_vorbis, streams

proc c_malloc(size: csize_t): pointer {.
  importc: "malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}
proc c_realloc(p: pointer, newsize: csize_t): pointer {.
  importc: "realloc", header: "<stdlib.h>".}

proc loadVorbis(v: Vorbis, outBuffer: var pointer, outLen, outChannels, outBitsPerSample, outSamplesPerSecond: var int) =
  ## v is consumed here.

  assert(not v.isNil)
  if v.isNil: return
  let i = stb_vorbis_get_info(v)

  const bytesPerSample = sizeof(uint16)

  var curOffset: uint
  var bufSz = 128 * 1024 * bytesPerSample * i.channels # 128K samples per channel
  var freeSz = bufSz
  var buffer = cast[ptr uint16](c_malloc(bufSz.csize_t))

  while true:
    # Fill up buffer from `curOffset` with `freeSz` decoded bytes
    let shortsToRead = cint(freeSz div sizeof(uint16))
    let shortsRead = stb_vorbis_get_samples_short_interleaved(v, i.channels, cast[ptr uint16](cast[uint](buffer) + curOffset), shortsToRead) * i.channels
    curOffset += uint(shortsRead * sizeof(uint16))
    if shortsRead < shortsToRead:
      break

    # Buffer is full, now double the size
    freeSz = bufSz
    bufSz *= 2
    buffer = cast[ptr uint16](c_realloc(buffer, bufSz.csize_t))

  stb_vorbis_close(v)
  outBuffer = buffer
  outLen = int(curOffset)
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

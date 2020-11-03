import winlean, streams
import context_xaudio2
import vorbis_utils

type
  DataSource* = ref object
    wfx*: WAVEFORMATEX
    data*: seq[uint8]
    mDuration*: float

proc newDataSource(): DataSource =
  createContext()
  result.new()

proc newDataSourceWithPCMData*(data: pointer, dataLength, channels, bitsPerSample, samplesPerSecond: int): DataSource =
  result = newDataSource()

  let bytesPerSample = bitsPerSample div 8
  let samplesInChannel = dataLength div bytesPerSample
  result.mDuration = samplesInChannel / (samplesPerSecond * channels)

  result.wfx.wFormatTag = 1
  result.wfx.nChannels = WORD(channels)
  result.wfx.nSamplesPerSec = DWORD(samplesPerSecond)
  result.wfx.wBitsPerSample = WORD(bitsPerSample)
  result.wfx.nBlockAlign = WORD((bitsPerSample * channels) div 8)

  result.data = newSeq[uint8](dataLength)
  copyMem(addr result.data[0], data, dataLength)

proc newDataSourceWithPCMData*(data: openarray[byte], channels, bitsPerSample, samplesPerSecond: int): DataSource {.inline.} =
  ## This function is only availbale for openal for now. Sorry.
  newDataSourceWithPCMData(unsafeAddr data[0], data.len, channels, bitsPerSample, samplesPerSecond)

proc newDataSourceWithFile*(path: string): DataSource =
  var buffer: pointer
  var len, channels, bitsPerSample, samplesPerSecond: int
  loadVorbisFile(path, buffer, len, channels, bitsPerSample, samplesPerSecond)
  result = newDataSourceWithPCMData(buffer, len, channels, bitsPerSample, samplesPerSecond)
  freeVorbisBuffer(buffer)

proc newDataSourceWithStream*(s: Stream): DataSource =
  var buffer: pointer
  var len, channels, bitsPerSample, samplesPerSecond: int
  loadVorbisStream(s, buffer, len, channels, bitsPerSample, samplesPerSecond)
  result = newDataSourceWithPCMData(buffer, len, channels, bitsPerSample, samplesPerSecond)
  freeVorbisBuffer(buffer)

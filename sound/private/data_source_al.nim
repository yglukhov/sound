import openal, context_al
import vorbis_utils
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

proc alFormat(channels, bitsPerSample: int): ALenum {.inline.} =
  if channels == 1:
    if bitsPerSample == 16:
      result = AL_FORMAT_MONO16
    elif bitsPerSample == 8:
      result = AL_FORMAT_MONO8
  else:
    if bitsPerSample == 16:
      result = AL_FORMAT_STEREO16
    elif bitsPerSample == 8:
      result = AL_FORMAT_STEREO8

proc newDataSourceWithPCMData*(data: pointer, dataLength, channels, bitsPerSample, samplesPerSecond: int): DataSource =
  result = newDataSource()

  let freq = ALsizei(samplesPerSecond)

  if not alContext.isNil:
    alGenBuffers(1, addr result.mBuffer)
    # Upload sound data to buffer
    alBufferData(result.mBuffer, alFormat(channels, bitsPerSample), data, ALsizei(dataLength), freq)

  let bytesPerSample = bitsPerSample div 8
  let samplesInChannel = dataLength div bytesPerSample
  result.mDuration = (samplesInChannel.ALint / (freq.ALint * channels).ALint).float

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
  var len, bitsPerSample, channels, samplesPerSecond: int
  loadVorbisStream(s, buffer, len, channels, bitsPerSample, samplesPerSecond)
  result = newDataSourceWithPCMData(buffer, len, channels, bitsPerSample, samplesPerSecond)
  freeVorbisBuffer(buffer)

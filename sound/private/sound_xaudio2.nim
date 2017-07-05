import dynlib, winlean
import stb_vorbis
import context_xaudio2, data_source_xaudio2

type Sound* = ref object
    sourceVoice: IXAudio2SourceVoice
    mDataSource: DataSource

var activeSounds: seq[Sound]

proc finalizeSound(s: Sound) =
    discard

proc newSound(): Sound =
    result.new(finalizeSound)

proc deleteSourceVoice(s: Sound) =
    discard

proc `dataSource=`(s: Sound, dataSource: DataSource) =
    s.mDataSource = dataSource
    if not s.sourceVoice.isNil:
        s.deleteSourceVoice()
        s.sourceVoice = nil
    if not dataSource.isNil:
        discard ixaudio2.CreateSourceVoice(ixaudio2, addr s.sourceVoice, addr dataSource.wfx, 0, 0, nil, nil, nil)
        var buf: XAUDIO2_BUFFER
        buf.pAudioData = addr dataSource.data[0]
        buf.AudioBytes = uint32(dataSource.data.len)
        echo "submit: ", s.sourceVoice.SubmitSourceBuffer(s.sourceVoice, addr buf, nil)

proc newSoundWithFile*(path: string): Sound =
    createContext()
    result = newSound()
    result.dataSource = newDataSourceWithFile(path)

proc stop*(s: Sound) =
    discard s.sourceVoice.Stop(s.sourceVoice, 0, 0)

proc play*(s: Sound) =
    discard s.sourceVoice.Start(s.sourceVoice, 0, 0)

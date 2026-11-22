import
  openal,
  mpeg

const BufferCount = 32

type
  Speaker* = object
    device: ALCdevice
    context: ALCcontext
    source: ALuint
    buffers: array[BufferCount, ALuint]
    free: seq[ALuint]
    rate: int
    queued*: int
    playedSamples*: int
    submittedSamples*: int
    underruns*: int
    ended*: bool
    started*: bool
    frame: AudioFrame

proc checkAudio() =
  ## Reports native playback errors instead of silently dropping sound.
  let error = alGetError()
  if error != AL_NO_ERROR:
    raise newException(MpegError, "OpenAL error " & $error & ".")

proc close*(speaker: var Speaker) =
  ## Releases queued buffers, the source, and the output device.
  if speaker.source != 0:
    alSourceStop(speaker.source)
    alDeleteSources(1, addr speaker.source)
    speaker.source = 0
    alDeleteBuffers(BufferCount, addr speaker.buffers[0])
  if speaker.context != nil:
    discard alcMakeContextCurrent(nil)
    alcDestroyContext(speaker.context)
    speaker.context = nil
  if speaker.device != nil:
    discard alcCloseDevice(speaker.device)
    speaker.device = nil

proc initSpeaker*(decoder: Decoder): Speaker =
  ## Opens the default physical audio output with a bounded stereo queue.
  result.rate = decoder.sampleRate
  if result.rate == 0:
    raise newException(MpegError, "The MPEG file has no audio stream.")
  result.device = alcOpenDevice(nil)
  if result.device == nil:
    raise newException(MpegError, "Cannot open the default audio device.")
  try:
    result.context = alcCreateContext(result.device, nil)
    if result.context == nil or not alcMakeContextCurrent(result.context):
      raise newException(MpegError, "Cannot create an OpenAL context.")
    alGenSources(1, addr result.source)
    alGenBuffers(BufferCount, addr result.buffers[0])
    checkAudio()
    for buffer in result.buffers:
      result.free.add(buffer)
    echo "Audio device: ", $alcGetString(result.device, ALC_DEVICE_SPECIFIER)
  except:
    result.close()
    raise

proc pump*(speaker: var Speaker, decoder: Decoder) =
  ## Reclaims played buffers, fills available slots, and starts playback.
  var processed: ALint
  alGetSourcei(speaker.source, AL_BUFFERS_PROCESSED, addr processed)
  for i in 0 ..< int(processed):
    var buffer: ALuint
    alSourceUnqueueBuffers(speaker.source, 1, addr buffer)
    speaker.free.add(buffer)
    dec speaker.queued
    speaker.playedSamples += PlmAudioSamplesPerFrame
  while speaker.free.len > 0 and not speaker.ended:
    if not decoder.decodeAudio(speaker.frame):
      speaker.ended = true
      break
    var buffer = speaker.free.pop()
    let pcm = speaker.frame.pcm16
    alBufferData(
      buffer,
      AL_FORMAT_STEREO16,
      unsafeAddr pcm[0],
      ALsizei(pcm.len * sizeof(int16)),
      ALsizei(speaker.rate)
    )
    alSourceQueueBuffers(speaker.source, 1, addr buffer)
    inc speaker.queued
    speaker.submittedSamples += speaker.frame.samples.len div 2
  var state: ALint
  alGetSourcei(speaker.source, AL_SOURCE_STATE, addr state)
  if speaker.queued > 0 and state != AL_PLAYING:
    if speaker.started:
      inc speaker.underruns
    alSourcePlay(speaker.source)
    speaker.started = true
  checkAudio()

proc time*(speaker: Speaker): float64 =
  ## Returns the audio clock from completed buffers and the device cursor.
  var offset: ALint
  alGetSourcei(speaker.source, AL_SAMPLE_OFFSET, addr offset)
  return float64(speaker.playedSamples + int(offset)) / float64(speaker.rate)

proc finished*(speaker: Speaker): bool =
  ## Returns whether the decoder and output device have drained all audio.
  speaker.ended and speaker.queued == 0

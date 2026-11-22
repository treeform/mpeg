## Low-level PL_MPEG-compatible decoder API. Returned frames are borrowed.
const
  DefaultBufferSize = 128 * 1024
  PlmAudioSamplesPerFrame* = 1152
  PlmPacketInvalidTs* = -1.0
  PlmDemuxPacketPrivate* = 0xBD
  PlmDemuxPacketAudio1* = 0xC0
  PlmDemuxPacketAudio2* = 0xC1
  PlmDemuxPacketAudio3* = 0xC2
  PlmDemuxPacketAudio4* = 0xC3
  PlmDemuxPacketVideo1* = 0xE0

type
  plm_packet_t* = object
    `type`*: cint
    pts*: float64
    length*: csize_t
    data*: ptr uint8

  plm_plane_t* = object
    width*: cuint
    height*: cuint
    data*: ptr uint8

  plm_frame_t* = object
    time*: float64
    width*: cuint
    height*: cuint
    y*: plm_plane_t
    cr*: plm_plane_t
    cb*: plm_plane_t

  plm_samples_t* = object
    time*: float64
    count*: cuint
    interleaved*: array[PlmAudioSamplesPerFrame * 2, float32]

  plm_t* = object
    demux: ptr plm_demux_t
    time: float64
    hasEnded: cint
    loop: cint
    hasDecoders: cint
    videoEnabled: cint
    videoPacketType: cint
    videoBuffer: ptr plm_buffer_t
    videoDecoder: ptr plm_video_t
    audioEnabled: cint
    audioStreamIndex: cint
    audioPacketType: cint
    audioLeadTime: float64
    audioBuffer: ptr plm_buffer_t
    audioDecoder: ptr plm_audio_t
    videoDecodeCallback: plm_video_decode_callback
    videoDecodeCallbackUserData: pointer
    audioDecodeCallback: plm_audio_decode_callback
    audioDecodeCallbackUserData: pointer

  plm_buffer_t* = object
    bitIndex: csize_t
    capacity: csize_t
    length: csize_t
    totalSize: csize_t
    discardReadBytes: cint
    hasEnded: cint
    freeWhenDone: cint
    closeWhenDone: cint
    fh: File
    loadCallback: plm_buffer_load_callback
    seekCallback: plm_buffer_seek_callback
    tellCallback: plm_buffer_tell_callback
    loadCallbackUserData: pointer
    bytes: ptr uint8
    mode: plm_buffer_mode

  VlcNode = tuple[index, value: int32]

  plm_demux_t* = object
    buffer: ptr plm_buffer_t
    destroyBufferWhenDone: cint
    systemClockRef: float64
    lastFileSize: csize_t
    lastDecodedPts: float64
    startTime: float64
    duration: float64
    startCode: cint
    hasPackHeader: cint
    hasSystemHeader: cint
    hasHeaders: cint
    numAudioStreams: cint
    numVideoStreams: cint
    currentPacket: plm_packet_t
    nextPacket: plm_packet_t

  plm_video_motion_t = object
    fullPx: cint
    isSet: cint
    rSize: cint
    h: cint
    v: cint

  plm_video_t* = object
    framerate: float64
    pixelAspectRatio: float64
    time: float64
    framesDecoded: cint
    width: cint
    height: cint
    mbWidth: cint
    mbHeight: cint
    mbSize: cint
    lumaWidth: cint
    lumaHeight: cint
    chromaWidth: cint
    chromaHeight: cint
    startCode: cint
    pictureType: cint
    motionForward: plm_video_motion_t
    motionBackward: plm_video_motion_t
    hasSequenceHeader: cint
    quantizerScale: cint
    sliceBegin: cint
    macroblockAddress: cint
    mbRow: cint
    mbCol: cint
    macroblockType: cint
    macroblockIntra: cint
    dcPredictor: array[3, cint]
    buffer: ptr plm_buffer_t
    destroyBufferWhenDone: cint
    frameCurrent: plm_frame_t
    frameForward: plm_frame_t
    frameBackward: plm_frame_t
    framesData: ptr uint8
    blockData: array[64, cint]
    intraQuantMatrix: array[64, uint8]
    nonIntraQuantMatrix: array[64, uint8]
    hasReferenceFrame: cint
    assumeNoBFrames: cint

  plm_quantizer_spec_t = object
    levels: uint16
    group: uint8
    bits: uint8

  plm_audio_t* = object
    time: float64
    samplesDecoded: cint
    samplerateIndex: cint
    bitrateIndex: cint
    version: cint
    layer: cint
    mode: cint
    bound: cint
    vPos: cint
    nextFrameDataSize: cint
    hasHeader: cint
    buffer: ptr plm_buffer_t
    destroyBufferWhenDone: cint
    allocation: array[2, array[32, ptr plm_quantizer_spec_t]]
    scaleFactorInfo: array[2, array[32, uint8]]
    scaleFactor: array[2, array[32, array[3, cint]]]
    sample: array[2, array[32, array[3, cint]]]
    samples: plm_samples_t
    D: array[1024, float32]
    V: array[2, array[1024, float32]]
    U: array[32, float32]

  plm_video_decode_callback* = proc(
    decoder: ptr plm_t, frame: ptr plm_frame_t, user: pointer
  ) {.cdecl, raises: [].}
  plm_audio_decode_callback* = proc(
    decoder: ptr plm_t, samples: ptr plm_samples_t, user: pointer
  ) {.cdecl, raises: [].}
  plm_buffer_load_callback* = proc(
    buffer: ptr plm_buffer_t, user: pointer
  ) {.cdecl, raises: [].}
  plm_buffer_seek_callback* = proc(
    buffer: ptr plm_buffer_t, offset: csize_t, user: pointer
  ) {.cdecl, raises: [].}
  plm_buffer_tell_callback* = proc(
    buffer: ptr plm_buffer_t, user: pointer
  ): csize_t {.cdecl, raises: [].}

  plm_buffer_mode = enum
    PLM_BUFFER_MODE_FILE, PLM_BUFFER_MODE_FIXED_MEM, PLM_BUFFER_MODE_RING, PLM_BUFFER_MODE_APPEND

include memory

{.push cdecl, raises: [].}

proc plm_create_with_filename*(filename: cstring): ptr plm_t
  ## Create a plmpeg instance with a filename.

proc plm_create_with_file*(fh: File, close_when_done: cint): ptr plm_t
  ## Create a plmpeg instance with a file handle.

proc plm_create_with_memory*(
  bytes: ptr uint8,
  length: csize_t,
  free_when_done: cint
): ptr plm_t
  ## Create a plmpeg instance with a pointer to memory as source.

proc plm_create_with_buffer*(
  buffer: ptr plm_buffer_t,
  destroy_when_done: cint
): ptr plm_t
  ## Create a plmpeg instance with a plm_buffer as source.

proc plm_destroy*(self: ptr plm_t)
  ## Destroys the decoder and its owned buffers.

proc plm_has_headers*(self: ptr plm_t): cint
  ## Get whether we have headers on all available streams and we can report
  ## the number of video/audio streams, video dimensions, framerate and audio
  ## samplerate.

proc plm_probe*(self: ptr plm_t, probesize: csize_t): cint
  ## Probe the MPEG-PS data to find the actual number of video and audio
  ## streams within the buffer.

proc plm_get_video_enabled*(self: ptr plm_t): cint
  ## Get or set whether video decoding is enabled.

proc plm_set_video_enabled*(self: ptr plm_t, enabled: cint)
  ## Enables or disables video decoding and buffering.

proc plm_get_num_video_streams*(self: ptr plm_t): cint
  ## Get the number of video streams (0--1) reported in the system header.

proc plm_get_width*(self: ptr plm_t): cint
  ## Get the display width/height of the video stream.

proc plm_get_height*(self: ptr plm_t): cint
  ## Returns the display height in pixels.

proc plm_get_pixel_aspect_ratio*(self: ptr plm_t): cdouble
  ## Returns the width-to-height ratio of an individual pixel.

proc plm_get_framerate*(self: ptr plm_t): cdouble
  ## Get the framerate of the video stream in frames per second.

proc plm_get_audio_enabled*(self: ptr plm_t): cint
  ## Get or set whether audio decoding is enabled.

proc plm_set_audio_enabled*(self: ptr plm_t, enabled: cint)
  ## Enables or disables decoding of the selected audio stream.

proc plm_get_num_audio_streams*(self: ptr plm_t): cint
  ## Get the number of audio streams (0--4) reported in the system header.

proc plm_set_audio_stream*(self: ptr plm_t, stream_index: cint)
  ## Set the desired audio stream (0--3).

proc plm_get_samplerate*(self: ptr plm_t): cint
  ## Get the samplerate of the audio stream in samples per second.

proc plm_get_audio_lead_time*(self: ptr plm_t): cdouble
  ## Get or set the audio lead time in seconds - the time in which audio
  ## samples are decoded in advance (or behind) the video decode time.

proc plm_set_audio_lead_time*(self: ptr plm_t, lead_time: cdouble)
  ## Sets how far ahead of video to decode audio for device buffering.

proc plm_get_time*(self: ptr plm_t): cdouble
  ## Get the current internal time in seconds.

proc plm_get_duration*(self: ptr plm_t): cdouble
  ## Get the video duration of the underlying source in seconds.

proc plm_rewind*(self: ptr plm_t)
  ## Rewind all buffers back to the beginning.

proc plm_get_loop*(self: ptr plm_t): cint
  ## Get or set looping.

proc plm_set_loop*(self: ptr plm_t, loop: cint)
  ## Enables automatic rewind at the end of the stream.

proc plm_has_ended*(self: ptr plm_t): cint
  ## Get whether the file has ended.

proc plm_set_video_decode_callback*(
  self: ptr plm_t,
  fp: plm_video_decode_callback,
  user: pointer
)
  ## Set the callback for decoded video frames used with plm_decode().

proc plm_set_audio_decode_callback*(
  self: ptr plm_t,
  fp: plm_audio_decode_callback,
  user: pointer
)
  ## Set the callback for decoded audio samples used with plm_decode().

proc plm_decode*(self: ptr plm_t, seconds: cdouble)
  ## Advances the clock and delivers due frames through registered callbacks.

proc plm_decode_video*(self: ptr plm_t): ptr plm_frame_t
  ## Returns a borrowed video frame, or nil at EOF or when data is unavailable.

proc plm_decode_audio*(self: ptr plm_t): ptr plm_samples_t
  ## Returns borrowed audio samples, or nil when no packet can be decoded.

proc plm_seek*(self: ptr plm_t, time: cdouble, seek_exact: cint): cint
  ## Seek to the specified time, clamped between 0 -- duration.

proc plm_seek_frame*(
  self: ptr plm_t,
  time: cdouble,
  seek_exact: cint
): ptr plm_frame_t
  ## Similar to plm_seek(), but will not call the video_decode_callback,
  ## audio_decode_callback or make any attempts to sync audio.

proc plm_buffer_create_with_filename*(filename: cstring): ptr plm_buffer_t
  ## Create a buffer instance with a filename.

proc plm_buffer_create_with_file*(
  fh: File,
  close_when_done: cint
): ptr plm_buffer_t
  ## Create a buffer instance with a file handle.

proc plm_buffer_create_with_callbacks*(
  load_callback: plm_buffer_load_callback,
  seek_callback: plm_buffer_seek_callback,
  tell_callback: plm_buffer_tell_callback,
  length: csize_t,
  user: pointer
): ptr plm_buffer_t
  ## Create a buffer instance with custom callbacks for loading, seeking and
  ## telling the position.

proc plm_buffer_create_with_memory*(
  bytes: ptr uint8,
  length: csize_t,
  free_when_done: cint
): ptr plm_buffer_t
  ## Create a buffer instance with a pointer to memory as source.

proc plm_buffer_create_with_capacity*(capacity: csize_t): ptr plm_buffer_t
  ## Create an empty buffer with an initial capacity.

proc plm_buffer_create_for_appending*(
  initial_capacity: csize_t
): ptr plm_buffer_t
  ## Create an empty buffer with an initial capacity.

proc plm_buffer_destroy*(self: ptr plm_buffer_t)
  ## Destroys a buffer and releases any data it owns.

proc plm_buffer_write*(
  self: ptr plm_buffer_t,
  bytes: ptr uint8,
  length: csize_t
): csize_t
  ## Copy data into the buffer.

proc plm_buffer_signal_end*(self: ptr plm_buffer_t)
  ## Mark the current byte length as the end of this buffer and signal that no
  ## more data is expected to be written to it.

proc plm_buffer_set_load_callback*(
  self: ptr plm_buffer_t,
  fp: plm_buffer_load_callback,
  user: pointer
)
  ## Set a callback that is called whenever the buffer needs more data.

proc plm_buffer_rewind*(self: ptr plm_buffer_t)
  ## Rewinds buffered input and invokes its seek callback when available.

proc plm_buffer_get_size*(self: ptr plm_buffer_t): csize_t
  ## Get the total size.

proc plm_buffer_get_remaining*(self: ptr plm_buffer_t): csize_t
  ## Get the number of remaining (yet unread) bytes in the buffer.

proc plm_buffer_has_ended*(self: ptr plm_buffer_t): cint
  ## Get whether the read position of the buffer is at the end and no more
  ## data is expected.

proc plm_demux_create*(
  buffer: ptr plm_buffer_t,
  destroy_when_done: cint
): ptr plm_demux_t
  ## Create a demuxer with a plm_buffer as source.

proc plm_demux_destroy*(self: ptr plm_demux_t)
  ## Destroy a demuxer and free all data.

proc plm_demux_has_headers*(self: ptr plm_demux_t): cint
  ## Returns true/false whether pack and system headers have been found.

proc plm_demux_probe*(self: ptr plm_demux_t, probesize: csize_t): cint
  ## Probe the file for the actual number of video/audio streams.

proc plm_demux_get_num_video_streams*(self: ptr plm_demux_t): cint
  ## Returns the number of video streams found in the system header.

proc plm_demux_get_num_audio_streams*(self: ptr plm_demux_t): cint
  ## Returns the number of audio streams found in the system header.

proc plm_demux_rewind*(self: ptr plm_demux_t)
  ## Rewind the internal buffer.

proc plm_demux_has_ended*(self: ptr plm_demux_t): cint
  ## Get whether the file has ended.

proc plm_demux_seek*(
  self: ptr plm_demux_t,
  time: cdouble,
  `type`: cint,
  force_intra: cint
): ptr plm_packet_t
  ## Seek to a packet of the specified type with a PTS just before specified
  ## time.

proc plm_demux_get_start_time*(self: ptr plm_demux_t, `type`: cint): cdouble
  ## Get the PTS of the first packet of this type.

proc plm_demux_get_duration*(self: ptr plm_demux_t, `type`: cint): cdouble
  ## Estimates duration from the first and last packet timestamps.

proc plm_demux_decode*(self: ptr plm_demux_t): ptr plm_packet_t
  ## Returns a borrowed packet, or nil when more data is needed or at EOF.

proc plm_video_create_with_buffer*(
  buffer: ptr plm_buffer_t,
  destroy_when_done: cint
): ptr plm_video_t
  ## Create a video decoder with a plm_buffer as source.

proc plm_video_destroy*(self: ptr plm_video_t)
  ## Destroy a video decoder and free all data.

proc plm_video_has_header*(self: ptr plm_video_t): cint
  ## Get whether a sequence header was found and we can accurately report on
  ## dimensions and framerate.

proc plm_video_get_framerate*(self: ptr plm_video_t): cdouble
  ## Get the framerate in frames per second.

proc plm_video_get_pixel_aspect_ratio*(self: ptr plm_video_t): cdouble
  ## Returns the width-to-height ratio of an individual pixel.

proc plm_video_get_width*(self: ptr plm_video_t): cint
  ## Get the display width/height.

proc plm_video_get_height*(self: ptr plm_video_t): cint
  ## Returns the display height in pixels.

proc plm_video_set_no_delay*(self: ptr plm_video_t, no_delay: cint)
  ## Set "no delay" mode.

proc plm_video_get_time*(self: ptr plm_video_t): cdouble
  ## Get the current internal time in seconds.

proc plm_video_set_time*(self: ptr plm_video_t, time: cdouble)
  ## Set the current internal time in seconds.

proc plm_video_rewind*(self: ptr plm_video_t)
  ## Rewind the internal buffer.

proc plm_video_has_ended*(self: ptr plm_video_t): cint
  ## Get whether the file has ended.

proc plm_video_decode*(self: ptr plm_video_t): ptr plm_frame_t
  ## Returns a borrowed frame and advances the video clock.

proc plm_audio_create_with_buffer*(
  buffer: ptr plm_buffer_t,
  destroy_when_done: cint
): ptr plm_audio_t
  ## Create an audio decoder with a plm_buffer as source.

proc plm_audio_destroy*(self: ptr plm_audio_t)
  ## Destroy an audio decoder and free all data.

proc plm_audio_has_header*(self: ptr plm_audio_t): cint
  ## Get whether a frame header was found and we can accurately report on
  ## samplerate.

proc plm_audio_get_samplerate*(self: ptr plm_audio_t): cint
  ## Get the samplerate in samples per second.

proc plm_audio_get_time*(self: ptr plm_audio_t): cdouble
  ## Get the current internal time in seconds.

proc plm_audio_set_time*(self: ptr plm_audio_t, time: cdouble)
  ## Set the current internal time in seconds.

proc plm_audio_rewind*(self: ptr plm_audio_t)
  ## Rewind the internal buffer.

proc plm_audio_has_ended*(self: ptr plm_audio_t): cint
  ## Get whether the file has ended.

proc plm_audio_decode*(self: ptr plm_audio_t): ptr plm_samples_t
  ## Returns borrowed samples for one MP2 packet and advances the audio clock.

include bitstream, demux, video, audio, playback
{.pop.}

include colors

proc plm_set_audio_enabled*(
  decoder: ptr plm_t,
  enabled: cint,
  streamIndex: cint
) {.raises: [].} =
  ## Selects an audio stream and enables it using the original Nim API.
  plm_set_audio_stream(decoder, streamIndex)
  plm_set_audio_enabled(decoder, enabled)

proc plm_frame_to_rgb*(frame: ptr plm_frame_t, rgb: ptr uint8)
    {.raises: [].} =
  ## Converts a frame to tightly packed RGB using the original Nim API.
  plm_frame_to_rgb(frame, rgb, cint(frame.width * 3))

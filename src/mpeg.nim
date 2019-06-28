import os
const libPathVer = "/src/"
const libPath = currentSourcePath().splitPath.head.splitPath.head & libPathVer
{.passC:"-I" & libPath.}
{.compile: "pl_mpeg.c".}
{.push header:"pl_mpeg.h", importc.}

type
  plm_t = distinct pointer
  plm_buffer_t = distinct pointer
  plm_demux_t = distinct pointer
  plm_video_t = distinct pointer
  plm_audio_t = distinct pointer

##  Demuxed MPEG PS packet
##  The type maps directly to the various MPEG-PES start codes. pts is the
##  presentation time stamp of the packet in seconds. Not all packets have
##  a pts value.

type
  plm_packet_t* {.bycopy.} = object
    `type`*: cint
    pts*: cdouble
    length*: csize
    data*: ptr uint8


##  Decoded Video Plane
##  The byte length of the data is width * height. Note that different planes
##  have different sizes: the Luma plane (Y) is double the size of each of
##  the two Chroma planes (Cr, Cb) - i.e. 4 times the byte length.
##  Also note that the size of the plane does *not* denote the size of the
##  displayed frame. The sizes of planes are always rounded up to the nearest
##  macroblock (16px).

type
  plm_plane_t* {.bycopy.} = object
    width*: cuint
    height*: cuint
    data*: ptr uint8


##  Decoded Video Frame
##  width and height denote the desired display size of the frame. This may be
##  different from the internal size of the 3 planes.

type
  plm_frame_t* {.bycopy.} = object
    time*: cdouble
    width*: cuint
    height*: cuint
    y*: plm_plane_t
    cr*: plm_plane_t
    cb*: plm_plane_t


##  Callback function type for decoded video frames used by the high-level
##  plm_* interface

type
  plm_video_decode_callback* = proc (self: ptr plm_t; frame: ptr plm_frame_t;
                                  user: pointer)

##  Decoded Audio Samples
##  Samples are stored as normalized (-1, 1) float either interleaved, or if
##  PLM_AUDIO_SEPARATE_CHANNELS is defined, in two separate arrays.
##  The `count` is always PLM_AUDIO_SAMPLES_PER_FRAME and just there for
##  convenience.

const
  PLM_AUDIO_SAMPLES_PER_FRAME* = 1152

type
  plm_samples_t* {.bycopy.} = object
    time*: cdouble
    count*: cuint              ##  #ifdef PLM_AUDIO_SEPARATE_CHANNELS
                ##  	float left[PLM_AUDIO_SAMPLES_PER_FRAME];
                ##  	float right[PLM_AUDIO_SAMPLES_PER_FRAME];
                ##  #else
    interleaved*: array[PLM_AUDIO_SAMPLES_PER_FRAME * 2, cfloat] ## #endif


##  Callback function type for decoded audio samples used by the high-level
##  plm_* interface

type
  plm_audio_decode_callback* = proc (self: ptr plm_t; samples: ptr plm_samples_t;
                                  user: pointer)

##  Callback function for plm_buffer when it needs more data

type
  plm_buffer_load_callback* = proc (self: ptr plm_buffer_t; user: pointer)

##  -----------------------------------------------------------------------------
##  plm_* public API
##  High-Level API for loading/demuxing/decoding MPEG-PS data
##  Create a plmpeg instance with a filename. Returns NULL if the file could not
##  be opened.

proc plm_create_with_filename*(filename: cstring): ptr plm_t
##  Create a plmpeg instance with file handle. Pass TRUE to close_when_done
##  to let plmpeg call fclose() on the handle when plm_destroy() is
##  called.

proc plm_create_with_file*(fh: ptr FILE; close_when_done: cint): ptr plm_t
##  Create a plmpeg instance with pointer to memory as source. This assumes the
##  whole file is in memory. Pass TRUE to free_when_done to let plmpeg call
##  free() on the pointer when plm_destroy() is called.

proc plm_create_with_memory*(bytes: ptr uint8; length: csize; free_when_done: cint): ptr plm_t
##  Create a plmpeg instance with a plm_buffer as source. This is also
##  called internally by all the above constructor functions.

proc plm_create_with_buffer*(buffer: ptr plm_buffer_t; destroy_when_done: cint): ptr plm_t
##  Destroy a plmpeg instance and free all data

proc plm_destroy*(self: ptr plm_t)
##  Get or set whether video decoding is enabled.

proc plm_get_video_enabled*(self: ptr plm_t): cint
proc plm_set_video_enabled*(self: ptr plm_t; enabled: cint)
##  Get or set whether audio decoding is enabled. When enabling, you can set the
##  desired audio stream (0-3) to decode.

proc plm_get_audio_enabled*(self: ptr plm_t): cint
proc plm_set_audio_enabled*(self: ptr plm_t; enabled: cint; stream_index: cint)
##  Get the display width/height of the video stream

proc plm_get_width*(self: ptr plm_t): cint
proc plm_get_height*(self: ptr plm_t): cint
##  Get the framerate of the video stream in frames per second

proc plm_get_framerate*(self: ptr plm_t): cdouble
##  Get the number of available audio streams in the file

proc plm_get_num_audio_streams*(self: ptr plm_t): cint
##  Get the samplerate of the audio stream in samples per second

proc plm_get_samplerate*(self: ptr plm_t): cint
##  Get or set the audio lead time in seconds - the time in which audio samples
##  are decoded in advance (or behind) the video decode time. Default 0.

proc plm_get_audio_lead_time*(self: ptr plm_t): cdouble
proc plm_set_audio_lead_time*(self: ptr plm_t; lead_time: cdouble)
##  Get the current internal time in seconds

proc plm_get_time*(self: ptr plm_t): cdouble
##  Rewind all buffers back to the beginning.

proc plm_rewind*(self: ptr plm_t)
##  Get or set looping. Default FALSE.

proc plm_get_loop*(self: ptr plm_t): cint
proc plm_set_loop*(self: ptr plm_t; loop: cint)
##  Get whether the file has ended. If looping is enabled, this will always
##  return FALSE.

proc plm_has_ended*(self: ptr plm_t): cint
##  Set the callback for decoded video frames used with plm_decode(). If no
##  callback is set, video data will be ignored and not be decoded.

proc plm_set_video_decode_callback*(self: ptr plm_t; fp: plm_video_decode_callback;
                                   user: pointer)
##  Set the callback for decoded audio samples used with plm_decode(). If no
##  callback is set, audio data will be ignored and not be decoded.

proc plm_set_audio_decode_callback*(self: ptr plm_t; fp: plm_audio_decode_callback;
                                   user: pointer)
##  Advance the internal timer by seconds and decode video/audio up to
##  this time. Returns TRUE/FALSE whether anything was decoded.

proc plm_decode*(self: ptr plm_t; seconds: cdouble): cint
##  Decode and return one video frame. Returns NULL if no frame could be decoded
##  (either because the source ended or data is corrupt). If you only want to
##  decode video, you should disable audio via plm_set_audio_enabled().
##  The returned plm_frame_t is valid until the next call to
##  plm_decode_video call or until the plm_destroy is called.

proc plm_decode_video*(self: ptr plm_t): ptr plm_frame_t
##  Decode and return one audio frame. Returns NULL if no frame could be decoded
##  (either because the source ended or data is corrupt). If you only want to
##  decode audio, you should disable video via plm_set_video_enabled().
##  The returned plm_samples_t is valid until the next call to
##  plm_decode_video or until the plm_destroy is called.

proc plm_decode_audio*(self: ptr plm_t): ptr plm_samples_t
##  -----------------------------------------------------------------------------
##  plm_buffer public API
##  Provides the data source for all other plm_* interfaces
##  The default size for buffers created from files or by the high-level API

##  Create a buffer instance with a filename. Returns NULL if the file could not
##  be opened.

proc plm_buffer_create_with_filename*(filename: cstring): ptr plm_buffer_t
##  Create a buffer instance with file handle. Pass TRUE to close_when_done
##  to let plmpeg call fclose() on the handle when plm_destroy() is
##  called.

proc plm_buffer_create_with_file*(fh: ptr FILE; close_when_done: cint): ptr plm_buffer_t
##  Create a buffer instance with a pointer to memory as source. This assumes
##  the whole file is in memory. Pass 1 to free_when_done to let plmpeg call
##  free() on the pointer when plm_destroy() is called.

proc plm_buffer_create_with_memory*(bytes: ptr uint8; length: csize;
                                   free_when_done: cint): ptr plm_buffer_t
##  Create an empty buffer with an initial capacity. The buffer will grow
##  as needed.

proc plm_buffer_create_with_capacity*(capacity: csize): ptr plm_buffer_t
##  Destroy a buffer instance and free all data

proc plm_buffer_destroy*(self: ptr plm_buffer_t)
##  Copy data into the buffer. If the data to be written is larger than the
##  available space, the buffer will realloc() with a larger capacity.
##  Returns the number of bytes written. This will always be the same as the
##  passed in length, except when the buffer was created _with_memory() for
##  which _write() is forbidden.

proc plm_buffer_write*(self: ptr plm_buffer_t; bytes: ptr uint8; length: csize): csize
##  Set a callback that is called whenever the buffer needs more data

proc plm_buffer_set_load_callback*(self: ptr plm_buffer_t;
                                  fp: plm_buffer_load_callback; user: pointer)
##  Rewind the buffer back to the beginning. When loading from a file handle,
##  this also seeks to the beginning of the file.

proc plm_buffer_rewind*(self: ptr plm_buffer_t)
##  -----------------------------------------------------------------------------
##  plm_demux public API
##  Demux an MPEG Program Stream (PS) data into separate packages
##  Various Packet Types

var PLM_DEMUX_PACKET_PRIVATE*: cint = 0x000000BD

var PLM_DEMUX_PACKET_AUDIO_1*: cint = 0x000000C0

var PLM_DEMUX_PACKET_AUDIO_2*: cint = 0x000000C1

var PLM_DEMUX_PACKET_AUDIO_3*: cint = 0x000000C2

var PLM_DEMUX_PACKET_AUDIO_4*: cint = 0x000000C2

var PLM_DEMUX_PACKET_VIDEO_1*: cint = 0x000000E0

##  Create a demuxer with a plm_buffer as source

proc plm_demux_create*(buffer: ptr plm_buffer_t; destroy_when_done: cint): ptr plm_demux_t
##  Destroy a demuxer and free all data

proc plm_demux_destroy*(self: ptr plm_demux_t)
##  Returns the number of video streams found in the system header.

proc plm_demux_get_num_video_streams*(self: ptr plm_demux_t): cint
##  Returns the number of audio streams found in the system header.

proc plm_demux_get_num_audio_streams*(self: ptr plm_demux_t): cint
##  Rewinds the internal buffer. See plm_buffer_rewind().

proc plm_demux_rewind*(self: ptr plm_demux_t)
##  Decode and return the next packet. The returned packet_t is valid until
##  the next call to plm_demux_decode() or until the demuxer is destroyed.

proc plm_demux_decode*(self: ptr plm_demux_t): ptr plm_packet_t
##  -----------------------------------------------------------------------------
##  plm_video public API
##  Decode MPEG1 Video ("mpeg1") data into raw YCrCb frames
##  Create a video decoder with a plm_buffer as source

proc plm_video_create_with_buffer*(buffer: ptr plm_buffer_t; destroy_when_done: cint): ptr plm_video_t
##  Destroy a video decoder and free all data

proc plm_video_destroy*(self: ptr plm_video_t)
##  Get the framerate in frames per second

proc plm_video_get_framerate*(self: ptr plm_video_t): cdouble
##  Get the display width/height

proc plm_video_get_width*(self: ptr plm_video_t): cint
proc plm_video_get_height*(self: ptr plm_video_t): cint
##  Set "no delay" mode. When enabled, the decoder assumes that the video does
##  *not* contain any B-Frames. This is useful for reducing lag when streaming.

proc plm_video_set_no_delay*(self: ptr plm_video_t; no_delay: cint)
##  Get the current internal time in seconds

proc plm_video_get_time*(self: ptr plm_video_t): cdouble
##  Rewinds the internal buffer. See plm_buffer_rewind().

proc plm_video_rewind*(self: ptr plm_video_t)
##  Decode and return one frame of video and advance the internal time by
##  1/framerate seconds. The returned frame_t is valid until the next call of
##  plm_video_decode() or until the video decoder is destroyed.

proc plm_video_decode*(self: ptr plm_video_t): ptr plm_frame_t
##  Convert the YCrCb data of a frame into an interleaved RGB buffer. The buffer
##  pointed to by *rgb must have a size of (frame->width * frame->height * 3)
##  bytes.

proc plm_frame_to_rgb*(frame: ptr plm_frame_t; rgb: ptr uint8)
##  -----------------------------------------------------------------------------
##  plm_audio public API
##  Decode MPEG-1 Audio Layer II ("mp2") data into raw samples
##  Create an audio decoder with a plm_buffer as source

proc plm_audio_create_with_buffer*(buffer: ptr plm_buffer_t; destroy_when_done: cint): ptr plm_audio_t
##  Destroy an audio decoder and free all data

proc plm_audio_destroy*(self: ptr plm_audio_t)
##  Get the samplerate in samples per second

proc plm_audio_get_samplerate*(self: ptr plm_audio_t): cint
##  Get the current internal time in seconds

proc plm_audio_get_time*(self: ptr plm_audio_t): cdouble
##  Rewinds the internal buffer. See plm_buffer_rewind().

proc plm_audio_rewind*(self: ptr plm_audio_t)
##  Decode and return one "frame" of audio and advance the internal time by
##  (PLM_AUDIO_SAMPLES_PER_FRAME/samplerate) seconds. The returned samples_t
##  is valid until the next call of plm_audio_decode() or until the audio
##  decoder is destroyed.

proc plm_audio_decode*(self: ptr plm_audio_t): ptr plm_samples_t

{.pop.}
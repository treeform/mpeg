/*
PL_MPEG - MPEG1 Video decoder, MP2 Audio decoder, MPEG-PS demuxer

Dominic Szablewski - https://phoboslab.org


-- LICENSE: The MIT License(MIT)

Copyright(c) 2019 Dominic Szablewski

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files(the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions :
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.




-- Synopsis

// Define `PL_MPEG_IMPLEMENTATION` in *one* C/C++ file before including this
// library to create the implementation.

#define PL_MPEG_IMPLEMENTATION
#include "plmpeg.h"

// This function gets called for each decoded video frame
void my_video_callback(plm_t *plm, plm_frame_t *frame, void *user) {
	// Do something with frame->y.data, frame->cr.data, frame->cb.data
}

// This function gets called for each decoded audio frame
void my_audio_callback(plm_t *plm, plm_samples_t *frame, void *user) {
	// Do something with samples->interleaved
}

// Load a .mpg (MPEG Program Stream) file
plm_t *plm = plm_create_with_filename("some-file.mpg");

// Install the video & audio decode callbacks
plm_set_video_decode_callback(plm, my_video_callback, my_data);
plm_set_audio_decode_callback(plm, my_audio_callback, my_data);


// Decode
do {
	plm_decode(plm, time_since_last_call);
} while (!plm_has_ended(plm));

// All done
plm_destroy(plm);



-- Documentation

This library provides several interfaces to load, demux and decode MPEG video
and audio data. A high-level API combines the demuxer, video & audio decoders
in an easy to use wrapper.

Lower-level APIs for accessing the demuxer, video decoder and audio decoder,
as well as providing different data sources are also available.

Interfaces are written in an object orientet style, meaning you create object
instances via various different constructor functions (plm_*create()),
do some work on them and later dispose them via plm_*destroy().

plm_*		-- the high-level interface, combining demuxer and decoders
plm_buffer_* -- the data source used by all interfaces
plm_demux_*  -- the MPEG-PS demuxer
plm_video_*  -- the MPEG1 Video ("mpeg1") decoder
plm_audio_*  -- the MPEG1 Audio Layer II ("mp2") decoder


This library uses malloc(), realloc() and free() to manage memory. Typically
all allocation happens up-front when creating the interface. However, the
default buffer size may be too small for certain inputs. In these cases plmpeg
will realloc() the buffer with a larger size whenever needed. You can configure
the default buffer size by defining PLM_BUFFER_DEFAULT_SIZE *before*
including this library.

With the high-level interface you have two options to decode video & audio:

1) Use plm_decode() and just hand over the delta time since the last call.
It will decode everything needed and call your callbacks (specified through
plm_set_{video|audio}_decode_callback()) any number of times.

2) Use plm_decode_video() and plm_decode_audio() to decode exactly one
frame of video or audio data at a time. How you handle the synchronization of
both streams is up to you.

If you only want to decode video *or* audio through these functions, you should
disable the other stream (plm_set_{video|audio}_enabled(FALSE))


Video data is decoded into a struct with all 3 planes (Y, Cr, Cb) stored in
separate buffers. You can either convert this to RGB on the CPU (slow) via the
plm_frame_to_rgb() function or do it on the GPU with the following matrix:

mat4 rec601 = mat4(
	1.16438,  0.00000,  1.59603, -0.87079,
	1.16438, -0.39176, -0.81297,  0.52959,
	1.16438,  2.01723,  0.00000, -1.08139,
	0, 0, 0, 1
);
gl_FragColor = vec4(y, cb, cr, 1.0) * rec601;

Audio data is decoded into a struct with either one single float array with the
samples for the left and right channel interleaved, or if the
PLM_AUDIO_SEPARATE_CHANNELS is defined *before* including this library, into
two separate float arrays - one for each channel.


See below for detailed the API documentation.

*/


#ifndef PL_MPEG_H
#define PL_MPEG_H

#include <stdint.h>
#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif

// -----------------------------------------------------------------------------
// Public Data Types


// Object types for the various interfaces

typedef struct plm_t plm_t;
typedef struct plm_buffer_t plm_buffer_t;
typedef struct plm_demux_t plm_demux_t;
typedef struct plm_video_t plm_video_t;
typedef struct plm_audio_t plm_audio_t;


// Demuxed MPEG PS packet
// The type maps directly to the various MPEG-PES start codes. pts is the
// presentation time stamp of the packet in seconds. Not all packets have
// a pts value.

typedef struct {
	int type;
	double pts;
	size_t length;
	uint8_t *data;
} plm_packet_t;


// Decoded Video Plane
// The byte length of the data is width * height. Note that different planes
// have different sizes: the Luma plane (Y) is double the size of each of
// the two Chroma planes (Cr, Cb) - i.e. 4 times the byte length.
// Also note that the size of the plane does *not* denote the size of the
// displayed frame. The sizes of planes are always rounded up to the nearest
// macroblock (16px).

typedef struct {
	unsigned int width;
	unsigned int height;
	uint8_t *data;
} plm_plane_t;


// Decoded Video Frame
// width and height denote the desired display size of the frame. This may be
// different from the internal size of the 3 planes.

typedef struct {
	double time;
	unsigned int width;
	unsigned int height;
	plm_plane_t y;
	plm_plane_t cr;
	plm_plane_t cb;
} plm_frame_t;


// Callback function type for decoded video frames used by the high-level
// plm_* interface

typedef void(*plm_video_decode_callback)
	(plm_t *self, plm_frame_t *frame, void *user);


// Decoded Audio Samples
// Samples are stored as normalized (-1, 1) float either interleaved, or if
// PLM_AUDIO_SEPARATE_CHANNELS is defined, in two separate arrays.
// The `count` is always PLM_AUDIO_SAMPLES_PER_FRAME and just there for
// convenience.

#define PLM_AUDIO_SAMPLES_PER_FRAME 1152

typedef struct {
	double time;
	unsigned int count;
	// #ifdef PLM_AUDIO_SEPARATE_CHANNELS
	// 	float left[PLM_AUDIO_SAMPLES_PER_FRAME];
	// 	float right[PLM_AUDIO_SAMPLES_PER_FRAME];
	// #else
		float interleaved[PLM_AUDIO_SAMPLES_PER_FRAME * 2];
	//#endif
} plm_samples_t;


// Callback function type for decoded audio samples used by the high-level
// plm_* interface

typedef void(*plm_audio_decode_callback)
	(plm_t *self, plm_samples_t *samples, void *user);


// Callback function for plm_buffer when it needs more data

typedef void(*plm_buffer_load_callback)(plm_buffer_t *self, void *user);



// -----------------------------------------------------------------------------
// plm_* public API
// High-Level API for loading/demuxing/decoding MPEG-PS data


// Create a plmpeg instance with a filename. Returns NULL if the file could not
// be opened.

plm_t *plm_create_with_filename(const char *filename);


// Create a plmpeg instance with file handle. Pass TRUE to close_when_done
// to let plmpeg call fclose() on the handle when plm_destroy() is
// called.

plm_t *plm_create_with_file(FILE *fh, int close_when_done);


// Create a plmpeg instance with pointer to memory as source. This assumes the
// whole file is in memory. Pass TRUE to free_when_done to let plmpeg call
// free() on the pointer when plm_destroy() is called.

plm_t *plm_create_with_memory(uint8_t *bytes, size_t length, int free_when_done);


// Create a plmpeg instance with a plm_buffer as source. This is also
// called internally by all the above constructor functions.

plm_t *plm_create_with_buffer(plm_buffer_t *buffer, int destroy_when_done);


// Destroy a plmpeg instance and free all data

void plm_destroy(plm_t *self);


// Get or set whether video decoding is enabled.

int plm_get_video_enabled(plm_t *self);
void plm_set_video_enabled(plm_t *self, int enabled);


// Get or set whether audio decoding is enabled. When enabling, you can set the
// desired audio stream (0-3) to decode.

int plm_get_audio_enabled(plm_t *self);
void plm_set_audio_enabled(plm_t *self, int enabled, int stream_index);


// Get the display width/height of the video stream

int plm_get_width(plm_t *self);
int plm_get_height(plm_t *self);


// Get the framerate of the video stream in frames per second

double plm_get_framerate(plm_t *self);


// Get the number of available audio streams in the file

int plm_get_num_audio_streams(plm_t *self);


// Get the samplerate of the audio stream in samples per second

int plm_get_samplerate(plm_t *self);


// Get or set the audio lead time in seconds - the time in which audio samples
// are decoded in advance (or behind) the video decode time. Default 0.

double plm_get_audio_lead_time(plm_t *self);
void plm_set_audio_lead_time(plm_t *self, double lead_time);


// Get the current internal time in seconds

double plm_get_time(plm_t *self);


// Rewind all buffers back to the beginning.

void plm_rewind(plm_t *self);


// Get or set looping. Default FALSE.

int plm_get_loop(plm_t *self);
void plm_set_loop(plm_t *self, int loop);


// Get whether the file has ended. If looping is enabled, this will always
// return FALSE.

int plm_has_ended(plm_t *self);


// Set the callback for decoded video frames used with plm_decode(). If no
// callback is set, video data will be ignored and not be decoded.

void plm_set_video_decode_callback(plm_t *self, plm_video_decode_callback fp, void *user);


// Set the callback for decoded audio samples used with plm_decode(). If no
// callback is set, audio data will be ignored and not be decoded.

void plm_set_audio_decode_callback(plm_t *self, plm_audio_decode_callback fp, void *user);


// Advance the internal timer by seconds and decode video/audio up to
// this time. Returns TRUE/FALSE whether anything was decoded.

int plm_decode(plm_t *self, double seconds);


// Decode and return one video frame. Returns NULL if no frame could be decoded
// (either because the source ended or data is corrupt). If you only want to
// decode video, you should disable audio via plm_set_audio_enabled().
// The returned plm_frame_t is valid until the next call to
// plm_decode_video call or until the plm_destroy is called.

plm_frame_t *plm_decode_video(plm_t *self);


// Decode and return one audio frame. Returns NULL if no frame could be decoded
// (either because the source ended or data is corrupt). If you only want to
// decode audio, you should disable video via plm_set_video_enabled().
// The returned plm_samples_t is valid until the next call to
// plm_decode_video or until the plm_destroy is called.

plm_samples_t *plm_decode_audio(plm_t *self);



// -----------------------------------------------------------------------------
// plm_buffer public API
// Provides the data source for all other plm_* interfaces


// The default size for buffers created from files or by the high-level API

#ifndef PLM_BUFFER_DEFAULT_SIZE
#define PLM_BUFFER_DEFAULT_SIZE (128 * 1024)
#endif


// Create a buffer instance with a filename. Returns NULL if the file could not
// be opened.

plm_buffer_t *plm_buffer_create_with_filename(const char *filename);


// Create a buffer instance with file handle. Pass TRUE to close_when_done
// to let plmpeg call fclose() on the handle when plm_destroy() is
// called.

plm_buffer_t *plm_buffer_create_with_file(FILE *fh, int close_when_done);


// Create a buffer instance with a pointer to memory as source. This assumes
// the whole file is in memory. Pass 1 to free_when_done to let plmpeg call
// free() on the pointer when plm_destroy() is called.

plm_buffer_t *plm_buffer_create_with_memory(uint8_t *bytes, size_t length, int free_when_done);


// Create an empty buffer with an initial capacity. The buffer will grow
// as needed.

plm_buffer_t *plm_buffer_create_with_capacity(size_t capacity);


// Destroy a buffer instance and free all data

void plm_buffer_destroy(plm_buffer_t *self);


// Copy data into the buffer. If the data to be written is larger than the
// available space, the buffer will realloc() with a larger capacity.
// Returns the number of bytes written. This will always be the same as the
// passed in length, except when the buffer was created _with_memory() for
// which _write() is forbidden.

size_t plm_buffer_write(plm_buffer_t *self, uint8_t *bytes, size_t length);


// Set a callback that is called whenever the buffer needs more data

void plm_buffer_set_load_callback(plm_buffer_t *self, plm_buffer_load_callback fp, void *user);


// Rewind the buffer back to the beginning. When loading from a file handle,
// this also seeks to the beginning of the file.

void plm_buffer_rewind(plm_buffer_t *self);



// -----------------------------------------------------------------------------
// plm_demux public API
// Demux an MPEG Program Stream (PS) data into separate packages


// Various Packet Types

static const int PLM_DEMUX_PACKET_PRIVATE = 0xBD;
static const int PLM_DEMUX_PACKET_AUDIO_1 = 0xC0;
static const int PLM_DEMUX_PACKET_AUDIO_2 = 0xC1;
static const int PLM_DEMUX_PACKET_AUDIO_3 = 0xC2;
static const int PLM_DEMUX_PACKET_AUDIO_4 = 0xC2;
static const int PLM_DEMUX_PACKET_VIDEO_1 = 0xE0;


// Create a demuxer with a plm_buffer as source

plm_demux_t *plm_demux_create(plm_buffer_t *buffer, int destroy_when_done);


// Destroy a demuxer and free all data

void plm_demux_destroy(plm_demux_t *self);


// Returns the number of video streams found in the system header.

int plm_demux_get_num_video_streams(plm_demux_t *self);


// Returns the number of audio streams found in the system header.

int plm_demux_get_num_audio_streams(plm_demux_t *self);


// Rewinds the internal buffer. See plm_buffer_rewind().

void plm_demux_rewind(plm_demux_t *self);


// Decode and return the next packet. The returned packet_t is valid until
// the next call to plm_demux_decode() or until the demuxer is destroyed.

plm_packet_t *plm_demux_decode(plm_demux_t *self);



// -----------------------------------------------------------------------------
// plm_video public API
// Decode MPEG1 Video ("mpeg1") data into raw YCrCb frames


// Create a video decoder with a plm_buffer as source

plm_video_t *plm_video_create_with_buffer(plm_buffer_t *buffer, int destroy_when_done);


// Destroy a video decoder and free all data

void plm_video_destroy(plm_video_t *self);


// Get the framerate in frames per second

double plm_video_get_framerate(plm_video_t *self);


// Get the display width/height

int plm_video_get_width(plm_video_t *self);
int plm_video_get_height(plm_video_t *self);


// Set "no delay" mode. When enabled, the decoder assumes that the video does
// *not* contain any B-Frames. This is useful for reducing lag when streaming.

void plm_video_set_no_delay(plm_video_t *self, int no_delay);


// Get the current internal time in seconds

double plm_video_get_time(plm_video_t *self);


// Rewinds the internal buffer. See plm_buffer_rewind().

void plm_video_rewind(plm_video_t *self);


// Decode and return one frame of video and advance the internal time by
// 1/framerate seconds. The returned frame_t is valid until the next call of
// plm_video_decode() or until the video decoder is destroyed.

plm_frame_t *plm_video_decode(plm_video_t *self);


// Convert the YCrCb data of a frame into an interleaved RGB buffer. The buffer
// pointed to by *rgb must have a size of (frame->width * frame->height * 3)
// bytes.

void plm_frame_to_rgb(plm_frame_t *frame, uint8_t *rgb);



// -----------------------------------------------------------------------------
// plm_audio public API
// Decode MPEG-1 Audio Layer II ("mp2") data into raw samples


// Create an audio decoder with a plm_buffer as source

plm_audio_t *plm_audio_create_with_buffer(plm_buffer_t *buffer, int destroy_when_done);


// Destroy an audio decoder and free all data

void plm_audio_destroy(plm_audio_t *self);


// Get the samplerate in samples per second

int plm_audio_get_samplerate(plm_audio_t *self);


// Get the current internal time in seconds

double plm_audio_get_time(plm_audio_t *self);


// Rewinds the internal buffer. See plm_buffer_rewind().

void plm_audio_rewind(plm_audio_t *self);


// Decode and return one "frame" of audio and advance the internal time by
// (PLM_AUDIO_SAMPLES_PER_FRAME/samplerate) seconds. The returned samples_t
// is valid until the next call of plm_audio_decode() or until the audio
// decoder is destroyed.

plm_samples_t *plm_audio_decode(plm_audio_t *self);



#ifdef __cplusplus
}
#endif

#endif // PL_MPEG_H
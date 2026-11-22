import
  std/os,
  benchy, mpeg

let
  path =
    if paramCount() > 0:
      paramStr(1)
    else:
      currentSourcePath().parentDir / "data/stereo.mpg"
  video = openMpeg(path)
  audio = openMpeg(path)

video.audioEnabled = false
audio.videoEnabled = false

timeIt "video decode and RGBA conversion", 10:
  video.rewind()
  var
    frame: VideoFrame
    count = 0
  while video.decodeVideo(frame):
    inc count
  keep(count)

timeIt "audio decode and PCM conversion", 10:
  audio.rewind()
  var
    frame: AudioFrame
    count = 0
  while audio.decodeAudio(frame):
    count += frame.pcm16.len
  keep(count)

video.close()
audio.close()

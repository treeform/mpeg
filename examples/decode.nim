import
  std/[math, os],
  mpeg

proc main() =
  ## Decodes both streams and reports frame counts and audio level.
  let
    path =
      if paramCount() > 0:
        paramStr(1)
      else:
        currentSourcePath().parentDir.parentDir / "tests/data/stereo.mpg"
    decoder = openMpeg(path)
  defer: decoder.close()
  echo decoder.width, "x", decoder.height, " at ", decoder.frameRate, " fps"
  echo "Audio: ", decoder.sampleRate, " Hz, interleaved stereo"
  var
    video: VideoFrame
    audio: AudioFrame
    videos, samples = 0
    energy: float64
    videoDone, audioDone: bool
  while not videoDone or not audioDone:
    if not videoDone and (audioDone or video.time <= audio.time):
      if decoder.decodeVideo(video):
        inc videos
      else:
        videoDone = true
    elif not audioDone:
      if decoder.decodeAudio(audio):
        for sample in audio.samples:
          energy += float64(sample) ^ 2
        samples += audio.samples.len
      else:
        audioDone = true
  echo "Video frames: ", videos
  echo "Audio sample frames: ", samples div 2
  if samples > 0:
    echo "Audio RMS: ", sqrt(energy / float64(samples))

main()

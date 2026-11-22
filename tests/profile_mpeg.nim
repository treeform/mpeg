## Capture the stereo fixture with Fluffy. Pass the trace output path as argv[1].
when not defined(mpegProfile):
  {.error: "Build with -d:mpegProfile to enable decoder tracing".}

import std/os, fluffy/measure, mpeg

proc main() =
  let
    path = currentSourcePath().parentDir / "data" / "stereo.mpg"
    tracePath = if paramCount() == 0: "tmp/profile_mpeg.json" else: paramStr(1)
    video = openMpeg(path)
    audio = openMpeg(path)
  defer:
    video.close()
    audio.close()
  if tracePath.parentDir.len > 0: createDir(tracePath.parentDir)
  video.audioEnabled = false
  audio.videoEnabled = false
  var
    v: VideoFrame
    a: AudioFrame
    pcm: array[PlmAudioSamplesPerFrame * 2, int16]
  doAssert video.decodeVideo(v) and audio.decodeAudio(a)
  video.rewind()
  audio.rewind()
  # Limit detailed captures to stay within Fluffy's event budget.
  const
    frames = when defined(mpegProfileDetail): 4 else: 60
    packets = when defined(mpegProfileDetail): 4 else: 84
  startTrace()
  defer:
    endTrace()
    dumpMeasures(tracePath)
  for i in 0..<frames:
    doAssert video.decodeVideo(v)
  for i in 0..<packets:
    doAssert audio.decodeAudio(a)
    doAssert a.pcm16(pcm) == pcm.len

main()

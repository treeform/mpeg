import
  std/[monotimes, os, times],
  mpeg,
  speakers

proc main() =
  ## Plays a clip through the default sound device and verifies completion.
  let
    path =
      if paramCount() > 0:
        paramStr(1)
      else:
        currentSourcePath().parentDir / "data/stereo.mpg"
    decoder = openMpeg(path)
  defer: decoder.close()
  decoder.videoEnabled = false
  var speaker = initSpeaker(decoder)
  defer: speaker.close()
  let started = getMonoTime()
  while not speaker.finished:
    speaker.pump(decoder)
    if (getMonoTime() - started).inSeconds > 300:
      raise newException(MpegError, "Audio output did not finish in time.")
    sleep(5)
  doAssert speaker.started
  doAssert speaker.playedSamples == speaker.submittedSamples
  doAssert speaker.playedSamples > 0
  doAssert speaker.underruns == 0
  echo "Played ", speaker.playedSamples, " stereo sample frames at ",
    decoder.sampleRate, " Hz; underruns: ", speaker.underruns, "."

main()

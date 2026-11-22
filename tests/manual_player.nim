import
  std/[monotimes, options, os, times],
  boxy, mpeg, opengl, windy,
  speakers

proc main() =
  ## Displays video while using the actual sound-device cursor as its clock.
  let
    path =
      if paramCount() > 0:
        paramStr(1)
      else:
        currentSourcePath().parentDir / "data/stereo.mpg"
    hold = paramCount() > 1 and paramStr(2) == "--hold"
    decoder = openMpeg(path)
  defer: decoder.close()
  if decoder.width == 0:
    raise newException(MpegError, "The file contains no video.")
  let
    window = newWindow("MPEG playback", ivec2(810, 490))
    hasAudio = decoder.hasAudio
  window.makeContextCurrent()
  loadExtensions()
  let
    renderer = newBoxy()
    image = newImage(decoder.width, decoder.height)
  var speaker: Speaker
  if hasAudio:
    speaker = initSpeaker(decoder)
  defer: speaker.close()
  var
    frame: VideoFrame
    pending = decoder.decodeVideo(frame)
    displayed = 0
    finished = false
    audioEnd = none(MonoTime)
  let started = getMonoTime()
  window.onButtonPress = proc(button: Button) =
    ## Closes the player when Escape is pressed.
    if button == KeyEscape:
      window.closeRequested = true
  while not window.closeRequested:
    pollEvents()
    var clock = float64((getMonoTime() - started).inMicroseconds) / 1_000_000
    if hasAudio:
      speaker.pump(decoder)
      clock = speaker.time
      if speaker.finished:
        if audioEnd.isNone:
          audioEnd = some(getMonoTime())
        clock += float64((getMonoTime() - audioEnd.get).inMicroseconds) /
          1_000_000
    var changed = false
    while pending and frame.time <= clock:
      copyMem(addr image.data[0], addr frame.rgba[0], frame.rgba.len)
      changed = true
      inc displayed
      pending = decoder.decodeVideo(frame)
    if changed:
      renderer.addImage("video", image, mipmaps = false)
    if displayed > 0:
      renderer.beginFrame(window.size)
      let
        scale = min(
          window.size.x.float32 / image.width.float32,
          window.size.y.float32 / image.height.float32
        )
        size = vec2(image.width.float32, image.height.float32) * scale
        position = (window.size.vec2 - size) / 2
      renderer.drawImage("video", rect(position, size))
      renderer.endFrame()
      window.swapBuffers()
    if not pending and (not hasAudio or speaker.finished) and not finished:
      finished = true
      echo "Displayed ", displayed, " frames; audio sample frames played: ",
        speaker.playedSamples, "; underruns: ", speaker.underruns, "."
      if not hold:
        break
    sleep(5)

main()

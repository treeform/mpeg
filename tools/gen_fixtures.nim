import std/[os, osproc]

const DataPath = currentSourcePath().parentDir.parentDir / "tests/data"

proc ffmpeg(arguments: openArray[string]) =
  ## Runs FFmpeg and stops if a fixture or reference could not be generated.
  let command = quoteShellCommand(
    @["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"] & @arguments
  )
  if execCmd(command) != 0:
    raise newException(IOError, "FFmpeg fixture generation failed.")

createDir(DataPath)
ffmpeg([
  "-f", "lavfi", "-i", "testsrc2=size=162x98:rate=30:duration=2",
  "-f", "lavfi", "-i",
  "aevalsrc=0.25*sin(2*PI*440*t)|0.125*sin(2*PI*880*t):s=48000:d=2",
  "-r", "30", "-fps_mode", "cfr", "-c:v", "mpeg1video", "-q:v", "3",
  "-bf", "2", "-g", "15", "-c:a", "mp2", "-b:a", "192k", "-ar", "48000",
  "-ac", "2", "-f", "mpeg", DataPath / "stereo.mpg"
])
ffmpeg([
  "-i", DataPath / "stereo.mpg", "-map", "0:a:0", "-frames:a", "6",
  "-c:a", "pcm_f32le", "-f", "f32le", DataPath / "stereo.f32"
])
ffmpeg([
  "-i", DataPath / "stereo.mpg", "-map", "0:v:0", "-frames:v", "1",
  "-pix_fmt", "rgb24", "-f", "rawvideo", DataPath / "stereo.rgb"
])
ffmpeg([
  "-i", DataPath / "stereo.mpg", "-vf", "select=eq(n\\,59)",
  "-frames:v", "1", "-pix_fmt", "rgb24", "-f", "rawvideo",
  DataPath / "stereo-last.rgb"
])
ffmpeg([
  "-f", "lavfi", "-i", "testsrc2=size=64x48:rate=25:duration=0.48",
  "-r", "25", "-c:v", "mpeg1video", "-q:v", "3", "-bf", "0", "-an",
  "-f", "mpeg", DataPath / "video.mpg"
])
ffmpeg([
  "-f", "lavfi", "-i", "testsrc2=size=64x48:rate=24:duration=1",
  "-f", "lavfi", "-i", "sine=frequency=660:sample_rate=44100:duration=1",
  "-r", "24", "-c:v", "mpeg1video", "-q:v", "3", "-bf", "0",
  "-c:a", "mp2", "-b:a", "128k", "-ar", "44100", "-ac", "1",
  "-f", "mpeg", DataPath / "mono.mpg"
])

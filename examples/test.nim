import ../src/mpeg, flippy, strformat

# Load mmpeg file (only spesific format is supported)
var plm = plm_create_with_filename("bjork-all-is-full-of-love.mpg")

# Disable audo for now
plm_set_audio_enabled(plm, 0, 0)

# Will use Flippy image library to write images.
# Create a an image that will hold 1 frame.
var image = newImage(plm_get_width(plm), plm_get_height(plm), 3)

# For the first 100 frames.
for i in 0..100:
  echo i
  # Deconde a single frame
  var frame = plm_decode_video(plm)
  # Convert a frame to rgb and save it to our image
  plm_frame_to_rgb(frame, addr image.data[0])
  # Save the image.
  image.save(&"tmp/f{i}.png")


proc plm_demux_buffer_seek(self: ptr plm_demux_t, pos: csize_t)
proc plm_demux_decode_time(self: ptr plm_demux_t): float64
proc plm_demux_decode_packet(self: ptr plm_demux_t, `type`: cint): ptr plm_packet_t
proc plm_demux_get_packet(self: ptr plm_demux_t): ptr plm_packet_t

const PLM_START_PACK: cint = 0xBA

const PLM_START_SYSTEM: cint = 0xBB

proc plm_demux_create*(buffer: ptr plm_buffer_t, destroyWhenDone: cint): ptr plm_demux_t =
  let self = createShared(plm_demux_t)
  self.buffer = buffer
  self.destroyBufferWhenDone = destroyWhenDone
  self.startTime = PlmPacketInvalidTs
  self.duration = PlmPacketInvalidTs
  self.startCode = -1
  discard plm_demux_has_headers(self)
  return self

proc plm_demux_destroy*(self: ptr plm_demux_t) =
  if self.destroyBufferWhenDone != 0:
    plm_buffer_destroy(self.buffer)
  deallocShared(self)

proc plm_demux_has_headers*(self: ptr plm_demux_t): cint =
  if self.hasHeaders != 0:
    return 1
  # Decode pack header
  if self.hasPackHeader == 0:
    if self.startCode != PLM_START_PACK and plm_buffer_find_start_code(self.buffer,
        PLM_START_PACK) == -1:
      return 0
    self.startCode = PLM_START_PACK
    if plm_buffer_has(self.buffer, 64) == 0:
      return 0
    self.startCode = -1
    if plm_buffer_read(self.buffer, 4) != 0x02:
      return 0
    self.systemClockRef = plm_demux_decode_time(self)
    plm_buffer_skip(self.buffer, 1)
    plm_buffer_skip(self.buffer, 22)
    plm_buffer_skip(self.buffer, 1)
    self.hasPackHeader = 1
  # Decode system header
  if self.hasSystemHeader == 0:
    if self.startCode != PLM_START_SYSTEM and plm_buffer_find_start_code(self.buffer,
        PLM_START_SYSTEM) == -1:
      return 0
    self.startCode = PLM_START_SYSTEM
    if plm_buffer_has(self.buffer, 56) == 0:
      return 0
    self.startCode = -1
    plm_buffer_skip(self.buffer, 16)
    plm_buffer_skip(self.buffer, 24)
    self.numAudioStreams = plm_buffer_read(self.buffer, 6)
    plm_buffer_skip(self.buffer, 5)
    self.numVideoStreams = plm_buffer_read(self.buffer, 5)
    self.hasSystemHeader = 1
  self.hasHeaders = 1
  return 1

proc plm_demux_probe*(self: ptr plm_demux_t, probesize: csize_t): cint =
  let previousPos = plm_buffer_tell(self.buffer)
  var videoStream: cint = 0
  var audioStreams: array[4, cint] = [0, 0, 0, 0]
  while true:
    self.startCode = plm_buffer_next_start_code(self.buffer)
    if self.startCode == PLM_DEMUX_PACKET_VIDEO_1:
      videoStream = 1
    elif self.startCode >= PLM_DEMUX_PACKET_AUDIO_1 and self.startCode <= PLM_DEMUX_PACKET_AUDIO_4:
      audioStreams[self.startCode - PLM_DEMUX_PACKET_AUDIO_1] = 1
    if not (self.startCode != -1 and plm_buffer_tell(self.buffer) - csize_t(previousPos) < probesize):
      break
  self.numVideoStreams = (if videoStream != 0: 1 else: 0)
  self.numAudioStreams = 0
  for i in 0 ..< 4:
    if audioStreams[i] != 0:
      inc self.numAudioStreams
  plm_demux_buffer_seek(self, csize_t(previousPos))
  return (cint(self.numVideoStreams != 0 or self.numAudioStreams != 0))

proc plm_demux_get_num_video_streams*(self: ptr plm_demux_t): cint =
  return (if plm_demux_has_headers(self) != 0: self.numVideoStreams else: 0)

proc plm_demux_get_num_audio_streams*(self: ptr plm_demux_t): cint =
  return (if plm_demux_has_headers(self) != 0: self.numAudioStreams else: 0)

proc plm_demux_rewind*(self: ptr plm_demux_t) =
  plm_buffer_rewind(self.buffer)
  self.currentPacket.length = 0
  self.nextPacket.length = 0
  self.startCode = -1

proc plm_demux_has_ended*(self: ptr plm_demux_t): cint =
  return plm_buffer_has_ended(self.buffer)

proc plm_demux_buffer_seek(self: ptr plm_demux_t, pos: csize_t) =
  plm_buffer_seek(self.buffer, pos)
  self.currentPacket.length = 0
  self.nextPacket.length = 0
  self.startCode = -1

proc plm_demux_get_start_time*(self: ptr plm_demux_t, `type`: cint): float64 =
  if self.startTime != PlmPacketInvalidTs:
    return self.startTime
  let previousPos = plm_buffer_tell(self.buffer)
  let previousStartCode: cint = self.startCode
  # Find first video PTS
  plm_demux_rewind(self)
  while true:
    let packet = plm_demux_decode(self)
    if packet == nil:
      break
    if packet.`type` == `type`:
      self.startTime = packet.pts
    if not (self.startTime == PlmPacketInvalidTs):
      break
  plm_demux_buffer_seek(self, csize_t(previousPos))
  self.startCode = previousStartCode
  return self.startTime

proc plm_demux_get_duration*(self: ptr plm_demux_t, `type`: cint): float64 =
  let fileSize: csize_t = plm_buffer_get_size(self.buffer)
  if self.duration != PlmPacketInvalidTs and self.lastFileSize == fileSize:
    return self.duration
  let previousPos: csize_t = plm_buffer_tell(self.buffer)
  let previousStartCode: cint = self.startCode
  # Find last video PTS. Start searching 64kb from the end and go further
  # back if needed.
  let startRange: int64 = int64(64 * 1024)
  let maxRange: int64 = int64(4096 * 1024)
  var `range`: int64 = startRange
  while `range` <= maxRange:
    var seekPos: int64 = int64(fileSize) - `range`
    if seekPos < 0:
      seekPos = 0
      `range` = maxRange
    plm_demux_buffer_seek(self, csize_t(seekPos))
    self.currentPacket.length = 0
    var lastPts: float64 = PlmPacketInvalidTs
    var packet: ptr plm_packet_t = nil
    while true:
      packet = plm_demux_decode(self)
      if packet == nil:
        break
      if packet.pts != PlmPacketInvalidTs and packet.`type` == `type`:
        lastPts = packet.pts
    if lastPts != PlmPacketInvalidTs:
      self.duration = lastPts - plm_demux_get_start_time(self, `type`)
      break
    `range` *= 2
  plm_demux_buffer_seek(self, previousPos)
  self.startCode = previousStartCode
  self.lastFileSize = fileSize
  return self.duration

proc plm_demux_seek*(self: ptr plm_demux_t, time: float64, `type`: cint,
    forceIntra: cint): ptr plm_packet_t =
  var seekTime = time
  if plm_demux_has_headers(self) == 0:
    return nil
  let duration: float64 = plm_demux_get_duration(self, `type`)
  let fileSize: int64 = int64(plm_buffer_get_size(self.buffer))
  var byterate: int64 = int64(float64(fileSize) / duration)
  var curTime: float64 = self.lastDecodedPts
  var scanSpan: float64 = 1.0
  if seekTime > duration:
    seekTime = duration
  elif seekTime < 0.0:
    seekTime = 0.0
  seekTime += self.startTime
  for retry in 0 ..< 32:
    var foundPacketWithPts: cint = 0
    var foundPacketInRange: cint = 0
    var lastValidPacketStart: int64 = int64(-1)
    var firstPacketTime: float64 = PlmPacketInvalidTs
    let curPos: int64 = int64(plm_buffer_tell(self.buffer))
    # Estimate byte offset and jump to it.
    let offset: int64 = int64((seekTime - curTime - scanSpan) * float64(byterate))
    var seekPos: int64 = curPos + offset
    if seekPos < 0:
      seekPos = 0
    elif seekPos > fileSize - 256:
      seekPos = fileSize - 256
    plm_demux_buffer_seek(self, csize_t(seekPos))
    # Scan through all packets up to the seek_time to find the last packet
    # containing an intra frame.
    while plm_buffer_find_start_code(self.buffer, `type`) != -1:
      let packetStart: int64 = int64(plm_buffer_tell(self.buffer))
      let packet = plm_demux_decode_packet(self, `type`)
      # Skip packet if it has no PTS
      if packet == nil or packet.pts == PlmPacketInvalidTs:
        continue
      # Bail scanning through packets if we hit one that is outside
      # seek_time - scan_span.
      # We also adjust the cur_time and byterate values here so the next
      # iteration can be a bit more precise.
      if packet.pts > seekTime or packet.pts < seekTime - scanSpan:
        foundPacketWithPts = 1
        byterate = int64(float64((seekPos - curPos)) / (packet.pts - curTime))
        curTime = packet.pts
        break
      # If we are still here, it means this packet is in close range to
      # the seek_time. If this is the first packet for this jump position
      # record the PTS. If we later have to back off, when there was no
      # intra frame in this range, we can lower the seek_time to not scan
      # this range again.
      if foundPacketInRange == 0:
        foundPacketInRange = 1
        firstPacketTime = packet.pts
      # Check if this is an intra frame packet. If so, record the buffer
      # position of the start of this packet. We want to jump back to it
      # later, when we know it's the last intra frame before desired
      # seek time.
      if forceIntra != 0:
        for i in 0 ..< int(packet.length) - 5:
          # Find the START_PICTURE code
          if cint(packet.data[i]) == 0x00 and cint(packet.data[i + 1]) == 0x00 and cint(
              packet.data[i + 2]) == 0x01 and cint(packet.data[i + 3]) == 0x00:
            # Bits 11--13 in the picture header contain the frame
            # type, where 1=Intra
            if (cint(packet.data[i + 5]) and 0x38) == 8:
              lastValidPacketStart = packetStart
            break
      else:
        lastValidPacketStart = packetStart
    # If there was at least one intra frame in the range scanned above,
    # our search is over. Jump back to the packet and decode it again.
    if lastValidPacketStart != int64(-1):
      plm_demux_buffer_seek(self, csize_t(lastValidPacketStart))
      return plm_demux_decode_packet(self, `type`)
    elif foundPacketInRange != 0:
      scanSpan *= 2.0
      seekTime = firstPacketTime
    elif foundPacketWithPts == 0:
      byterate = int64(float64((seekPos - curPos)) / (duration - curTime))
      curTime = duration
  return nil

proc plm_demux_decode*(self: ptr plm_demux_t): ptr plm_packet_t =
  if plm_demux_has_headers(self) == 0:
    return nil
  if self.currentPacket.length != 0:
    let bitsTillNextPacket: csize_t = self.currentPacket.length shl 3
    if plm_buffer_has(self.buffer, bitsTillNextPacket) == 0:
      return nil
    plm_buffer_skip(self.buffer, bitsTillNextPacket)
    self.currentPacket.length = 0
  # Pending packet waiting for data?
  if self.nextPacket.length != 0:
    return plm_demux_get_packet(self)
  # Pending packet waiting for header?
  if self.startCode != -1:
    return plm_demux_decode_packet(self, self.startCode)
  while true:
    self.startCode = plm_buffer_next_start_code(self.buffer)
    if self.startCode == PLM_DEMUX_PACKET_VIDEO_1 or self.startCode == PLM_DEMUX_PACKET_PRIVATE or
        self.startCode >= PLM_DEMUX_PACKET_AUDIO_1 and self.startCode <= PLM_DEMUX_PACKET_AUDIO_4:
      return plm_demux_decode_packet(self, self.startCode)
    if not (self.startCode != -1):
      break
  return nil

proc plm_demux_decode_time(self: ptr plm_demux_t): float64 =
  var clock: int64 = int64(plm_buffer_read(self.buffer, 3)) shl 30
  plm_buffer_skip(self.buffer, 1)
  clock = clock or int64(plm_buffer_read(self.buffer, 15) shl 15)
  plm_buffer_skip(self.buffer, 1)
  clock = clock or int64(plm_buffer_read(self.buffer, 15))
  plm_buffer_skip(self.buffer, 1)
  return float64(clock) / 90000.0

proc plm_demux_decode_packet(self: ptr plm_demux_t, `type`: cint): ptr plm_packet_t =
  if plm_buffer_has(self.buffer, csize_t(16 shl 3)) == 0:
    return nil
  self.startCode = -1
  self.nextPacket.`type` = `type`
  self.nextPacket.length = csize_t(plm_buffer_read(self.buffer, 16))
  self.nextPacket.length -= csize_t(plm_buffer_skip_bytes(self.buffer, 0xff))
  # skip P-STD
  if plm_buffer_read(self.buffer, 2) == 0x01:
    plm_buffer_skip(self.buffer, 16)
    self.nextPacket.length -= 2
  let ptsDtsMarker: cint = plm_buffer_read(self.buffer, 2)
  if ptsDtsMarker == 0x03:
    self.nextPacket.pts = plm_demux_decode_time(self)
    self.lastDecodedPts = self.nextPacket.pts
    plm_buffer_skip(self.buffer, 40)
    self.nextPacket.length -= 10
  elif ptsDtsMarker == 0x02:
    self.nextPacket.pts = plm_demux_decode_time(self)
    self.lastDecodedPts = self.nextPacket.pts
    self.nextPacket.length -= 5
  elif ptsDtsMarker == 0x00:
    self.nextPacket.pts = PlmPacketInvalidTs
    plm_buffer_skip(self.buffer, 4)
    self.nextPacket.length -= 1
  else:
    return nil
  return plm_demux_get_packet(self)

proc plm_demux_get_packet(self: ptr plm_demux_t): ptr plm_packet_t =
  if plm_buffer_has(self.buffer, self.nextPacket.length shl 3) == 0:
    return nil
  self.currentPacket.data = self.buffer.bytes + (self.buffer.bitIndex shr 3)
  self.currentPacket.length = self.nextPacket.length
  self.currentPacket.`type` = self.nextPacket.`type`
  self.currentPacket.pts = self.nextPacket.pts
  self.nextPacket.length = 0
  return addr(self.currentPacket)

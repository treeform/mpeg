proc plm_buffer_seek(self: ptr plm_buffer_t, pos: csize_t)
proc plm_buffer_tell(self: ptr plm_buffer_t): csize_t
proc plm_buffer_discard_read_bytes(self: ptr plm_buffer_t)
proc plm_buffer_load_file_callback(self: ptr plm_buffer_t, user: pointer)
proc plm_buffer_seek_file_callback(self: ptr plm_buffer_t, offset: csize_t, user: pointer)
proc plm_buffer_tell_file_callback(self: ptr plm_buffer_t, user: pointer): csize_t
proc plm_buffer_has(self: ptr plm_buffer_t, count: csize_t): cint
proc plm_buffer_read(self: ptr plm_buffer_t, count: cint): cint
proc plm_buffer_align(self: ptr plm_buffer_t)
proc plm_buffer_skip(self: ptr plm_buffer_t, count: csize_t)
proc plm_buffer_skip_bytes(self: ptr plm_buffer_t, v: uint8): cint
proc plm_buffer_next_start_code(self: ptr plm_buffer_t): cint
proc plm_buffer_find_start_code(self: ptr plm_buffer_t, code: cint): cint
proc plm_buffer_has_start_code(self: ptr plm_buffer_t, code: cint): cint
proc plm_buffer_peek_non_zero(self: ptr plm_buffer_t, bitCount: cint): cint

proc plm_buffer_create_with_filename*(filename: cstring): ptr plm_buffer_t =
  var fh: File
  if filename == nil or not open(fh, $filename, fmRead):
    return nil
  return plm_buffer_create_with_file(fh, 1)

proc plm_buffer_create_with_file*(fh: File, closeWhenDone: cint): ptr plm_buffer_t =
  let self = plm_buffer_create_with_capacity(DefaultBufferSize)
  self.fh = fh
  self.closeWhenDone = closeWhenDone
  self.mode = PLM_BUFFER_MODE_FILE
  self.discardReadBytes = 1
  try:
    self.totalSize = csize_t(getFileSize(fh))
    setFilePos(fh, 0)
  except IOError:
    if closeWhenDone != 0: close(fh)
    deallocShared(self.bytes)
    deallocShared(self)
    return nil
  self.loadCallback = plm_buffer_load_file_callback
  self.seekCallback = plm_buffer_seek_file_callback
  self.tellCallback = plm_buffer_tell_file_callback
  return self

proc plm_buffer_create_with_callbacks*(loadCallback: plm_buffer_load_callback,
    seekCallback: plm_buffer_seek_callback, tellCallback: plm_buffer_tell_callback,
    length: csize_t, user: pointer): ptr plm_buffer_t =
  let self = plm_buffer_create_with_capacity(DefaultBufferSize)
  self.mode = PLM_BUFFER_MODE_FILE
  self.totalSize = length
  self.loadCallback = loadCallback
  self.seekCallback = seekCallback
  self.tellCallback = tellCallback
  self.loadCallbackUserData = user
  return self

proc plm_buffer_create_with_memory*(bytes: ptr uint8, length: csize_t,
    freeWhenDone: cint): ptr plm_buffer_t =
  let self = createShared(plm_buffer_t)
  self.capacity = length
  self.length = length
  self.totalSize = length
  self.freeWhenDone = freeWhenDone
  self.bytes = bytes
  self.mode = PLM_BUFFER_MODE_FIXED_MEM
  self.discardReadBytes = 0
  return self

proc plm_buffer_create_with_capacity*(capacity: csize_t): ptr plm_buffer_t =
  let self = createShared(plm_buffer_t)
  self.capacity = capacity
  self.freeWhenDone = 1
  self.bytes = cast[ptr uint8](allocShared0(int(capacity)))
  self.mode = PLM_BUFFER_MODE_RING
  self.discardReadBytes = 1
  return self

proc plm_buffer_create_for_appending*(initialCapacity: csize_t): ptr plm_buffer_t =
  let self = plm_buffer_create_with_capacity(initialCapacity)
  self.mode = PLM_BUFFER_MODE_APPEND
  self.discardReadBytes = 0
  return self

proc plm_buffer_destroy*(self: ptr plm_buffer_t) =
  if self.fh != nil and self.closeWhenDone != 0:
    close(self.fh)
  if self.freeWhenDone != 0:
    if self.mode == PLM_BUFFER_MODE_FIXED_MEM:
      freeExternal(self.bytes)
    else:
      deallocShared(self.bytes)
  deallocShared(self)

proc plm_buffer_get_size*(self: ptr plm_buffer_t): csize_t =
  return (if self.mode == PLM_BUFFER_MODE_FILE: self.totalSize else: self.length)

proc plm_buffer_get_remaining*(self: ptr plm_buffer_t): csize_t =
  return self.length - (self.bitIndex shr 3)

proc plm_buffer_write*(self: ptr plm_buffer_t, bytes: ptr uint8, length: csize_t): csize_t =
  if self.mode == PLM_BUFFER_MODE_FIXED_MEM:
    return 0
  if self.discardReadBytes != 0:
    plm_buffer_discard_read_bytes(self)
    if self.mode == PLM_BUFFER_MODE_RING:
      self.totalSize = 0
  # Do we have to resize to fit the new data?
  if length > csize_t(high(int)) - self.length:
    return 0
  let needed = self.length + length
  if needed > self.capacity:
    let newSize = max(needed, min(self.capacity, csize_t(high(int) div 2)) * 2)
    self.bytes = resizeShared(self.bytes, int(newSize))
    self.capacity = newSize
  if length > 0:
    copyMem(self.bytes + self.length, bytes, int(length))
  self.length += length
  self.hasEnded = 0
  return length

proc plm_buffer_signal_end*(self: ptr plm_buffer_t) =
  self.totalSize = self.length

proc plm_buffer_set_load_callback*(self: ptr plm_buffer_t, fp: plm_buffer_load_callback,
    user: pointer) =
  self.loadCallback = fp
  self.loadCallbackUserData = user

proc plm_buffer_rewind*(self: ptr plm_buffer_t) =
  plm_buffer_seek(self, 0)

proc plm_buffer_seek(self: ptr plm_buffer_t, pos: csize_t) =
  self.hasEnded = 0
  if self.seekCallback != nil:
    self.seekCallback(self, pos, self.loadCallbackUserData)
    self.bitIndex = 0
    self.length = 0
  elif self.mode == PLM_BUFFER_MODE_RING:
    if pos != 0:
      # Seeking to non-0 is forbidden for dynamic-mem buffers
      return
    self.bitIndex = 0
    self.length = 0
    self.totalSize = 0
  elif pos < self.length:
    self.bitIndex = pos shl 3

proc plm_buffer_tell(self: ptr plm_buffer_t): csize_t =
  return (if self.tellCallback != nil: self.tellCallback(self, self.loadCallbackUserData) + (
      self.bitIndex shr 3) - self.length else: self.bitIndex shr 3)

proc plm_buffer_discard_read_bytes(self: ptr plm_buffer_t) =
  let bytePos: csize_t = self.bitIndex shr 3
  if bytePos == self.length:
    self.bitIndex = 0
    self.length = 0
  elif bytePos > 0:
    moveMem(self.bytes, self.bytes + bytePos, int(self.length - bytePos))
    self.bitIndex -= bytePos shl 3
    self.length -= bytePos

proc plm_buffer_load_file_callback(self: ptr plm_buffer_t, user: pointer) =
  if self.discardReadBytes != 0:
    plm_buffer_discard_read_bytes(self)
  let bytesAvailable: csize_t = self.capacity - self.length
  var bytesRead: csize_t
  try:
    bytesRead = csize_t(readBuffer(self.fh, self.bytes + self.length, int(bytesAvailable)))
  except IOError:
    self.hasEnded = 1
    return
  self.length += bytesRead
  if bytesRead == 0:
    self.hasEnded = 1

proc plm_buffer_seek_file_callback(self: ptr plm_buffer_t, offset: csize_t, user: pointer) =
  try:
    setFilePos(self.fh, int64(offset))
  except IOError:
    self.hasEnded = 1

proc plm_buffer_tell_file_callback(self: ptr plm_buffer_t, user: pointer): csize_t =
  try:
    return csize_t(getFilePos(self.fh))
  except IOError:
    return 0

proc plm_buffer_has_ended*(self: ptr plm_buffer_t): cint =
  return self.hasEnded

proc plm_buffer_has(self: ptr plm_buffer_t, count: csize_t): cint =
  if ((self.length shl 3) - self.bitIndex) >= count:
    return 1
  if self.loadCallback != nil:
    self.loadCallback(self, self.loadCallbackUserData)
    if ((self.length shl 3) - self.bitIndex) >= count:
      return 1
  if self.totalSize != 0 and self.length == self.totalSize:
    self.hasEnded = 1
  return 0

proc plm_buffer_read(self: ptr plm_buffer_t, count: cint): cint =
  var count = count
  if plm_buffer_has(self, csize_t(count)) == 0:
    return 0
  var value: cint = 0
  while count != 0:
    let currentByte: cint = cint(self.bytes[self.bitIndex shr 3])
    let remaining: cint = cint(8 - (self.bitIndex and 7))
    let read: cint = (if remaining < count: remaining else: count)
    let shift: cint = remaining - read
    let mask: cint = (0xff'i32 shr (8 - read))
    value = (value shl read) or ((currentByte and (mask shl shift)) shr shift)
    self.bitIndex += csize_t(read)
    count -= read
  return value

proc plm_buffer_align(self: ptr plm_buffer_t) =
  self.bitIndex = ((self.bitIndex + 7) shr 3) shl 3

proc plm_buffer_skip(self: ptr plm_buffer_t, count: csize_t) =
  if plm_buffer_has(self, count) != 0:
    self.bitIndex += count

proc plm_buffer_skip_bytes(self: ptr plm_buffer_t, v: uint8): cint =
  plm_buffer_align(self)
  var skipped: cint = 0
  while plm_buffer_has(self, 8) != 0 and cint(self.bytes[self.bitIndex shr 3]) == cint(v):
    self.bitIndex += 8
    inc skipped
  return skipped

proc plm_buffer_next_start_code(self: ptr plm_buffer_t): cint =
  plm_buffer_align(self)
  while plm_buffer_has(self, csize_t((5 shl 3))) != 0:
    let byteIndex: csize_t = self.bitIndex shr 3
    if cint(self.bytes[byteIndex]) == 0x00 and cint(self.bytes[byteIndex + 1]) == 0x00 and cint(
        self.bytes[byteIndex + 2]) == 0x01:
      self.bitIndex = (byteIndex + 4) shl 3
      return cint(self.bytes[byteIndex + 3])
    self.bitIndex += 8
  return -1

proc plm_buffer_find_start_code(self: ptr plm_buffer_t, code: cint): cint =
  var current: cint = 0
  while true:
    current = plm_buffer_next_start_code(self)
    if current == code or current == -1:
      return current
  return -1

proc plm_buffer_has_start_code(self: ptr plm_buffer_t, code: cint): cint =
  let previousBitIndex: csize_t = self.bitIndex
  let previousDiscardReadBytes: cint = self.discardReadBytes
  self.discardReadBytes = 0
  let current: cint = plm_buffer_find_start_code(self, code)
  self.bitIndex = previousBitIndex
  self.discardReadBytes = previousDiscardReadBytes
  return current

proc plm_buffer_peek_non_zero(self: ptr plm_buffer_t, bitCount: cint): cint =
  if plm_buffer_has(self, csize_t(bitCount)) == 0:
    return 0
  let val: cint = plm_buffer_read(self, bitCount)
  self.bitIndex -= csize_t(bitCount)
  return cint(val != 0)

proc readVlc(buffer: ptr plm_buffer_t, table: openArray[VlcNode]): cint =
  var index = 0'i32
  while true:
    let node = table[index + plm_buffer_read(buffer, 1)]
    if node.index <= 0:
      return node.value
    index = node.index

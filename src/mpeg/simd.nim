## Keep feature detection in a baseline module. The probe includes OS support
## for saving the AVX registers, and runs once at module initialization.
const buildAvx2* = defined(amd64) and not defined(mpegNoSimd) and
  (defined(gcc) or defined(clang) or defined(vcc)) and not defined(js)

when buildAvx2:
  when defined(vcc):
    var avx2Available {.importc: "PF_AVX2_INSTRUCTIONS_AVAILABLE", header: "<windows.h>".}: uint32
    proc processorFeature(feature: uint32): int32
      {.stdcall, importc: "IsProcessorFeaturePresent", header: "<windows.h>".}
    let useAvx2* = processorFeature(avx2Available) != 0
  else:
    proc cpuSupports(feature: cstring): cint {.importc: "__builtin_cpu_supports", nodecl.}
    let useAvx2* = cpuSupports("avx2") != 0

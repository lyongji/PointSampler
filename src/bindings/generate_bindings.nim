## Futhark binding generator for PointSampler C API.
##
## Run: nim c -r src/bindings/generate_bindings.nim
## This outputs src/bindings/ps_c_api_gen.nim

import futhark, os, std/strutils

# ponytail: query clang resource dir instead of pinning version number
const clangResDir = staticExec("clang -print-resource-dir 2>/dev/null").strip
const clangIncDir = if clangResDir.len > 0: clangResDir & "/include" else: "/usr/lib/clang/20/include"

importc:
  path currentSourcePath.parentDir / ".." / ".." / "c_api"
  sysPath "/usr/include"
  sysPath clangIncDir
  outputPath currentSourcePath.parentDir / "ps_c_api_gen.nim"
  "ps_c_api.h"

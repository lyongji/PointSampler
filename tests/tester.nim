## Test runner — auto-discovers `t*.nim` in the tests directory.

import std/[os, strformat]

proc fatal(msg: string) =
  quit &"FAILURE {msg}"

proc exec(cmd: string) =
  echo &"Running: {cmd}"
  if execShellCmd(cmd) != 0: fatal cmd

let testDir = currentSourcePath.parentDir()
for f in walkFiles(testDir / "t*.nim"):
  let name = f.extractFilename
  if name == "tester.nim": continue
  exec &"nim c -r {quoteShell(f)}"

echo "All test files completed."

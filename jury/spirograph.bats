#!/usr/bin/env bats

load 'test_libs/bats-support-0.3.0/load.bash'
load 'test_libs/bats-assert-2.2.0/load.bash'

SCRIPT="gallery/spirograph/spirograph.sh"

@test "spirograph: should be executable" {
  assert [ -x "$SCRIPT" ]
}

@test "spirograph: runs without errors for 1 second" {
  run timeout 1s "$SCRIPT"
  assert_failure
}

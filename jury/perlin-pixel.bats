#!/usr/bin/env bats

load 'jury/test_libs/bats-support-0.3.0/load.bash'
load 'jury/test_libs/bats-assert-2.2.0/load.bash'

SCRIPT="gallery/perlin-pixel/perlin-pixel.sh"

@test "perlin-pixel: should be executable" {
  assert [ -x "$SCRIPT" ]
}

@test "perlin-pixel: runs without errors for 1 second" {
  run timeout 1s "$SCRIPT"
  assert_success
}

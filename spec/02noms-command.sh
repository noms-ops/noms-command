#!/usr/bin/env bats

@test "command usage" {
    noms2 | grep Usage:
}

@test "command error" {
    run noms2 foo
    [ $status -ne 0 ]
    echo "$output" | grep -q "noms error: noms command \"foo\" not found: not a URL or bookmark"
}

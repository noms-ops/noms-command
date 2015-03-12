#!/usr/bin/env bats

@test "command usage" {
    noms2 | grep Usage:
}

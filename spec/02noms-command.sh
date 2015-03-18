#!/usr/bin/env bats

@test "command usage" {
    noms2 | grep Usage:
}

@test "command error" {
    run noms2 foo
    [ $status -ne 0 ]
    echo "$output" | grep -q "noms error: noms command \"foo\" not found: not a URL or bookmark"
}

@test "command js error" {
    run noms2 'data:application/json,{"$doctype":"noms-v2","$script":["window.alert(\"test error string\")"],"$body":[]}'
    echo "$output" | grep -q "test error string"
}

@test "scriptable auth" {
    rake start
    chmod 0600 test/identity
    noms2 -i test/identity http://localhost:8787/auth/dnc.json | grep -q Usage:
    ec=$?
    rake stop
    [ $ec -eq 0 ]
}

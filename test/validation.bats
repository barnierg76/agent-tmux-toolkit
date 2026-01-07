#!/usr/bin/env bats
# Tests for validation functions in agent-common.sh

setup() {
    source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# validate_name tests
# ═══════════════════════════════════════════════════════════════════════════════

@test "validate_name accepts alphanumeric" {
    run validate_name "test123"
    [ "$status" -eq 0 ]
}

@test "validate_name accepts dashes" {
    run validate_name "my-session"
    [ "$status" -eq 0 ]
}

@test "validate_name accepts underscores" {
    run validate_name "my_session"
    [ "$status" -eq 0 ]
}

@test "validate_name accepts mixed valid characters" {
    run validate_name "my-session_123"
    [ "$status" -eq 0 ]
}

@test "validate_name rejects semicolons" {
    run validate_name "test;injection"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects pipes" {
    run validate_name "test|cmd"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects spaces" {
    run validate_name "test space"
    [ "$status" -eq 1 ]
}

@test "validate_name rejects empty string" {
    run validate_name ""
    [ "$status" -eq 1 ]
}

@test "validate_name rejects backticks" {
    run validate_name 'test`whoami`'
    [ "$status" -eq 1 ]
}

@test "validate_name rejects dollar signs" {
    run validate_name 'test$HOME'
    [ "$status" -eq 1 ]
}

@test "validate_name rejects newlines" {
    run validate_name $'test\ninjection'
    [ "$status" -eq 1 ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# die() tests
# ═══════════════════════════════════════════════════════════════════════════════

@test "die exits with code 1 by default" {
    run bash -c 'source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"; die "test error"'
    [ "$status" -eq 1 ]
}

@test "die exits with custom code" {
    run bash -c 'source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"; die "test error" 42'
    [ "$status" -eq 42 ]
}

@test "die outputs error message to stderr" {
    run bash -c 'source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"; die "custom message" 2>&1'
    [[ "$output" == *"custom message"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# warn() tests
# ═══════════════════════════════════════════════════════════════════════════════

@test "warn does not exit" {
    run bash -c 'source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"; warn "warning"; echo "still running"'
    [ "$status" -eq 0 ]
    [[ "$output" == *"still running"* ]]
}

@test "warn outputs warning message" {
    run bash -c 'source "${BATS_TEST_DIRNAME}/../bin/agent-common.sh"; warn "test warning" 2>&1'
    [[ "$output" == *"test warning"* ]]
}

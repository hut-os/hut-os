#!/bin/bash
# Test script for HUTOS system tools
# This script will be run inside QEMU to test all tools

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS System Tools Test Suite                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local name="$1"
    local command="$2"
    
    echo "Testing: $name"
    echo "Command: $command"
    echo "----------------------------------------"
    
    if eval "$command"; then
        echo ""
        echo "✓ Test passed: $name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo ""
        echo "✗ Test failed: $name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

# Test 1: hutctl
run_test "hutctl --help" "hutctl --help"
run_test "hutctl status" "hutctl status"
run_test "hutctl version" "hutctl version"

# Test 2: hutinfo
run_test "hutinfo" "hutinfo"
run_test "hutinfo --version" "hutinfo --version"

# Test 3: hutsched
run_test "hutsched --help" "hutsched --help"
run_test "hutsched status" "hutsched status"
run_test "hutsched version" "hutsched version"

# Test 4: hutbench
run_test "hutbench --help" "hutbench --help"
run_test "hutbench cpu (quick)" "hutbench cpu 100"
run_test "hutbench version" "hutbench version"

# Test 5: hutdiag
run_test "hutdiag --help" "hutdiag --help"
run_test "hutdiag" "hutdiag"
run_test "hutdiag --version" "hutdiag --version"

# Test 6: Additional hutctl commands
run_test "hutctl scheduler" "hutctl scheduler"
run_test "hutctl memory" "hutctl memory"
run_test "hutctl cpu" "hutctl cpu"

# Summary
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Test Summary                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi

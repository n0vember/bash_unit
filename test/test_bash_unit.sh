#!/bin/bash

test_fail_fails() {
  (fail >/dev/null) && \
  (
    echo "FAILURE: fail must fail !!!"
    exit 1
  ) || \
  echo "OK" > /dev/null
}

#fail can now be used in the following tests

test_assert_fail_succeeds() {
  (assert_fail false) || fail 'assert_fail should succeed' 
}

test_assert_fail_fails() {
  (assert_fail true >/dev/null) && fail 'assert_fail should fail' || true
}

#assert_fail can now be used in the following tests

test_assert_succeeds() {
  assert true || fail 'assert should succeed'
}

test_assert_fails() {
  assert_fail "assert false" "assert should fail"
}

#assert can now be used in the following tests

test_assert_equals_fails_when_not_equal() {
  assert_fail \
    "assert_equals toto tutu" \
    "assert_equals should fail"
}

test_assert_equals_succeed_when_equal() {
  assert \
    "assert_equals 'toto tata' 'toto tata'"\
    'assert_equals should succeed'
}

#assert_equals can now be used in the following tests

test_fail_prints_failure_message() {
  assert_equals 'failure message' \
    "$(fail 'failure message' | line 2)" \
    "unexpected error message"
}

test_fail_prints_where_is_error() {
  assert_equals "${BASH_SOURCE}:${FUNCNAME}():${LINENO}" \
	"$(fail | line 2)"
}

test_assert_status_code_succeeds() {
  assert "assert_status_code 3 'exit 3'" \
    "assert_status_code should succeed"
}

test_assert_status_code_fails() {
  assert_fail "assert_status_code 3 true" \
    "assert_status_code should fail"
}

test_assert_show_stderr_when_failure() {
  message="$(assert 'echo some error message >&2; exit 2' | sed '2 !d')"
  assert_equals \
    "some error message" \
    "$message"
}

test_fake_actually_fakes_the_command() {
  fake ps echo expected
  assert_equals "expected" $(ps)
}

test_fake_can_fake_inline() {
  assert_equals \
    "expected" \
    $(fake ps echo expected ; ps)
}

test_fake_exports_faked_in_subshells() {
  fake ps echo expected
  assert_equals \
    expected \
    $( bash -c ps )
}

test_fake_transmits_params_to_fake_code() {
  function _ps() {
    assert_equals "aux" "$FAKE_PARAMS"
  }
  export -f _ps
  fake ps _ps

  ps aux
}

test_fake_echo_stdin_when_no_params() {
  fake ps << EOF
  PID TTY          TIME CMD
 7801 pts/9    00:00:00 bash
 7818 pts/9    00:00:00 ps
EOF

  assert_equals 2 $(ps | grep pts | wc -l)
}

test_run_all_tests_even_in_case_of_failure() {
  bash_unit_output=$($0 <(cat << EOF
function test_succeed() { assert true ; }
function test_fails()   { assert false ; }
EOF
) | sed -e 's:/dev/fd/[0-9]*:test_file:')

  assert_equals "\
Running tests in test_file
Running test_fails... FAILURE
test_file:test_fails():2
Running test_succeed... SUCCESS" "$bash_unit_output" 
}

test_exit_code_not_0_in_case_of_failure() {
  assert_fail "$0 <(cat << EOF
function test_succeed() { assert true ; }
function test_fails()   { assert false ; }
EOF
)"
}

line() {
  line_nb=$1
  tail -n +$line_nb | head -1
}

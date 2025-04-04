#!/usr/bin/env bats
#
# Unit tests for init.sh.
#
# shellcheck disable=SC2034

load _helper
load "../../../init.sh"

@test "Test all conversions" {
  input="I am a_string-With spaces 13"

  TEST_CASES=(
    "$input" "file_name" "i_am_a_string-with_spaces_13"
    "$input" "route_path" "i_am_a_string-with_spaces_13"
    "$input" "deployment_id" "i_am_a_string-with_spaces_13"
    "$input" "domain_name" "i_am_a_stringwith_spaces_13"
    "$input" "namespace" "IAmA_stringWithSpaces13"
    "$input" "package_name" "i-am-a_string-with-spaces-13"
    "$input" "function_name" "i_am_a_string-with_spaces_13"
    "$input" "ui_id" "i_am_a_string-with_spaces_13"
    "$input" "cli_command" "i_am_a_string-with_spaces_13"
    "$input" "log_entry" "I am a_string-With spaces 13"
    "$input" "code_comment_title" "I am a_string-With spaces 13"
    "$input" "dummy_type" "Invalid conversion type"
    "HelloWorld" "namespace" "HelloWorld"
    "Hello World" "namespace" "HelloWorld"
    "Hello world" "namespace" "HelloWorld"
    "Hello-world" "namespace" "Helloworld"
  )

  dataprovider_run "convert_string" 3
}

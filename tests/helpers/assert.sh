#!/usr/bin/env bash

fail() {
  printf "not ok - %s\n" "$1" >&2
  exit 1
}

pass() {
  printf "ok - %s\n" "$1"
}

assert_file_exists() {
  local path="$1"
  local message="$2"

  [ -e "$path" ] || fail "$message"
  pass "$message"
}

assert_file_missing() {
  local path="$1"
  local message="$2"

  [ ! -e "$path" ] || fail "$message"
  pass "$message"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  case "$haystack" in
    *"$needle"*) pass "$message" ;;
    *) fail "$message" ;;
  esac
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  case "$haystack" in
    *"$needle"*) fail "$message" ;;
    *) pass "$message" ;;
  esac
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  local message="$3"
  local actual=""

  [ -L "$path" ] || fail "$message"
  actual="$(readlink "$path")"
  [ "$actual" = "$expected" ] || fail "$message"
  pass "$message"
}

assert_command_output_contains() {
  local cmd="$1"
  local needle="$2"
  local message="$3"
  local output=""

  output="$(eval "$cmd")" || fail "$message"
  assert_contains "$output" "$needle" "$message"
}


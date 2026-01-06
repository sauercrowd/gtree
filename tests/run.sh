#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GTREE_BIN="$(cd "$SCRIPT_DIR/.." && pwd)/gtree"

declare -a temps=()
make_temp_dir() {
  local dir
  dir="$(mktemp -d)"
  temps+=("$dir")
  echo "$dir"
}

cleanup() {
  local dir
  if [[ ${#temps[@]} -eq 0 ]]; then
    return 0
  fi
  for dir in "${temps[@]}"; do
    rm -rf "$dir"
  done
}
trap cleanup EXIT

fail=0
tests=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    echo "assert_eq failed: expected '$expected' got '$actual' ${msg}"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-}"
  if ! grep -F -q -- "$needle" <<<"$haystack"; then
    echo "assert_contains failed: missing '$needle' ${msg}"
    return 1
  fi
}

assert_file_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "assert_file_exists failed: $path"
    return 1
  fi
}

assert_file_missing() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "assert_file_missing failed: $path"
    return 1
  fi
}

run_test() {
  local name="$1"
  shift
  tests=$((tests + 1))
  if "$@"; then
    echo "ok - $name"
  else
    echo "not ok - $name"
    fail=1
  fi
}

create_repo() {
  local repo
  repo="$(make_temp_dir)"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  echo "base" > "$repo/README"
  git -C "$repo" add README
  git -C "$repo" commit -m "init" -q
  (cd "$repo" && pwd -P)
}

test_add_rm() {
  local repo gtree_dir repo_name
  repo="$(create_repo)"
  repo_name="$(basename "$repo")"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add feature)
  assert_file_exists "$gtree_dir/$repo_name/feature" || return 1
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" rm feature)
  assert_file_missing "$gtree_dir/$repo_name/feature" || return 1
}

test_ls_outputs_branches() {
  local repo gtree_dir out
  repo="$(create_repo)"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add feature)
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add bugfix)
  out="$(cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" ls)"
  assert_contains "$out" "feature" || return 1
  assert_contains "$out" "bugfix" || return 1
}

test_cd_paths() {
  local repo gtree_dir out_main out_branch repo_name
  repo="$(create_repo)"
  repo_name="$(basename "$repo")"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add feature)
  out_main="$(cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" cd)"
  out_branch="$(cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" cd feature)"
  assert_eq "$repo" "$(cd "$out_main" && pwd -P)" || return 1
  assert_eq "$gtree_dir/$repo_name/feature" "$(cd "$out_branch" && pwd -P)" || return 1
}

test_packup_success() {
  local repo gtree_dir out branch repo_name
  repo="$(create_repo)"
  repo_name="$(basename "$repo")"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add feature)
  out="$(cd "$gtree_dir/$repo_name/feature" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" packup -c)"
  assert_eq "$repo" "$(cd "$out" && pwd -P)" || return 1
  assert_file_missing "$gtree_dir/$repo_name/feature" || return 1
  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD)"
  assert_eq "feature" "$branch" || return 1
}

test_packup_dirty_main() {
  local repo gtree_dir out status repo_name main_branch_before main_branch_after
  repo="$(create_repo)"
  repo_name="$(basename "$repo")"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  (cd "$repo" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" add feature)
  echo "change" >> "$repo/README"
  main_branch_before="$(git -C "$repo" symbolic-ref --quiet --short HEAD)"
  out="$(cd "$gtree_dir/$repo_name/feature" && GTREE_DIR="$gtree_dir" "$GTREE_BIN" packup)"
  status=$?
  if [[ $status -ne 0 ]]; then
    echo "expected zero exit"
    return 1
  fi
  assert_eq "$repo" "$(cd "$out" && pwd -P)" || return 1
  assert_file_missing "$gtree_dir/$repo_name/feature" || return 1
  main_branch_after="$(git -C "$repo" symbolic-ref --quiet --short HEAD)"
  assert_eq "$main_branch_before" "$main_branch_after" || return 1
}

test_init_output() {
  local out
  out="$("$GTREE_BIN" init)"
  assert_contains "$out" "gtree() {" || return 1
  assert_contains "$out" "_gtree_complete()" || return 1
}

test_init_add_cd() {
  local repo gtree_dir out repo_name
  repo="$(create_repo)"
  repo_name="$(basename "$repo")"
  gtree_dir="$(cd "$(make_temp_dir)" && pwd -P)"
  out="$(
    PATH="$(dirname "$GTREE_BIN"):$PATH"
    export PATH
    eval "$("$GTREE_BIN" init)"
    cd "$repo"
    GTREE_DIR="$gtree_dir" gtree add feature >/dev/null 2>&1
    pwd -P
  )"
  assert_eq "$gtree_dir/$repo_name/feature" "$out" || return 1
}

run_test "add/rm" test_add_rm
run_test "ls outputs branches" test_ls_outputs_branches
run_test "cd paths" test_cd_paths
run_test "packup success" test_packup_success
run_test "packup dirty main" test_packup_dirty_main
run_test "init output" test_init_output
run_test "init add cd" test_init_add_cd

if [[ $fail -ne 0 ]]; then
  echo "FAIL ($tests tests)"
  exit 1
fi

echo "PASS ($tests tests)"

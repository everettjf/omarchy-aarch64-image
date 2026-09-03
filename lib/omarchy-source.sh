#!/bin/bash

# Resolve the separately maintained Omarchy AArch64 source tree. Callers must
# provide PROJECT_ROOT, BUILD_ROOT (or BUILD_DIR), OMARCHY_AARCH64_URL,
# OMARCHY_AARCH64_REF, OMARCHY_AARCH64_VERSION,
# OMARCHY_AARCH64_PACKAGE_VERSION, and a fail() function.

OMARCHY_SOURCE_OVERRIDE="${OMARCHY_SOURCE_OVERRIDE:-}"
OMARCHY_SOURCE_DIR=""
OMARCHY_SOURCE_COMMIT=""
OMARCHY_SOURCE_DIRTY=""
OMARCHY_SOURCE_KIND=""

omarchy_source_git_at() {
  local source=$1
  shift
  git -c safe.directory="$source" -C "$source" "$@"
}

omarchy_source_git() {
  omarchy_source_git_at "$OMARCHY_SOURCE_DIR" "$@"
}

validate_omarchy_source() {
  local source=$1 top

  [[ -d $source/.git ]] || fail "Omarchy source is not a Git checkout: $source"
  top=$(omarchy_source_git_at "$source" rev-parse --show-toplevel) ||
    fail "cannot inspect Omarchy source checkout: $source"
  top=$(realpath -e -- "$top")
  [[ $top == "$source" ]] || fail "Omarchy source must be its repository root: $source"
  [[ -f $source/install/omarchy-base.packages ]] ||
    fail "Omarchy source lacks install/omarchy-base.packages: $source"
  [[ -f $source/default/pacman/pacman-aarch64.conf ]] ||
    fail "Omarchy source lacks its AArch64 pacman configuration: $source"
}

resolve_omarchy_source() {
  local source actual remote build_root

  [[ $OMARCHY_AARCH64_REF =~ ^[0-9a-f]{40}$ ]] ||
    fail "OMARCHY_AARCH64_REF must be a full immutable commit"
  [[ $OMARCHY_AARCH64_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+([.][0-9]+)?$ ]] ||
    fail "invalid OMARCHY_AARCH64_VERSION: $OMARCHY_AARCH64_VERSION"
  [[ $OMARCHY_AARCH64_PACKAGE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+-[1-9][0-9]*$ ]] ||
    fail "invalid OMARCHY_AARCH64_PACKAGE_VERSION: $OMARCHY_AARCH64_PACKAGE_VERSION"

  if [[ -n $OMARCHY_SOURCE_OVERRIDE ]]; then
    source=$(realpath -e -- "$OMARCHY_SOURCE_OVERRIDE") ||
      fail "Omarchy source override not found: $OMARCHY_SOURCE_OVERRIDE"
    OMARCHY_SOURCE_KIND=local
  else
    build_root=${BUILD_ROOT:-${BUILD_DIR:-}}
    [[ -n $build_root ]] || fail "source resolver needs BUILD_ROOT or BUILD_DIR"
    source="$build_root/cache/sources/omarchy-aarch64-${OMARCHY_AARCH64_REF:0:12}"
    mkdir -p "${source%/*}"
    if [[ ! -d $source/.git ]]; then
      log "Cloning pinned Omarchy AArch64 source"
      git clone --no-checkout "$OMARCHY_AARCH64_URL" "$source"
      omarchy_source_git_at "$source" checkout --detach "$OMARCHY_AARCH64_REF"
    fi
    source=$(realpath -e -- "$source")
    remote=$(omarchy_source_git_at "$source" remote get-url origin) ||
      fail "cached Omarchy source has no origin: $source"
    [[ $remote == "$OMARCHY_AARCH64_URL" ]] ||
      fail "cached Omarchy source origin is $remote, expected $OMARCHY_AARCH64_URL"
    OMARCHY_SOURCE_KIND=pinned
  fi

  validate_omarchy_source "$source"
  OMARCHY_SOURCE_DIR=$source
  actual=$(omarchy_source_git rev-parse HEAD)
  OMARCHY_SOURCE_COMMIT=$actual
  if [[ -n $(omarchy_source_git status --porcelain) ]]; then
    OMARCHY_SOURCE_DIRTY=yes
  else
    OMARCHY_SOURCE_DIRTY=no
  fi

  if [[ $OMARCHY_SOURCE_KIND == pinned ]]; then
    [[ $actual == "$OMARCHY_AARCH64_REF" ]] ||
      fail "cached Omarchy source is at $actual, expected $OMARCHY_AARCH64_REF"
    [[ $OMARCHY_SOURCE_DIRTY == no ]] ||
      fail "cached Omarchy source has local changes: $OMARCHY_SOURCE_DIR"
  else
    [[ $actual == "$OMARCHY_AARCH64_REF" ]] ||
      warn "local Omarchy source is at $actual instead of pinned $OMARCHY_AARCH64_REF"
  fi
}

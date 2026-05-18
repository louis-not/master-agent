#!/usr/bin/env bash
# Master Agent — dependency check / install helper
#
# Verifies the host has the tools the orchestrator needs:
#   - git    (Master + subagents commit through it)
#   - tmux   (subagents run in persistent panes)
#   - claude (the CLI the Master spawns inside each tmux session)
#
# Usage:
#   ./install.sh            # check only
#   ./install.sh --install  # attempt to install missing deps via brew/apt

set -euo pipefail

DO_INSTALL=0
if [ "${1:-}" = "--install" ]; then
  DO_INSTALL=1
fi

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }

detect_pkg_mgr() {
  if command -v brew >/dev/null 2>&1; then echo brew
  elif command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  else echo ""
  fi
}

install_pkg() {
  local pkg=$1
  local mgr
  mgr=$(detect_pkg_mgr)
  case "$mgr" in
    brew)   brew install "$pkg" ;;
    apt)    sudo apt-get update && sudo apt-get install -y "$pkg" ;;
    dnf)    sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -S --noconfirm "$pkg" ;;
    *)      red "No supported package manager found. Install '$pkg' manually."; return 1 ;;
  esac
}

version_of() {
  case "$1" in
    tmux) tmux -V 2>&1 | head -n1 ;;
    *)    "$1" --version 2>&1 | head -n1 ;;
  esac
}

check_or_install() {
  local cmd=$1
  local pkg=${2:-$1}
  if command -v "$cmd" >/dev/null 2>&1; then
    green "[ok]    $cmd  ($(version_of "$cmd"))"
    return 0
  fi
  red "[miss]  $cmd"
  if [ "$DO_INSTALL" -eq 1 ]; then
    yellow "        installing '$pkg'..."
    install_pkg "$pkg"
  else
    return 1
  fi
}

echo "Master Agent — dependency check"
echo "--------------------------------"

MISSING=0
check_or_install git  || MISSING=1
check_or_install tmux || MISSING=1

# claude CLI is not in standard package managers; only check + point at install docs.
if command -v claude >/dev/null 2>&1; then
  green "[ok]    claude ($(claude --version 2>&1 | head -n1))"
else
  red "[miss]  claude"
  yellow "        install via: npm i -g @anthropic-ai/claude-code   (see https://docs.claude.com/claude-code)"
  MISSING=1
fi

echo
if [ "$MISSING" -eq 0 ]; then
  green "All dependencies present. The Master orchestrator is ready to run."
  echo
  echo "Next: open Claude Code at your project root and ask it to read agent.md."
else
  if [ "$DO_INSTALL" -eq 1 ]; then
    yellow "Re-run './install.sh' to verify."
  else
    yellow "Re-run with './install.sh --install' to attempt automatic install of git/tmux."
  fi
  exit 1
fi

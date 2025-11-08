#!/usr/bin/env bash
# Helper to clean, build, and flash the Zephyr sample via west.

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: ./run [-a] [-c] [-b] [-f] [-d] [-e]

Default (no flags): build + flash (-bf).
Flags can be combined (e.g., -bc, -cbf, -bd).
  -a   All steps: clean, build, flash, debug (-cbfd).
  -c   Run "west build -t pristine" on the build directory.
  -b   Build the app for nucleo_l476rg into ./build.
  -f   Flash the previously built image.
  -d   Prepare VS Code debugging environment (write .vscode/zephyr-env).
  -e   Launch an interactive shell with Zephyr environment variables.
  -h   Show this help.
EOF
	exit "${1:-0}"
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$ROOT_DIR/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
BUILD_DIR="${ROOT_DIR}/build"
BOARD="nucleo_l476rg"
DEFAULT_SDK="$HOME/zephyr-sdk-0.17.4"
ZEPHYR_ENV_SCRIPT="${WORKSPACE_DIR}/zephyr/zephyr-env.sh"
ENV_EXPORT_FILE="${WORKSPACE_DIR}/.vscode/zephyr-env"

prepare_debug_env() {
	if [ -z "${ZEPHYR_BASE:-}" ]; then
		echo "Error: ZEPHYR_BASE is not set; cannot write debug environment." >&2
		exit 1
	fi
	if [ -z "${ZEPHYR_SDK_INSTALL_DIR:-}" ]; then
		echo "Error: ZEPHYR_SDK_INSTALL_DIR is not set; cannot write debug environment." >&2
		exit 1
	fi

	mkdir -p "$(dirname "$ENV_EXPORT_FILE")"
	cat >"$ENV_EXPORT_FILE" <<EOF
ZEPHYR_BASE=${ZEPHYR_BASE}
ZEPHYR_SDK_INSTALL_DIR=${ZEPHYR_SDK_INSTALL_DIR}
EOF
	echo "Wrote VS Code debug environment to ${ENV_EXPORT_FILE}."
	echo "Use VS Code Run and Debug (F5) to start an OpenOCD/GDB session."
}

if [ -z "${ZEPHYR_SDK_INSTALL_DIR:-}" ] && [ -d "$DEFAULT_SDK" ]; then
	export ZEPHYR_SDK_INSTALL_DIR="$DEFAULT_SDK"
fi

if [ -f "$ZEPHYR_ENV_SCRIPT" ]; then
	# shellcheck disable=SC1090
	source "$ZEPHYR_ENV_SCRIPT"
else
	echo "Warning: Zephyr env script not found at $ZEPHYR_ENV_SCRIPT" >&2
fi

: "${ZEPHYR_BASE:=${WORKSPACE_DIR}/zephyr}"
export ZEPHYR_BASE

do_clean=false
do_build=false
do_flash=false
do_debug_prepare=false
do_env_shell=false

if [ "$#" -eq 0 ]; then
	do_build=true
	do_flash=true
else
	while getopts ":aebcfdh" opt; do
		case "$opt" in
			a)
				do_clean=true
				do_build=true
				do_flash=true
				do_debug_prepare=true
				;;
			e) do_env_shell=true ;;
			c) do_clean=true ;;
			b) do_build=true ;;
			f) do_flash=true ;;
			d) do_debug_prepare=true ;;
			h) usage 0 ;;
			\?) echo "Unknown option: -$OPTARG" >&2; usage 1 ;;
		esac
	done
fi

if ! $do_clean && ! $do_build && ! $do_flash && ! $do_debug_prepare && ! $do_env_shell; then
	echo "Nothing to do; specify at least one of -c, -b, -f, -d, or -e." >&2
	usage 1
fi

if $do_env_shell && { $do_clean || $do_build || $do_flash || $do_debug_prepare; }; then
	echo "Flag -e cannot be combined with other actions." >&2
	exit 1
fi

if $do_env_shell; then
	echo "Zephyr environment loaded (ZEPHYR_BASE=${ZEPHYR_BASE})."
	cd "$WORKSPACE_DIR"
	exec "${SHELL:-/bin/bash}" -i
fi

if $do_clean; then
	echo "==> Cleaning build directory"
	west build -t pristine -d "$BUILD_DIR"
fi

if $do_build; then
	echo "==> Building $APP_DIR for $BOARD"
	west build -p auto -b "$BOARD" "$APP_DIR" -d "$BUILD_DIR"
fi

if $do_flash; then
	echo "==> Flashing $BOARD"
	west flash -d "$BUILD_DIR"
fi

if $do_debug_prepare; then
	echo "==> Preparing VS Code debug environment"
	prepare_debug_env
fi

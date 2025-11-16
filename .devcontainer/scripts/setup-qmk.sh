#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QMK_DIR="${QMK_HOME:-__qmk__}"
QMK_VERSION="${QMK_VERSION:-0.22.14}"
QMK_REPO_URL="${QMK_REPO_URL:-https://github.com/qmk/qmk_firmware.git}"

cd "$REPO_ROOT"

if [ ! -d "$QMK_DIR/.git" ]; then
  echo "Cloning QMK firmware ${QMK_VERSION} into ${QMK_DIR}..."
  git clone --depth 1 --branch "$QMK_VERSION" "$QMK_REPO_URL" "$QMK_DIR"
  qmk setup --home "$QMK_DIR" --yes
else
  echo "QMK firmware already present in ${QMK_DIR}, skipping clone."
fi

echo "Installing Python requirements..."
python3 -m pip install --upgrade pip
python3 -m pip install -r "${QMK_DIR}/requirements.txt"

KEYBALL_SOURCE="${REPO_ROOT}/qmk_firmware/keyboards/keyball"
KEYBALL_TARGET="${QMK_DIR}/keyboards/keyball"

if [ -d "$KEYBALL_SOURCE" ]; then
  mkdir -p "$(dirname "$KEYBALL_TARGET")"
  ln -sfn "$KEYBALL_SOURCE" "$KEYBALL_TARGET"
  echo "Linked ${KEYBALL_SOURCE} -> ${KEYBALL_TARGET}"
else
  echo "Warning: ${KEYBALL_SOURCE} not found. Skipping symlink."
fi

echo "Devcontainer setup complete."

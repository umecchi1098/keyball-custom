#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dest_root="${repo_root}/tmp/build_artifacts"
keyboard_choice=""
keymap_choice=""
compile_args=()

usage() {
  cat <<'USAGE'
使い方: build-keyball-interactive.sh [--keyboard NAME] [--keymap NAME] [--] [qmk compile の追加引数]

--keyboard, --keymap を指定すると対話入力をスキップできます。
"--" 以降の引数は qmk compile にそのまま渡されます。
USAGE
}

err() {
  echo "[ERROR] $*" >&2
  exit 1
}

in_list() {
  local needle="$1"
  shift
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

command -v qmk >/dev/null 2>&1 || err "qmk コマンドが見つかりません。"

while [ $# -gt 0 ]; do
  case "$1" in
    --keyboard)
      [ $# -ge 2 ] || err "--keyboard には値が必要です。"
      keyboard_choice="$2"
      shift 2
      ;;
    --keymap)
      [ $# -ge 2 ] || err "--keymap には値が必要です。"
      keymap_choice="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      compile_args+=("$@")
      break
      ;;
    *)
      compile_args+=("$1")
      shift
      ;;
  esac
done

qmk_dir="$(qmk env | awk -F'"' '/^QMK_HOME=/ {print $2; exit}')"
[ -n "$qmk_dir" ] || err "QMK_HOME を取得できませんでした。 qmk setup/config の確認が必要です。"
[ -d "$qmk_dir" ] || err "QMK_HOME(${qmk_dir}) が存在しません。"
keyball_root="${qmk_dir}/keyboards/keyball"
build_dir="${qmk_dir}/.build"
[ -d "$keyball_root" ] || err "${keyball_root} が見つかりません。"

keyboards=()
for dir in "$keyball_root"/*; do
  [ -d "$dir" ] || continue
  [ -d "$dir/keymaps" ] || continue
  keyboards+=("$(basename "$dir")")
done
if [ "${#keyboards[@]}" -gt 1 ]; then
  IFS=$'\n' keyboards=($(printf '%s\n' "${keyboards[@]}" | sort))
  unset IFS
fi
[ "${#keyboards[@]}" -gt 0 ] || err "選択可能なキーボードがありません。"

keyboard="$keyboard_choice"
if [ -n "$keyboard" ]; then
  in_list "$keyboard" "${keyboards[@]}" || err "キーボード ${keyboard} は候補にありません。"
else
  echo "キーボードを選択してください:" >&2
  PS3="キーボード番号: "
  select choice in "${keyboards[@]}"; do
    if [ -n "${choice:-}" ]; then
      keyboard="$choice"
      break
    fi
    echo "無効な番号です。" >&2
  done
fi

keymap_dir="${keyball_root}/${keyboard}/keymaps"
[ -d "$keymap_dir" ] || err "${keymap_dir} が見つかりません。"

keymaps=()
for dir in "$keymap_dir"/*; do
  [ -d "$dir" ] || continue
  keymaps+=("$(basename "$dir")")
done
if [ "${#keymaps[@]}" -gt 1 ]; then
  IFS=$'\n' keymaps=($(printf '%s\n' "${keymaps[@]}" | sort))
  unset IFS
fi
[ "${#keymaps[@]}" -gt 0 ] || err "選択可能なキーマップがありません。"

keymap="$keymap_choice"
if [ -n "$keymap" ]; then
  in_list "$keymap" "${keymaps[@]}" || err "キーマップ ${keymap} は候補にありません。"
else
  echo "キーマップを選択してください:" >&2
  PS3="キーマップ番号: "
  select choice in "${keymaps[@]}"; do
    if [ -n "${choice:-}" ]; then
      keymap="$choice"
      break
    fi
    echo "無効な番号です。" >&2
  done
fi

kb_arg="keyball/${keyboard}"
cmd=(qmk compile -kb "$kb_arg" -km "$keymap")
if [ "${#compile_args[@]}" -gt 0 ]; then
  cmd+=("${compile_args[@]}")
fi

echo "\n[INFO] ${kb_arg}:${keymap} をビルドします..." >&2
pushd "$qmk_dir" >/dev/null
if ! "${cmd[@]}"; then
  popd >/dev/null
  err "ビルドに失敗しました。"
fi
popd >/dev/null

artifact_prefix="keyball_${keyboard}_${keymap}"
shopt -s nullglob
artifacts=("${build_dir}/${artifact_prefix}".*)
shopt -u nullglob
[ "${#artifacts[@]}" -gt 0 ] || err "${artifact_prefix}.* に一致する生成物が見つかりません。"

stamp="$(date +%Y%m%d-%H%M%S)"
output_dir="${dest_root}/${artifact_prefix}_${stamp}"
mkdir -p "$output_dir"

for src in "${artifacts[@]}"; do
  cp "$src" "$output_dir/"
done

echo "\n[INFO] 生成物を ${output_dir} にコピーしました。" >&2
ls -1 "$output_dir"

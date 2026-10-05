#!/usr/bin/env bash
# Installs GUT (Godot Unit Test) into addons/gut.
# GUT is not committed (addons/gut/ is in .gitignore), so every member and CI
# run this script once after cloning. Running it again replaces the old copy.
#
# Usage (from anywhere inside the repo):
#   bash tools/install_gut.sh
# Offline (lab without internet), with a zip you already have:
#   GUT_ZIP=/path/to/Gut-9.7.1.zip bash tools/install_gut.sh

set -euo pipefail

GUT_VERSION="9.7.1"
GUT_URL="https://github.com/bitwes/Gut/archive/refs/tags/v${GUT_VERSION}.zip"

say() { printf '%s\n' "$*"; }
fail() {
  printf 'EROARE: %s\n' "$*" >&2
  exit 1
}

# The project root is the parent of the tools/ folder, wherever the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEST="${ROOT}/addons/gut"

[ -f "${ROOT}/project.godot" ] || fail "Nu găsesc project.godot în ${ROOT}. Rulează scriptul din repo-ul jocului."

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t gut_install)"
STAGING="${ROOT}/addons/.gut_new"
# Also removes a half-copied staging folder if the script stops early.
cleanup() { rm -rf "${TMP_DIR}" "${STAGING}"; }
trap cleanup EXIT

ZIP_FILE="${TMP_DIR}/gut.zip"
EXTRACT_DIR="${TMP_DIR}/extract"
mkdir -p "${EXTRACT_DIR}"

say "Instalez GUT ${GUT_VERSION} în addons/gut ..."

if [ -n "${GUT_ZIP:-}" ]; then
  [ -f "${GUT_ZIP}" ] || fail "Nu găsesc arhiva din GUT_ZIP: ${GUT_ZIP}"
  say "Folosesc arhiva locală ${GUT_ZIP}"
  cp "${GUT_ZIP}" "${ZIP_FILE}"
elif command -v curl >/dev/null 2>&1; then
  say "Descarc ${GUT_URL}"
  curl -fsSL --retry 3 --connect-timeout 20 -o "${ZIP_FILE}" "${GUT_URL}" \
    || fail "Descărcarea a eșuat. Verifică internetul și încearcă din nou."
elif command -v wget >/dev/null 2>&1; then
  say "Descarc ${GUT_URL}"
  wget -q --tries=3 --timeout=20 -O "${ZIP_FILE}" "${GUT_URL}" \
    || fail "Descărcarea a eșuat. Verifică internetul și încearcă din nou."
else
  fail "Am nevoie de curl sau wget. Instalează unul dintre ele."
fi

if command -v unzip >/dev/null 2>&1; then
  unzip -q "${ZIP_FILE}" -d "${EXTRACT_DIR}" || fail "Nu pot dezarhiva ${ZIP_FILE}."
elif command -v python3 >/dev/null 2>&1; then
  python3 -m zipfile -e "${ZIP_FILE}" "${EXTRACT_DIR}" || fail "Nu pot dezarhiva ${ZIP_FILE}."
else
  fail "Am nevoie de unzip sau python3 ca să dezarhivez."
fi

# The archive has one top folder (Gut-9.7.1/). Find addons/gut by its plugin.cfg.
PLUGIN_CFG="$(find "${EXTRACT_DIR}" -type f -path '*/addons/gut/plugin.cfg' -print -quit)"
[ -n "${PLUGIN_CFG}" ] || fail "Arhiva nu conține addons/gut/plugin.cfg."
SRC_DIR="$(dirname "${PLUGIN_CFG}")"

FOUND_VERSION="$(sed -n 's/^version="\(.*\)"/\1/p' "${PLUGIN_CFG}" | head -n 1)"
[ "${FOUND_VERSION}" = "${GUT_VERSION}" ] \
  || fail "Am primit GUT ${FOUND_VERSION:-necunoscut}, nu ${GUT_VERSION}."

# Copy next to the destination first, then swap, so a failed copy never
# leaves a half-installed addons/gut.
mkdir -p "${ROOT}/addons"
rm -rf "${STAGING}"
cp -R "${SRC_DIR}" "${STAGING}" || fail "Nu pot copia fișierele în addons/."

if [ -d "${DEST}" ]; then
  OLD_VERSION="$(sed -n 's/^version="\(.*\)"/\1/p' "${DEST}/plugin.cfg" 2>/dev/null | head -n 1 || true)"
  say "addons/gut există deja (versiunea ${OLD_VERSION:-necunoscută}). Îl înlocuiesc."
  rm -rf "${DEST}"
fi
mv "${STAGING}" "${DEST}"

INSTALLED="$(sed -n 's/^version="\(.*\)"/\1/p' "${DEST}/plugin.cfg" | head -n 1)"
say "Gata: GUT ${INSTALLED} este instalat în addons/gut."
say "Pasul următor: deschide proiectul în Godot 4.7.2. Panoul GUT apare jos, lângă Output."

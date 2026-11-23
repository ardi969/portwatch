#!/usr/bin/env bash
# Smoke test portwatch: nyalakan listener TCP + UDP beneran, lalu pastikan
# portwatch mendeteksinya (nama proses, user, port, JSON valid).
set -euo pipefail

cd "$(dirname "$0")/.."
PW="./portwatch"
ME=$(id -un)

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok: %s\n' "$*"; }

# --- listener TCP di 18099 (python http.server) ---------------------------
python3 -m http.server 18099 --bind 127.0.0.1 >/dev/null 2>&1 &
TCP_PID=$!

# --- listener UDP di 18098 (python socket) --------------------------------
python3 -c 'import socket,time; s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.bind(("127.0.0.1",18098)); time.sleep(30)' >/dev/null 2>&1 &
UDP_PID=$!

cleanup() { kill "$TCP_PID" "$UDP_PID" 2>/dev/null || true; }
trap cleanup EXIT
sleep 1

# 1. tabel default mendeteksi TCP 18099 dengan proses python3
OUT=$("$PW")
echo "$OUT" | grep -q '18099' || fail "port TCP 18099 tidak muncul di output default"
echo "$OUT" | grep '18099' | grep -q 'python3' || fail "proses python3 tidak tercantum untuk 18099"
echo "$OUT" | grep '18099' | grep -q "$ME" || fail "user $ME tidak tercantum untuk 18099"
pass "tabel default: TCP 18099 terdeteksi (python3, $ME)"

# 2. filter --port
OUT=$("$PW" --port 18099)
echo "$OUT" | grep -q '18099' || fail "--port 18099 tidak menampilkan 18099"
echo "$OUT" | grep -qv '18098' || fail "--port 18099 ikut menampilkan 18098"
pass "--port 18099"

# 3. filter --process (case-insensitive)
OUT=$("$PW" --process PYTHON3)
echo "$OUT" | grep -q '18099' || fail "--process PYTHON3 tidak menemukan python3"
pass "--process (case-insensitive)"

# 4. filter --tcp / --udp memisahkan protokol
"$PW" --tcp | grep -q '18099' || fail "--tcp tidak menampilkan listener TCP"
"$PW" --tcp | grep -q '18098' && fail "--tcp ikut menampilkan listener UDP"
"$PW" --udp | grep -q '18098' || fail "--udp tidak menampilkan listener UDP"
"$PW" --udp | grep -q '18099' && fail "--udp ikut menampilkan listener TCP"
pass "--tcp / --udp"

# 5. output JSON valid + berisi port 18099
"$PW" --json --port 18099 | python3 -c \
    'import json,sys; d=json.load(sys.stdin); assert any(x["port"]==18099 and x["process"]=="python3" for x in d), d' \
    || fail "JSON tidak valid / tidak berisi 18099+python3"
pass "--json valid (port 18099, process python3)"

# 6. sort + no-header jalan
"$PW" --sort process --no-header | grep -q '18099' || fail "--sort process --no-header gagal"
"$PW" --sort user | grep -q '18099' || fail "--sort user gagal"
pass "--sort / --no-header"

# 7. port yang tidak ada listener-nya -> pesan "No listening ports", exit 0
OUT=$("$PW" --port 19999)
echo "$OUT" | grep -q 'No listening ports' || fail "--port 19999 tidak memberi pesan kosong"
pass "port kosong -> pesan 'No listening ports'"

# 8. opsi salah -> exit != 0
"$PW" --bogus >/dev/null 2>&1 && fail "--bogus seharusnya gagal"
"$PW" --port abc >/dev/null 2>&1 && fail "--port abc seharusnya gagal"
pass "validasi opsi salah"

# 9. --version dan --help
"$PW" --version | grep -q 'portwatch 1.0.0' || fail "--version salah"
"$PW" --help | grep -q 'Usage' || fail "--help tidak menampilkan Usage"
pass "--version / --help"

printf '\nAll smoke tests passed.\n'

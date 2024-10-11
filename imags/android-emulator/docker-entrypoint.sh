#!/bin/sh

## forward adb port
sh -c "while true; do socat -s -dd -lf /var/log/socat-5037.log TCP4-LISTEN:5037,fork,reuseaddr TCP4:${ADB_DAEMON_ADDRESS},retry; sleep 0.01; done" &
## forward console port 5554 as external 5556
sh -c 'sleep 1; while true; do socat -s -d -lf /var/log/socat-5554.log TCP4-LISTEN:5556 TCP4:127.0.0.1:5554,retry; sleep 0.01; done' &
# forward adb port 5555 as external 5557
sh -c 'sleep 1; while true; do socat -s -d -lf /var/log/socat-5555.log TCP4-LISTEN:5557 TCP4:127.0.0.1:5555,retry; sleep 0.01; done' &

sh -c "sleep 1; adb connect ${ANDROID_EMULATOR_ADDRESS}:5557" &

#-no-window \
/home/user/Android/Sdk/emulator/emulator \
  -avd default \
  -no-boot-anim \
  -gpu off \
  -skip-adb-auth \
  -delay-adb \
  -no-audio \
  ${@}


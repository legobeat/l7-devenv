#!/bin/sh

## forward console port 5554 as external 5556
sh -c 'sleep 1; while true; do socat -d -lf /var/log/socat-5554.log TCP4-LISTEN:5556 tcp4:127.0.0.1:5554; sleep 0.01; done' &
# forward adb port 5555 as external 5557
sh -c 'sleep 1; while true; do socat -d -lf /var/log/socat-5555.log TCP4-LISTEN:5557 tcp4:127.0.0.1:5555; sleep 0.01; done' &

/home/user/Android/Sdk/emulator/emulator \
  -avd default \
  -no-window \
  -gpu off \
  -no-audio \
  ${@}


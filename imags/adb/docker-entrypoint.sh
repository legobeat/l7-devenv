#!/bin/bash

adb -a ${@}

#adb -a -H 0.0.0.0 -P 5037 -L tcp:0.0.0.0:5037 ${@}
#  --one-device SERIAL|USB  only allowed with 'start-server' or 'server nodaemon', server will only connect to one USB device, specified by a serial number or USB device address.
#  --exit-on-write-error    exit if stdout is closed

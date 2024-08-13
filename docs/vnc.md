# Remote collaboration with VNC

There is an experimental VNC image which provides a graphical environment with web browsers and remote-viewing capabilities:

To run and connect a viewer locally:
```
$ make -j4 images
$ podman build -t localhost/l7/vnc -f ./shipyard/vnc/Containerfile .
$ RUN_ARGS=' -p 5901:5901' NAME=vnc IMAGE=localhost/l7/vnc:latest de zsh -c 'DEBUG=1 /entrypoint.sh sleep 180000'

# open remote control
$ vncviewer 127.0.0.1:5901

```



# Remote collaboration with VNC

There is an experimental VNC image which provides a graphical X11 environment with terminal, web browser, and remote-viewing capabilities:

To run and connect a viewer locally:
```
$ make -j4 images
$ make image_vnc
$ podman compose up --no-deps --build --force-recreate vnc

# output generated vnc passwords
$ podman compose exec vnc cat /home/user/.local/vnc/admin_vncpasswd
$ podman compose exec vnc cat /home/user/.local/vnc/view_vncpasswd

# open remote control
$ vncviewer 127.0.0.1:5902
```

### Basic hotkeys

- `Ctrl+Esc c`: New terminal window
- `Ctrl+Esc w`: New firefox window
- `Ctrl+Esc d`: Application launcher
- `Ctrl+Esc ?`: Display keybindings
- `Ctrl+Esc L`: Reload `~/.ratpoisonrc`

Refer to `imags/X11/vnc/skel/.ratpoisonrc` for customization and complete reference.

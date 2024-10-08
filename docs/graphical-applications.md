# Running graphical applications

For launching graphical applications like terminal, web browser, and graphical IDE, there are two options, in either case utilizing X11:

1. A self-hosted X server running a dedicated desktop environment accessible over VNC
  - Recommended
2. Using a provided X socket
  - Affords more seamless integration at the cost of reduced isolation. Only recommended for advanced users.

## Requirements

The GUI-based images need to be built separately:

```
$ make images_gui
```

You will also want a VNC client. TigerVNC `vncviewer` is recommended.

## 1. Using a self-hosted X server

## Starting the desktop environment

By default, graphical applications will launch in a dedicated X server accessible via VNC. Currently, the display server needs to be started explicitly:

```
$ podman compose up --no-deps --build --force-recreate vnc

# output generated vnc passwords
$ podman compose exec vnc cat /home/user/.local/vnc/admin_vncpasswd
$ podman compose exec vnc cat /home/user/.local/vnc/view_vncpasswd

# open remote control
$ vncviewer 127.0.0.1:5902
```

### Launching applications
#### From the dev-shell

Provided applications will be launched directly in the VNC server if started from the shell. For example:

```
$ de
> firefox
```

### Inside the desktop environment

The default window manager is [ratpoison](https://www.nongnu.org/ratpoison/).

Refer to `imags/X11/vnc/skel/.ratpoisonrc` for customization and complete reference.

### Basic key bindings

- `Ctrl+. ?`: Display keybindings
- `Ctrl+. c`: New terminal window
- `Ctrl+. d`: Application launcher
- `Ctrl+. w`: New firefox window
- `Ctrl+. e`: New neovim window
- `Ctrl+. n`: Next window
- `Ctrl+. Tab`: Focus next
- `Ctrl+. s`: Split horizontally
- `Ctrl+. S`: Split vertically
- `Ctrl+. L`: Reload `~/.ratpoisonrc`

## 2. Using a provided X socket

If you have an existing X server you would like to use, you can mount and forward an existing socket.
When launching the environment or application, you will need to specify environment variables:
- `L7_X11_SOCKET_VOLUME`: The directory where the socket resides
- `L7_XAUTHORITY`: The path to the Xauthority file
- `L7_DISPLAY`: The DISPLAY number or path

For example, to launch a new xterm window in the current X session in a typical Linux environment:

```
$ export L7_X11_SOCKET_VOLUME=/tmp/.X11-unix L7_DISPLAY=${DISPLAY:-:0} L7_XAUTHORITY="${HOME}/.Xauthority"
$ podman compose run xterm
```

Or to launch firefox from inside the dev-shell:

```
$ export L7_X11_SOCKET_VOLUME=/tmp/.X11-unix L7_DISPLAY=${DISPLAY:-:0} L7_XAUTHORITY="${HOME}/.Xauthority"
$ de
> firefox
```

You can also provide the options directly in an existing shell session:
```
> L7_X11_SOCKET_VOLUME=/tmp/.X11-unix L7_DISPLAY=:0 L7_XAUTHORITY=${HOME}/.Xauthority firefox
```

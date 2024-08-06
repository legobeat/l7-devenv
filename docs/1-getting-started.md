
# Getting started

This will be a step-by-step guide to getting everything up and running from scratch.
This assumes you are running in a clean installation of Ubuntu 24.04 LTS or Debian Bookworm.
You should also be able to use this with Docker by replacing `podman` with `docker`.

## System preparation

### Installing dependencies

```
## Ensure your system is up to date
$ sudo apt-get update && sudo apt-get upgrade -y

## Install system dependencies
$ sudo apt-get install --no-install-recommends coreutils make podman buildah catatonit slirp4netns netavark passt fuse-overlayfs uidmap gnu-which overlayroot containers-storage yq whois golang-github-containernetworking-plugin-dnsname docker-compose-v2
```

<details><summary>Debian-specific</summary>
We will also need [docker-compose](https://github.com/docker/compose) v2. As of writing, it is not available in Debian distro repositories. You can either [build from source](https://github.com/docker/compose/blob/main/BUILDING.md), [download the binary release from GitHub](https://github.com/docker/compose?tab=readme-ov-file#linux), or install `docker-compose-plugin` from [Docker apt repositories](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository).
</details>

### Rootless podman setup

These steps may differ or not be required dependning on your distribution version. They have been tested on Debian 12 / Ubuntu 24.04 LTS.

```
$ systemctl --user enable --now podman.socket
$ podman info | grep graphDriver
# You should see `graphDriverName: overlay` or whatever you have previously configured
# If you see `vfs`, attempt a `podman system reset` or see Troubleshooting as it produces big and slow image layers
```

## Building

While you could quickly get up and running by pulling prebuilt images from the GitHub container registry, it is expected that you may want to do some customization of the images as part of configuration. By starting out from sources, we make that transition more natural.

```
## Sources directory - you can create a new directory or reuse an existing path where you keep your git repos checked out
$ export SRC_DIR=${HOME}/src
$ mkdir -p "${SRC_DIR}"
$ cd "${SRC_DIR}"

## Clone the repository
$ git clone --recurse-submodules https://github.com/legobeat/l7-devenv
$ cd l7-devenv
```

The environment is set up in the root [`Containerfile`](./Containerfile) (aka `Dockerfile`). While the defaults are intended to be a good start, you can inspect the `Containerfile` for any `ARG`s, which indicate customizable build-time arguments.

The image will be portable and contain no private information like usernames or auth tokens, though you can of course customize it to your liking.

### Build the images
While you can run `podman build` directly, there is also a [`Makefile`](./Makefile) for convenience that we are going to use.

```
$ make images
```

That's it! The command should install dependencies, build plugins from sources, and produce ready-to-use images. Inspect the `Makefile` to see supported configuration, e.g. if you prefer to use fish shell instead of default zsh:

```
$ make IMAGE_TAG=myfish SHELL=/usr/bin/fish EXTRA_PKGS=fish
```

The first build will take a while to complete. Subsequent builds on the same machine should be cached and faster.
When it's finished building, we can see our images in the local repository:

```
$ podman images | grep /l7 | head
```

## Installing

The main entrypoint for the IDE is [`devenv.sh`](../devenv.sh). After images are locally loaded, we just want to make it available in the global `PATH`. For convenience, we can call it `de`:

```
# Convenient installation script in user path
$ make install

# Or: Custom command name
$ L7_NVIM_CMD=my-ide make install

# Or: Manual User-local installation; may require modification of your .profile, .*shrc, etc
$ mkdir -p ~/.bin
$ ln -s "$(realpath devenv.sh)" ~/.bin/de

# Or: System-wide installation on default path
$ sudo ln -s ${SRC_DIR}/devenv.sh /usr/local/bin/de
```

`make install` will also add a `derun` command that can be used to shell into an existing session:

```
$ derun

# Or run a specific command
$ derun nvim /etc/hosts
```

You probably also want to set your default `SRC_DIR` pointing to your development root directory. For example:

```
$ echo 'export SRC_DIR=${HOME}/development/repos' >> ~/.bashrc
$ echo 'export SRC_DIR=${HOME}/development/repos' >> ~/.zshrc
```

## Using

Let's run the IDE container! First, let's try browsing this very repository and learn how changes are persisted when restarting. This will open a shell in your current working directory where subsequent commands will be run:

```
$ de # or ./devenv.sh, if you are not running an installed version

## Let's look at the files
> tree -L 2
> pwd

## We have a clean home directory
> tree -L 3 /home
> echo .DS_STORE >> .gitignore
> echo foo > ~/footest
> echo bar > ~/.local/bartest
> echo baz > /etc/shouldfail
> echo bay | sudo tee /etc/nosudo
> git status  # or g st
> exit        # or C^l
```

You should see changes in your working directory and `$HOME/.local/share/l7dev/local`. This is because these are mounted in the container (the working directory due to being a subdirectory of `$SRC_DIR`); any file-system changes in the container file-system outside of these mounts get wiped on exit.

### neovim

Now we will explore basic usage by using the IDE to make a change, prepare a commit, and push it for review.

The main entrypoint aside from your shell (default: `zsh`) will be `neovim`. We can either start a shell in the container lke above and run `neovim`, or run it directly:

```
$ de nvim README.md
```

This should open up [neovim](https://neovim.io) with the README of this repo.

The basic navigation (hjkl) and configuration is the same as traditional vim. This neovim installation comes with additional plugins installed and preconfigured, with some extra keybindings.
We can see how navigation can be done by opening the [keybindings](../skel/.config/nvim/keys.lua) configuration: `:e skel/.config/nvim/keys.lua<CR>` (when we type vim commands, `<CR>` is the same as pressing Enter).

First off, we can inspect the git status (`<C-g>`). Press `?` for keyboard shortcuts, `H` and `L` to jump between windows, and `<C-g>` again to close.
Let's imagine you're a macOS user and just noticed you have a distracting `.DS_STORE` in the diff view.

Use the file browser (`<C-n>`) to open `.containerignore` after displaying hidden files (`H`). Edit the file and save (`:w<CR>`).

#### Git operations
Now that it's time to add and commit the change, we have some options for how we want to do it. It's mostly a matter of preference:

##### git cli
Whatever tooling we use will be using these under the hood.

The usual git commands of course work but have some shortcuts as aliases defined in [`config/bashrc`](`config/bashrc`) and [`config/gitconfig`](`config/gitconfig`).

```
# Aside from your usual shell, neovim also has an embedded terminal:
# `:e term://zsh<CR>`
# Return to Normal mode by `C^l` or `C^\ C^n`

## add
> g a .containerignore

## inspect
> g dc

## commit
> g cm .containerignore -m 'Optional message'

## or in one line
> g cm .containerignore -m 'Optional message' .containerignore
```

##### tig
`tig` is a powerful git TUI client. We can use it to browse diffs and history, as well as preparing and making commits. It's especially useful when you want to stage or unstahe parts of a file.

```
# Launch from terminal
> tig
# Or directly in neovim:
# `:Tig<CR>`
```

1. Select `Unstaged changes`
2. Stage the line with `u`
3. Change to status view with `s`, inspect
4. Start commit with `C`

##### neotree
Navigate back to the git status, `ga`, `gc`.

---

Whichever approach you use, you will get the same error mssage:

```
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.
```

While the suggested instruction will work for a one-off, we are now getting to the point where the defaults need some customization. Setting up your git configuration is next on the agenda. See you in [`./2-configuring-git.md`](2-configuring-git.md).

## Troubleshooting
### Setup rootless podman (if necessary)
If you get permission errors or issues with mismatching userids, you are not alone.
While [rootless podman should generally work out of the box on newer mainstream distros, older or more obscure setups may require some preparation. The [official tutorialhttps://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) and [Arch wiki](https://wiki.archlinux.org/title/Podman#gootless_Podman) have some useful pointers.

Common setup:

```
$ sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
$ sudo setcap cap_setuid=ep /usr/bin/newuidmap
$ sudo setcap cap_setgid=ep /usr/bin/newgidmap
```

### `no space left on device` during image build
First, make sure you actually _do_ have more than a couple of GiB free space on yyour system.
Also make sure you have the `containers-storage` package install and inspect your `driver` and `graphroot` settings in `containers/storage.conf`.

This error can also arise due to a tmp device getting full, so we can try to expand it:

```
$ df -h
Filesystem          Size  Used Avail Use% Mounted on
/dev/mapper/root     30G  5.2G   23G  19% /
none                 30G  5.2G   23G  19% /usr/lib/modules
devtmpfs            4.0M     0  4.0M   0% /dev
tmpfs               1.0G  700M  300M   1% /tmp

$ sudo mount -oremount,size=4G /tmp
$ df -h

Filesystem          Size  Used Avail Use% Mounted on
/dev/mapper/root     30G  5.2G   23G  19% /
none                 30G  5.2G   23G  19% /usr/lib/modules
devtmpfs            4.0M     0  4.0M   0% /dev
tmpfs               3.9G  700M  3.2G   1% /tmp
```

### podman commands are too slow
The first thing to check is your [storage driver](https://github.com/containers/podman/issues/13226#issuecomment-1555872420).

### `setuid`, `newuidmap; write to uid_map failed: Operation not permitted`
Check storage driver settings on host. This should work:
```
$ cat ~/.config/containers/storage.conf
[storage]
driver = "overlay"
[storage.options.overlay]
force_mask = "shared"
mount_program = "/usr/bin/fuse-overlayfs"
```

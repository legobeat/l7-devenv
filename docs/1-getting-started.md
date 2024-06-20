
# Getting started

This will be a step-by-step guide to getting everything up and running from scratch.
This assumes you are running in a clean installation of Ubuntu 24.04 LTS or Debian Bookworm.
You should be able to use this with Docker by replacing `podman` with `docker`. 

## Installing dependencies

```
## Ensure your system is up to date
$ sudo apt-get update && sudo apt-get upgrade

## Install system dependencies
$ sudo apt-get install make podman slirp4netns fuse-overlayfs uidmap gnu-which
```

## Building
```
## Clone the repository
$ git clone --recurse-submodules https://github.com/legobeat/l7-devenv
$ cd l7-devenv
```

The environment is set up in the root [`Containerfile`](./Containerfile) (aka `Dockerfile`). While the defaults are intended to be a good start, you can inspect the `Containerfile` for any `ARG`s, which indicate customizable build-time arguments.

The image will be portable and contain no private information like usernames or auth tokens, though you can of course customize it to your liking.

### Build the images
While you can run `podman build` directly, there is also a [`Makefile`](./Makefile) for convenience.

```
$ make images
```

That's it! The command should install dependencies, build plugins from sources, and produce ready-to-use images. Inspect the `Makefile` to see supported configuration, e.g. if you want to use fish shell:
```
$ make SHELL=/usr/bin/zsh EXTRA_PKGS=fish
```
This image will take a while to build. You can ignore error messages from tests during the plugin build.
When it's finished building, wen can see our image in the local repository:
```
$ podman images | head
```

## Using

Let's run the container! First, let's try browsing this very repository and learn how changes are persisted when restarting. This will open a shell in your currenct working directory where subsequent commands will be run:

```
$ ./devenv.sh

## Let's look at the files
$$ tree -L 2
$$ pwd

## We have a clean home directory
$$ tree -L 3 /home
$$ echo .DS_STORE >> .containerignore
$$ echo .DS_STORE >> .gitignore
$$ echo foo > ~/footest
$$ echo bar > ~/.local/bartest
$$ echo baz > /etc/shouldfail
$$ git status
$$ exit
```

You should see changes in your working directory and `$HOME/.local/share/l7dev/local`. This is because these are mounted in the container; any file-system changes in the container file-system itself get wiped on exit.

### neovim

Now we will explore basic usage by using the IDE to make a change, prepare a commit, and push it for review.

The main entrypoint aside from your shell will be `neovim`. We can either start a shell in the container and run `neovim`, or run it directly:

```
$ ./devenv.sh nvim README.md
```

This should open up [neovim](https://neovim.io) with the README of this repo.

The basic navigation (hjkl) and configuration is the same as traditional vim. This neovim installation comes with additional plugins installed and preconfigured, with some extra keybindings.
We can see how navigation can be done by opening the [keybindings](./config/nvim/keys.lua) configuration: `:e config/nvim/keys.lua<CR>` (when we type vim commands `<CR>` is the same as pressing Enter).

First off, we can inspect the git status (`<C-g>`). Press `?` for keyboard shortcuts, and `<C-g>` again to close, or `H` and `L` to jump between windows.
Let's imagine you're a macOS user and just noticed you have a distracting `.DS_STORE` in the diff view.

Use the file browser (`<C-n>`) to open `.containerignore` after displaying hidden files (`H`). Edit the file and save (`:w<CR>`).

#### Git operations
Now that it's time to add and commit the change, we have some options for how we want to do it. It's mostly a matter of preference:

##### git cli
Whatever tooling we use will be using these under the hood.
```
# The usual git commands of course work but have some shortcuts as aliases defined in [`config/bashrc`](`config/bashrc`) and [`config/gitconfig`](`config/gitconfig`).

## add
$ g a .containerignore

## inspect
$ g dc

## commit
$ g cm .containerignore -m 'Optional message'

## or in one line
$ g cm .containerignore -m 'Optional message' .containerignore
```

##### tig
`tig` is a powerful git TUI client. We can use it to browse diffs and history, as well as preparing and making commits. It's especially useful when you want to stage or unstahe parts of a file.

```
$ tig
```

1. Select `Unstaged changes`
2. stage the line with `u`
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

While this will work for a one-off, porting over or setting up your git configuration is next on the agenda. See you in [`./2-configuring-git.md`](2-configuring-git.md).

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

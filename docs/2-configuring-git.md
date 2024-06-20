# Configuration

High-level overview for integration with git and GitHub:

#### SSH access
1. Ensure ssh socket is available from host (usually from `ssh-agent` or `gpg-agent`)
2. Set `SSH_SOCKET` env var when running `devenv.sh` to mount it in container and set `SSH_AUTH_SOCK` env var.
3. Configure

#### Git

### Git user configuration

The container comes with a default `.gitconfig`:

```
> cat ~/.gitconfig
```

Like other files in the home directory, changes here will be reset after a restart. We can add our custom gitconfig to mounted `~/.config/gitconfig`:

```
> cat <<EOT | tee ~/.config/gitconfig
  [user]
    email = you@example.com
    name = you
EOT
```

If you were following on from [`1-getting-started.md`](1-getting-started.md), you can now make a commit:

```
> g cm # -m 'commit title'
```

### SSH Setup

In order to push our changes, or pull from private repos, we need to set up authentication for GitHub remotes. In general, there are a few authentication methods, including:

- SSH key auth (ssh remotes only)
- GPG key auth
- Authentication token aka `GITHUB_TOKEN` (http remotes only)
- Oauth app credentials

We will be using SSH key authentication, which should be the most familiar.

First, if you have not done so, set up SSH authentication for your GitHub user on your host. With a default configuration, this should now work:

```
# Inspect keys
$ ssh-add -L

# Test connection
$ ssh git@github.com
Hi you! You've successfully authenticated, but GitHub does not provide shell access.

# Socket should be set and exist
$ echo "${SSH_AUTH_SOCKET}"
$ ls -la "${SSH_AUTH_SOCKET}"
```

To enable SSH integration, we set the `SSH_SOCKET` environment variable to the desired ssh-agent auth socket when starting:

```
$ SSH_SOCKET=${SSH_AUTH_SOCKET} ~/src/l7-devenv/devenv.sh
# inspect remotes
> g rv

# fork repo

# create PR
> gh pr create
# inspect any remotes created by gh
> g rv
```

# Configuration

### Git user configuration

The container comes with a default `.gitconfig`:

```
> cat ~/.gitconfig
```

Changes made here will be effective only for the lifetime of the current container. Modifying the default user configuration can be useful for experimentation and one-offs. To make changes stick across restarts and reboots, we can utilize container environment variables by running on the host:

```
$ cat <<EOT | tee -a ~/.config/l7ide/config/env
GIT_AUTHOR_EMAIL=you@example.com
GIT_AUTHOR_NAME=your name
GIT_COMMITTER_EMAIL=you@example.com
GIT_COMMITTER_NAME=your name
EOT
```

<details><summary>Overriding user configuration files</summary>

As an alternative to configuring using environment variables like above, we could also modify a persistent (mounted) configuration file `~/.config/git/config` with custom gitconfig by editing it on the host:

```
$ cat <<EOT | tee -a ~/.config/l7ide/config/git/config
  [user]
    email = you@example.com
    name = you
EOT
```

Any application reading configuration from `${HOME}/.config` can be configured in a similar way.

</details>

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

We will be using SSH key authentication, which should be the most familiar. However, instead of having the private key directly accessible by either the IDE context or development scripts, we weill be mounting an ssh authentication socket from an external agent. This may be running directly on your host or proxied elsewhere, and could itself be backed by a compatible hardware token.

First, if you have not done so, set up SSH authentication for your GitHub user on your host. After you have it sorted, with a default configuration, this should now work:

```
# Inspect keys
$ ssh-add -L

# Test connection
$ ssh git@github.com # or git@github.com-whatever if you set up alias remotes
Hi you! You've successfully authenticated, but GitHub does not provide shell access.

# Socket should be set and exist
$ echo "${SSH_AUTH_SOCKET}"
$ ls -la "${SSH_AUTH_SOCKET}"
```

<details><summary>Generating new local keys</summary>

```
$ ssh-keygen -t ed25519 -f ~/.ssh/github-l7-you

$ cat ~/.ssh/github-l7-you.pub
```

[Add SSH authentication pubkey to GitHub](https://github.com/settings/ssh/new)

```
$ eval `ssh-agent`
$ ssh-add github.com-you ~/.ssh/github.com-l7-you
$ cat <<EOT | tee -a ~/.ssh/config
  Host github.com-you
    HostName github.com
    User git
EOT
$ echo $SSH_AUTH_SOCK
$ ssh github.com-you
```

</details>

In case you have a dedicated socket, you can define it explicitly by setting the `SSH_SOCKET` environment variable to the path of the desired ssh-agent auth socket when starting the IDE:

```
$ SSH_SOCKET=${MY_SSH_AUTH_SOCKET} de
# inspect remotes
> g rv # git remote -v

# change from https to ssh protocol
> g remote set-url origin github.com-you:legobeat/l7-devenv
> g ru # git remote update
```

### GitHub API authentication setup

While it's all well and good to work over git and perform meta-tasks through the web browser, we can unlock a lot of productivity by allowing our tooling to integrate with the GitHub API.

> TODO: A future version of this should sandbox the forge auth token just like we do with ssh and gpg keys

First, [create a new authentication token](https://github.com/settings/personal-access-tokens/new).

Then, inside the IDE container:

```
> gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations on this host? SSH
? Generate a new SSH key to add to your GitHub account? No
? How would you like to authenticate GitHub CLI? Paste an authentication token
Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
The minimum required scopes are 'repo', 'read:org'.
? Paste your authentication token: **********************************************
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
! Authentication credentials saved in plain text
✓ Logged in as you

> gh auth status
github.com
  ✓ Logged in to github.com account you (/home/user/.config/gh/hosts.yml)
  - Active account: true
  - Git operations protocol: ssh
  - Token: **************************************************

# create PR
> gh pr create # --fill

# inspect any remotes created by gh
> g rv

# are CI checks passing?
> gh pr checks --watch
```

### GPG Setup

We also want to be able to sign our commit messages. We will use GPG to do so. Similarly to SSH keys, we will interface with an external agent. In this case, we will have the keyring managed in a dedicated container where signing will be made.

<details><summary>Generating GPG keypair</summary>

This will generate a new keypair, persisted in the private dontainer volume of the gpg proxy container. Commands are run inside IDE container.

```
> GPG_RUNNER_ENTRYPOINT=init-keyring.sh l7-gpg-proxy yourname you@example.com

# customize via:
# GPG_NAME
# GPG_EMAIL
# GPG_ALGO
# GPG_EXPIRY
# see man gpg --quick-gen-key for arguments reference

# list pubkey
> l7-gpg-proxy -K

# export pubkey again
> l7-gpg-proxy --export -a

# test signing a message
> echo 'hello there' | l7-gpg-proxy -bsa
```

The public key can then be [added on GitHub](https://github.com/settings/gpg/new).
</details>

The `l7-gpg-proxy` command is a `gpg` proxied to an ephemeral sibling container managing the keyring and handling gpg operations like signing. Once the keypair is under management by `l7-gpg-proxy`, all we need to do is tell git which key to use for signing operations:

```
# get the fingerprint
> l7-gpg-proxy -K

/vault/gnupg/pubring.kbx
------------------------
sec   ed25519 2025-02-19 [SC] [expires: 2025-05-01]
      A8EFB623C9138FEEABBADEADBEEF6302783834A0
uid           [ultimate] yourname <you@example.com>

# set the key (on host)
$ echo "[user] signingKey = A8EFB623C9138FEEABBADEADBEEF6302783834A0" >> ~/.config/l7ide/config/git/config

# you should now be able to make signed commits. To sign the latest commit on the current branch:
> g cma -S     # git commit --amend --gpg-sign

# enable commit signing by default (on host)
$ echo "[commit] gpgSign = true" >> ~/.config/l7ide/config/git/config

# temporarily disable signing
> g cm --no-gpg-sign
```

# Configuration

### Git user configuration

The container comes with a default `.gitconfig`:

```
> cat ~/.gitconfig
```

Like other files in the home directory, changes here will be reset after a restart. We can add our custom gitconfig to mounted `~/.config/gitconfig` by editing it on the host:

```
$ cat <<EOT | tee ~/.config/l7ide/config/gitconfig
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

> TODO

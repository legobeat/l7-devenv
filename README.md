# `l7ide`

Containerized neovim development environment. Primarily intended for contributors on [MetaMask](https://github.com/MetaMask) repositories.

For a guided tutorial, see [`GETTING_STARTED_DEBIAN.md`](./GETTING_STARTED_DEBIAN.md).

## Goals
- Ease-of-use
  - Quick and easy to set up with minimal configuration and sane defaults
  - Easy to maintain and update at your leisure
  - Easily extensible, configurable and customizable
  - Adapted for contribution to MetaMask and LavaMoat codebases
- Secure
  - Principle-of-least privilege applied
    - Text editor and plugins shouldn't need access to secrets like GitHub tokens
    - Keep development scripts and code-scanning tools away from each other and your home directory
  - Sandbox from rest of host system
    - Paste raw logs without exposing information about your user and host
  - Ephemeral file system
    - Everything beyond your sources and configuration are a clean slate after a restart
  - Auditable
- Fast and efficient
- Productivity-enhanching

## Dependencies
- OCI Container runtime
  - We will be using rootless podman to minimize privileges but Docker or any other compatible engine should work.
- An SSH agent socket
  - Typically provided by running `ssh-agent`

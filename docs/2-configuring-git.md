# Configuring git

High-level overview for integration with git and GitHub:

#### SSH access
1. Ensure ssh socket is available from host (usually from `ssh-agent` or `gpg-agent`)
2. Set `SSH_SOCKET` env var when running `devenv.sh` to mount it in container and set `SSH_AUTH_SOCK` env var.
3. Configure 

#### Git 

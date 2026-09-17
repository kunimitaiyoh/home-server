# home-server

Configuration management for the home server `radio`.

## Setup

1. Install Git and Ansible: `sudo apt-get update && sudo apt-get install -y git ansible` (or `./bootstrap.sh` if the repository is already cloned)
2. Clone this repository
3. Run `./apply.sh`

After applying, the `home-manager` command becomes available.

## Running individually

### Ansible only

```bash
(cd ansible && ansible-playbook site.yaml --ask-become-pass)
```

### Home Manager only

```bash
home-manager switch -b backup --flake ./nix#radio
```

## Manually installed tools

These tools are intentionally outside Ansible and Home Manager because they update themselves.

- Codex CLI: requires `bubblewrap` for sandboxing, which Ansible installs.

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

## Remote Desktop

Ansible installs Ubuntu Desktop and enables GNOME Remote Desktop's Remote Login (RDP) together with GDM. Port 3389 is not opened in UFW; connect through an SSH tunnel.

### One-time manual setup

Secrets are not managed by Ansible.

1. Set the device credentials that RDP clients present (first stage of Remote Login), then restart the daemon, which reads the credentials file only at startup:

   ```bash
   sudo grdctl --system rdp set-credentials
   sudo systemctl restart gnome-remote-desktop
   ```

2. Set the Linux password of each user who logs in via RDP (second stage, entered on the GDM screen; SSH stays key-only):

   ```bash
   sudo passwd bard
   sudo passwd witch
   ```

Do not run `grdctl --system rdp enable`, `disable`, or `set-tls-*`: they write a local state file that overrides `/etc/gnome-remote-desktop/grd.conf`.

### Connecting from Windows

1. Open an SSH tunnel (port 22 on the LAN, or the port forwarded by the router from outside). The local port must not be 3389: `mstsc` on Windows 11 refuses loopback connections to 3389 before sending anything.

   ```powershell
   ssh -L 23389:localhost:3389 -p <port> bard@<host>
   ```

2. Connect with `mstsc` to `localhost:23389`. Enter the device credentials (they can be saved in `mstsc`), then log in on the GDM screen with your Linux password.

## Updating

- Package updates: run `cd nix && nix flake update` and commit `flake.lock`
- If `flake.lock` does not exist yet, it is generated on the first apply; commit it

```bash
nix flake update --flake ./nix
```

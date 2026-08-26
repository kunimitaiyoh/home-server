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

## Updating

- Package updates: run `cd nix && nix flake update` and commit `flake.lock`
- If `flake.lock` does not exist yet, it is generated on the first apply; commit it

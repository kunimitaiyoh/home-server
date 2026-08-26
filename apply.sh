#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

(cd ansible && ansible-playbook site.yaml --ask-become-pass)

if ! command -v nix >/dev/null && [ -e /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi

if command -v home-manager >/dev/null; then
  home-manager switch -b backup --flake ./nix#radio
else
  nix run home-manager/release-26.05 -- switch -b backup --flake ./nix#radio
fi

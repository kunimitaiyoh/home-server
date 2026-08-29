{ pkgs, pkgs-unstable, lib, ... }:

{
  home.username = "bard";
  home.homeDirectory = "/home/bard";
  home.stateVersion = "26.05";

  home.packages = (with pkgs; [
    git
    gh
    jq
    ripgrep
    btop
    byobu
    tmux
    vim
    nano
    curl
    wget
    rsync
    unzip
    zip
    ffmpeg
    socat
    lsof
    dig
    terraform
    google-cloud-sdk
    stripe-cli
    android-tools
    awscli2
  ]) ++ (with pkgs-unstable; [
    claude-code
    codex
    opencode
  ]);

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    initExtra = builtins.readFile ./home/.bashrc;
    profileExtra = builtins.readFile ./home/.profile;
  };

  programs.mise = {
    enable = true;
    enableBashIntegration = true;
    globalConfig.tools = {
      node = [ "26" "24" "22" ];
      pnpm = "latest";
    };
  };

  home.file.".config/git/ignore".source = ./home/.config/git/ignore;
  home.file.".local/bin" = {
    source = ./home/.local/bin;
    recursive = true;
  };
  home.file.".claude/CLAUDE.md".source = ./home/.claude/CLAUDE.md;
  home.file.".claude/statusline.sh" = {
    source = ./home/.claude/statusline.sh;
    executable = true;
  };
  home.file.".claude/skills" = {
    source = ./home/.claude/skills;
    recursive = true;
  };
  home.file.".claude/rules" = {
    source = ./home/.claude/rules;
    recursive = true;
  };
  home.file.".claude/output-styles" = {
    source = ./home/.claude/output-styles;
    recursive = true;
  };

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run bash -c '
      mkdir -p ~/.claude
      [ -f ~/.claude/settings.json ] || echo "{}" > ~/.claude/settings.json
      ${pkgs.jq}/bin/jq -s ".[0] + .[1]" ~/.claude/settings.json ${./home/.claude/settings.json} > ~/.claude/settings.json.tmp
      mv ~/.claude/settings.json.tmp ~/.claude/settings.json
    '
  '';
}

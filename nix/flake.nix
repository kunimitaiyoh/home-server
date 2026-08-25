{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
        "terraform"
        "claude-code"
      ];
      pkgs = import nixpkgs {
        inherit system;
        config = { inherit allowUnfreePredicate; };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = { inherit allowUnfreePredicate; };
      };
    in
    {
      homeConfigurations.radio = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit pkgs-unstable; };
        modules = [ ./home.nix ];
      };
    };
}

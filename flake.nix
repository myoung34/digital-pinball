{
  description = "Digital pinball";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    formatter.x86_64-linux = pkgs.alejandra;

    packages.x86_64-linux = import ./pkgs pkgs;

    nixosConfigurations.pinball = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos/configuration.nix
        ./nixos/cabinet.nix
      ];
    };
  };
}

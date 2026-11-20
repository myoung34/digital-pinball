{
  description = "Digital pinball";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations.pinball = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [./nixos/configuration.nix];
    };
  };
}

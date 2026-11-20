pkgs: {
  dmdserver = pkgs.callPackage ./dmdserver.nix {};
  vpinball = pkgs.callPackage ./vpinball.nix {};
  vpinfe = pkgs.callPackage ./vpinfe.nix {};
}

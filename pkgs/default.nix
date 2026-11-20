pkgs: {
  make-directb2s = pkgs.callPackage ./make-directb2s.nix {};
  dmdserver = pkgs.callPackage ./dmdserver.nix {};
  dmd-placeholder = pkgs.callPackage ./dmd-placeholder.nix {};
  pindmd3-resync = pkgs.callPackage ./pindmd3-resync.nix {};
  vpinball = pkgs.callPackage ./vpinball.nix {};
  vpinfe = pkgs.callPackage ./vpinfe.nix {};
  virtuapin-fix = pkgs.callPackage ./virtuapin-fix.nix {};
}

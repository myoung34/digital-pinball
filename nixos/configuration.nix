{pkgs, ...}: {
  imports = [./hardware-configuration.nix];

  # Must match the bootloader the installer set up (see /etc/nixos/configuration.nix).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "pinball";
  networking.networkmanager.enable = true; # wifi: `nmtui`

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # XFCE with autologin, same as barcaderator.
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.xkb.layout = "us";
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "pinball";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  users.users.pinball = {
    isNormalUser = true;
    description = "pinball";
    extraGroups = ["networkmanager" "wheel"];
    initialPassword = "pinball"; # change with `passwd` after first login
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  programs.firefox.enable = true;
  programs.git = {
    enable = true;
    config.init.defaultBranch = "main";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    vim
    wget
    ripgrep
  ];

  # Set to the value in the installer-generated /etc/nixos/configuration.nix. Never bump it.
  system.stateVersion = "26.05";
}

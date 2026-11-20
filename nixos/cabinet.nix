# Virtual pinball cabinet: GPU, VPX, VPinFE launcher, PinDMD3 and controller access.
{
  config,
  pkgs,
  ...
}: let
  pinballPkgs = import ../pkgs pkgs;
  home = config.users.users.pinball.home;
  pindmd3 = "/dev/serial/by-id/usb-VirtuaPin_VirtuaPin_PinDMD3_4294967295-if00";

  vpinfeIni = pkgs.writeText "vpinfe.ini" ''
    [Displays]
    tablescreenid = 0
    bgscreenid = 1
    dmdscreenid =
    cabmode = true
    tableorientation = landscape
    tablerotation = 270

    [Settings]
    vpxbinpath = /run/current-system/sw/bin/VPinballX_BGFX
    tablerootdir = ${home}/tables
    # No keyring on this machine (see gnome-keyring below).
    chromeoptions = --password-store=basic

    [Input]
    joyleft = 9
    joyright = 1
    joyselect = 8
    joyback = 10
    joymenu = 2
  '';
  # Index new table folders (metadata + art) before showing the wheel, and
  # build a static backglass for tables that don't ship one.
  launcher = pkgs.writeShellScript "vpinfe-cabinet" ''
    # The compositor adds a frame of latency; nothing here needs it.
    ${pkgs.xfconf}/bin/xfconf-query -c xfwm4 -p /general/use_compositing -s false || true
    ${pinballPkgs.vpinfe}/bin/vpinfe --buildmeta
    ${pinballPkgs.make-directb2s}/bin/make-directb2s ${home}/tables
    exec ${pinballPkgs.vpinfe}/bin/vpinfe
  '';
in {
  # Quadro M4000 (Maxwell): 580 is the last driver branch that supports it,
  # and Maxwell has no open kernel module.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    modesetting.enable = true;
  };

  # The playfield TV is mounted with its bottom edge at the backbox end. VPX's
  # cabinet autofit always draws for the other way round, so flip the output.
  services.xserver.displayManager.setupCommands = "${pkgs.xrandr}/bin/xrandr --output DP-1 --rotate inverted";

  # Never blank the screens.
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
  '';
  services.xserver.desktopManager.xfce.enableScreensaver = false;
  environment.xfce.excludePackages = [pkgs.xfce4-power-manager];
  # Autologin never unlocks the keyring, so anything touching it pops a password prompt.
  services.gnome.gnome-keyring.enable = false;

  environment.systemPackages = [pinballPkgs.vpinball pinballPkgs.vpinfe];
  services.unclutter-xfixes.enable = true; # hide the mouse cursor

  # PinDMD3 is a USB serial device (/dev/ttyACM0, group dialout).
  users.users.pinball.extraGroups = ["dialout"];

  # Fixes the VirtuaPin plunger axis (see pkgs/virtuapin-fix.py).
  hardware.uinput.enable = true;
  systemd.services.virtuapin-fix = {
    description = "VirtuaPin Controller with signed axes";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pinballPkgs.virtuapin-fix}/bin/virtuapin-fix";
      Restart = "always";
    };
  };

  systemd.services.dmdserver = {
    description = "libdmdutil DMD server (PinDMD3)";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      # A warm reboot can leave the DMD mid-frame; resync it or it shows garbage.
      ExecStartPre = "${pinballPkgs.pindmd3-resync}/bin/pindmd3-resync ${pindmd3}";
      ExecStart = "${pinballPkgs.dmdserver}/bin/dmdserver --config=${./cabinet/dmdserver.ini} --wait-for-displays --logging";
      # Placeholder shown on the wheel and after each game (buffered frame).
      ExecStartPost = "${pinballPkgs.dmd-placeholder}/bin/dmd-placeholder";
      DynamicUser = true;
      SupplementaryGroups = ["dialout"];
      Restart = "always";
    };
  };

  # Seed settings once; VPX and VPinFE rewrite these files themselves.
  systemd.tmpfiles.rules = [
    "d ${home}/tables 0755 pinball users -"
    "d ${home}/.local/share/VPinballX/10.8 0755 pinball users -"
    "C ${home}/.local/share/VPinballX/10.8/VPinballX.ini 0644 pinball users - ${./cabinet/VPinballX.ini}"
    "z ${home}/.local/share/VPinballX/10.8/VPinballX.ini 0644 pinball users -"
    "d ${home}/.config/vpinfe 0755 pinball users -"
    "C ${home}/.config/vpinfe/vpinfe.ini 0644 pinball users - ${vpinfeIni}"
    "z ${home}/.config/vpinfe/vpinfe.ini 0644 pinball users -"
  ];

  environment.etc."xdg/autostart/vpinfe.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=VPinFE
    Exec=${launcher}
  '';
}

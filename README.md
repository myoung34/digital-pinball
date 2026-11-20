# Digital Pinball

NixOS config for the pinball cabinet (host `pinball`): XFCE, autologin, NetworkManager wifi.

## First boot (no network yet)

The minimal install has no wifi tooling, so apply the starter config through the
classic `/etc/nixos` path first:

1. Copy `nixos/configuration.nix` over `/etc/nixos/configuration.nix`, keeping the
   installer's `hardware-configuration.nix`, bootloader lines, and `system.stateVersion`.
2. Without network the rebuild can't download packages. Either plug in ethernet,
   or boot the installer USB, connect wifi there (`nmtui` on the minimal ISO), then
   mount the disk at `/mnt` and run `nixos-install`.
3. `sudo nixos-rebuild switch`, reboot, then connect with `nmtui`.

## After networking works

```sh
git clone git@github.com:myoung34/digital-pinball.git && cd digital-pinball
cp /etc/nixos/hardware-configuration.nix nixos/
git add nixos/hardware-configuration.nix   # flakes only see git-tracked files
sudo nixos-rebuild switch --flake .#pinball
```

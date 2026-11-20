# VPinFE: a multi-screen VPX frontend (Python + Chromium kiosk windows).
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  python3,
  chromium,
}: let
  python = python3.withPackages (ps:
    with ps; [
      nicegui
      olefile
      pillow
      platformdirs
      psutil
      py7zr
      pynput
      qrcode
      rarfile
      requests
      screeninfo
      websockets
    ]);
in
  stdenvNoCC.mkDerivation rec {
    pname = "vpinfe";
    version = "2.6.6";

    src = fetchFromGitHub {
      owner = "vpinfe";
      repo = "vpinfe";
      rev = "v${version}";
      hash = "sha256-DOzpzq8IguNI9WbR6ckXtxkjADkGo6LHaSo8acvXSJw=";
    };

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/vpinfe $out/bin
      cp -r . $out/share/vpinfe
      substituteInPlace $out/share/vpinfe/common/app_version.py --replace-quiet dev-local v${version}
      makeWrapper ${python}/bin/python $out/bin/vpinfe \
        --add-flags $out/share/vpinfe/main.py \
        --prefix PATH : ${lib.makeBinPath [chromium]}
      runHook postInstall
    '';

    meta = {
      description = "Frontend for Visual Pinball X";
      homepage = "https://github.com/vpinfe/vpinfe";
      license = lib.licenses.mit;
      mainProgram = "vpinfe";
    };
  }

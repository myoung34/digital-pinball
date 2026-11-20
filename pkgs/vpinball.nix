# Visual Pinball X standalone, from the upstream prebuilt Linux release.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  libdrm,
  libgbm,
  libGL,
  libpng,
  libtiff,
  pipewire,
  libxkbcommon,
  udev,
  vulkan-loader,
  wayland,
  libx11,
  libxcursor,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxscrnsaver,
  libxtst,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "vpinball";
  version = "10.8.1-5436-af26b2d93";

  src = fetchurl {
    url = "https://github.com/vpinball/vpinball/releases/download/v${version}/VPinballX_GL-${version}-linux-x64-Release.tar.gz";
    hash = "sha256-kJaTersaXdItxGeC22d51jjY48L6xTMYTYdpnGKtWjM=";
  };
  sourceRoot = ".";

  nativeBuildInputs = [autoPatchelfHook makeWrapper];

  # SDL3 declares its dlopen() targets in ELF notes; autoPatchelf adds them to RUNPATH.
  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libdrm
    libgbm
    libGL
    libpng
    libtiff
    libxkbcommon
    pipewire
    udev
    vulkan-loader
    wayland
    zlib
    libx11
    libxcursor
    libxext
    libxfixes
    libxi
    libxrandr
    libxscrnsaver
    libxtst
  ];
  autoPatchelfIgnoreMissingDeps = ["libsteam_api.so" "libGLES_CM.so.1"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/vpinball $out/bin
    cp -r . $out/opt/vpinball
    makeWrapper $out/opt/vpinball/VPinballX_GL $out/bin/VPinballX_GL
    runHook postInstall
  '';

  meta = {
    description = "Visual Pinball X standalone";
    homepage = "https://github.com/vpinball/vpinball";
    license = lib.licenses.gpl3Plus;
    platforms = ["x86_64-linux"];
    mainProgram = "VPinballX_GL";
  };
}

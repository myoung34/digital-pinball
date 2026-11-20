# Visual Pinball X standalone, from the upstream prebuilt Linux release.
# BGFX, not GL: the GL build can't render separate backglass/DMD windows.
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
    url = "https://github.com/vpinball/vpinball/releases/download/v${version}/VPinballX_BGFX-${version}-linux-x64-Release.tar.gz";
    hash = "sha256-nT+Xk7DI68PlPOpC6ZY77rUwWiWfgw2HyrnxzabIGl0=";
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
  autoPatchelfIgnoreMissingDeps = ["libsteam_api.so" "libGLES_CM.so.1" "libd3d12.so" "librenderdoc.so" "libwebgpu_dawn.so"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/vpinball $out/bin
    cp -r . $out/opt/vpinball
    # libbgfx dlopen()s EGL/Vulkan without ELF dlopen notes, so RUNPATH misses them.
    makeWrapper $out/opt/vpinball/VPinballX_BGFX $out/bin/VPinballX_BGFX \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libGL vulkan-loader]}
    runHook postInstall
  '';

  meta = {
    description = "Visual Pinball X standalone";
    homepage = "https://github.com/vpinball/vpinball";
    license = lib.licenses.gpl3Plus;
    platforms = ["x86_64-linux"];
    mainProgram = "VPinballX_BGFX";
  };
}

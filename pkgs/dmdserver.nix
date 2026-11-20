# dmdserver from libdmdutil master: the VPX 10.8.1 release bundles a libdmdutil
# without PinDMD3 support, so VPX streams frames here (DMDServer=1) instead.
# Upstream builds its deps with download scripts; this does the same steps offline.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  libserialport,
}: let
  src = owner: repo: rev: hash: fetchFromGitHub {inherit owner repo rev hash;};
  libdmdutil = src "vpinball" "libdmdutil" "6b8f711a5346cf2e70562872ebc1a57b210906df" "sha256-A6xb/3E/he+ytLP+pAHueJVYdFs+Esd2Q6RN3YgNcCw=";
  # Pinned by libdmdutil's platforms/config.sh and libzedmd's platforms/config.sh.
  libzedmd = src "PPUC" "libzedmd" "ed69d499d87d4d328bd328773cc6bbd3dadd64c3" "sha256-z+O6IxRM8wBi/8trU1dJ8bG/35GVQIzc5BLWWg1FbnM=";
  cargs = src "likle" "cargs" "0698c3f90333446d0fc2745c1e9ce10dd4a9497a" "sha256-DpUeKFVtbpD2lqW10q91zCFmm4AQKAYSHXUp5B1YNM8=";
  sockpp = src "fpagliughi" "sockpp" "e6c4688a576d95f42dd7628cefe68092f6c5cd0f" "sha256-eIgYam/iQXjT3/Fu6ptNGSUVutLMG5Z1tmLsKLFOD/Q=";
  libframeutil = src "ppuc" "libframeutil" "711ab21dcf9ad33d8db8339dfd3b1548bcc34cdb" "sha256-SEfoFFEImthhp03d2DoZApJIWI4adcPZAYfa47xrwpE=";
in
  stdenv.mkDerivation {
    pname = "dmdserver";
    version = "0.14.0-unstable-2026-10-30";

    src = libdmdutil;
    nativeBuildInputs = [cmake];
    buildInputs = [libserialport];
    dontUseCmakeConfigure = true;

    buildPhase = ''
      runHook preBuild
      root=$PWD
      libs=$root/deps/lib
      inc=$root/deps/include
      mkdir -p $libs $inc

      cp -r ${cargs} cargs && chmod -R u+w cargs
      cmake -S cargs -B cargs/build -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
      cmake --build cargs/build -j$NIX_BUILD_CORES
      cp cargs/include/cargs.h $inc/ && cp cargs/build/libcargs.so $libs/

      cp -r ${sockpp} sockpp && chmod -R u+w sockpp
      cmake -S sockpp -B sockpp/build -DCMAKE_BUILD_TYPE=Release
      cmake --build sockpp/build -j$NIX_BUILD_CORES
      cp -r sockpp/include/sockpp $inc/ && cp -a sockpp/build/libsockpp.so* $libs/

      cp ${lib.getDev libserialport}/include/libserialport.h $inc/
      cp -a ${libserialport}/lib/libserialport.so* $libs/
      cp ${libframeutil}/include/* $inc/

      # Each project expects its deps under third-party/{include,runtime-libs/linux/x64}.
      thirdparty() {
        mkdir -p $1/third-party/include $1/third-party/runtime-libs/linux/x64
        cp -rn $inc/* $1/third-party/include/
        cp -a $libs/* $1/third-party/runtime-libs/linux/x64/
      }

      cp -r ${libzedmd} libzedmd && chmod -R u+w libzedmd
      thirdparty libzedmd
      cmake -S libzedmd -B libzedmd/build -DPLATFORM=linux -DARCH=x64 \
        -DBUILD_STATIC=OFF -DPOST_BUILD_COPY_EXT_LIBS=OFF -DCMAKE_BUILD_TYPE=Release
      cmake --build libzedmd/build --target zedmd_shared -j$NIX_BUILD_CORES
      cp libzedmd/src/ZeDMD.h $inc/ && cp -a libzedmd/build/libzedmd.so* $libs/

      thirdparty $root
      cmake -S . -B build -DPLATFORM=linux -DARCH=x64 \
        -DBUILD_STATIC=OFF -DPOST_BUILD_COPY_EXT_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_SERUM=OFF -DENABLE_VNI=OFF -DENABLE_PUP=OFF -DENABLE_PIN2DMD=OFF
      cmake --build build --target dmdserver -j$NIX_BUILD_CORES
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib
      cp build/dmdserver $out/bin/
      cp -a build/libdmdutil.so* deps/lib/* $out/lib/
      chmod -R u+w $out/lib
      for f in $out/bin/dmdserver $out/lib/*.so; do patchelf --add-rpath $out/lib $f; done
      runHook postInstall
    '';

    meta = {
      description = "libdmdutil DMD server (ZeDMD, Pixelcade, PinDMD3)";
      homepage = "https://github.com/vpinball/libdmdutil";
      license = lib.licenses.gpl3Plus;
      platforms = ["x86_64-linux"];
      mainProgram = "dmdserver";
    };
  }

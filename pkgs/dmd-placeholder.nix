{
  dejavu_fonts,
  python3Packages,
  writers,
  writeShellScriptBin,
}: let
  script = writers.writePython3 "dmd-placeholder" {
    libraries = [python3Packages.pillow];
    flakeIgnore = ["E501"];
  } (builtins.readFile ./dmd-placeholder.py);
in
  writeShellScriptBin "dmd-placeholder" ''
    exec ${script} ${dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf "$@"
  ''

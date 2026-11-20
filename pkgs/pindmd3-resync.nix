{
  python3Packages,
  writers,
}:
writers.writePython3Bin "pindmd3-resync" {
  libraries = [python3Packages.pyserial];
  flakeIgnore = ["E501"];
} (builtins.readFile ./pindmd3-resync.py)

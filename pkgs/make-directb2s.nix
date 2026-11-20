{
  python3Packages,
  writers,
}:
writers.writePython3Bin "make-directb2s" {
  libraries = [python3Packages.pillow];
  flakeIgnore = ["E501"];
} (builtins.readFile ./make-directb2s.py)

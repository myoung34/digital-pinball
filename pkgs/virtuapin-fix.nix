{
  python3Packages,
  writers,
}:
writers.writePython3Bin "virtuapin-fix" {
  libraries = [python3Packages.evdev];
  flakeIgnore = ["E203" "E501"];
} (builtins.readFile ./virtuapin-fix.py)

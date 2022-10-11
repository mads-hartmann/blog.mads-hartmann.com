# This file is being read by nix-shell. See 'man nix-shell' for more details on how this works.
let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs { };
in
nixpkgs.mkShell {
  nativeBuildInputs = [
    nixpkgs.niv
    nixpkgs.ruby_3_1
  ];
}

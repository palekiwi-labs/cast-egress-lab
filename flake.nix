{
  description = "cast-egress-lab: probe tools for the cast egress proxy spike";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in {
      # Only gaps in the cast sandbox shell. pi, claude-code and gh are
      # deliberately absent: probe the binaries real services use.
      # mkShellNoCC avoids a stdenv bash replacing SHELL.
      devShells = forAll (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [ nodejs opencode jq go-task ];
        };
      });
    };
}

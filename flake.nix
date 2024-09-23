{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }:
    let
      forAllSystems =
        nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in {
      packages = forAllSystems (system: rec {
        default = firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "firmware";

          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".conf"
            ".keymap"
            ".dtsi"
            ".yml"
            ".shield"
            ".overlay"
            ".defconfig"
          ];

          board = "nice_nano_v2";
          shield = "urchin_%PART%";

          zephyrDepsHash =
            "sha256-TBGBB8VowUxdvlBGY4jprgKg6fjmb712ennqr88TyZE=";

          meta = {
            description = "ZMK firmware";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems
        (system: { default = zmk-nix.devShells.${system}.default; });
    };
}

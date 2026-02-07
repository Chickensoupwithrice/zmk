{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in
    {
      packages = forAllSystems (
        system:
        let
          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".conf"
            ".keymap"
            ".dtsi"
            ".yml"
            ".shield"
            ".overlay"
            ".defconfig"
          ];

          zephyrDepsHash = "sha256-DXOQ+Hu8p1qeLiB1loRmKG9YOVbkJWMOrDI/aVA472M=";
        in
        rec {
          default = firmware;

          firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
            inherit src zephyrDepsHash;
            name = "firmware";

            board = "nice_nano_v2";
            shield = "urchin_%PART%";

            meta = {
              description = "ZMK firmware";
              license = nixpkgs.lib.licenses.mit;
              platforms = nixpkgs.lib.platforms.all;
            };
          };

          flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
          update = zmk-nix.packages.${system}.update;

          settings_reset = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
            inherit src zephyrDepsHash;
            inherit (firmware) westDeps;
            name = "settings_reset";

            board = "nice_nano_v2";
            shield = "settings_reset";
          };

          flash_settings_reset = zmk-nix.packages.${system}.flash.override {
            firmware = settings_reset;
          };
        }
      );

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}

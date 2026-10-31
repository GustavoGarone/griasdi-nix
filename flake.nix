{
  description = "griasdi, end-to-end encrypted chat and voice, for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # griasdi is unfree. Allow just it here, so the packages and the module
      # build without the consumer enabling allowUnfree.
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "griasdi"
                  "griasdi-unwrapped"
                ];
            }
          )
        );
    in
    {
      packages = forAllSystems (pkgs: rec {
        griasdi = pkgs.callPackage ./package.nix { };
        default = griasdi;
      });

      overlays.default = final: _prev: {
        griasdi = final.callPackage ./package.nix { };
      };

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.griasdi;
        in
        {
          options.programs.griasdi = {
            enable = lib.mkEnableOption "griasdi, end-to-end encrypted chat and voice";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.griasdi;
              defaultText = lib.literalExpression "griasdi-nix.packages.\${system}.griasdi";
              description = "The griasdi package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}

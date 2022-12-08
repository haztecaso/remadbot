{
  description = "Bot de telegram que envía avisos sobre nuevas bicicletas en el servicio de intercambio de objetos del ayuntamiento de Madrid, ReMAD.";


  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "aarch64-linux" "aarch64-darwin" "i686-linux" "x86_64-darwin" "x86_64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

    requirements = python310Packages: with python310Packages; [
        requests
        beautifulsoup4
        python-telegram-bot
    ];

    remadbot = {lib, python310Packages}: python310Packages.buildPythonPackage rec {
      pname = "remadbot";
      version = "0.1.0";

      src = ./.;

      propagatedBuildInputs = requirements python310Packages;

      meta = {
        homepage = "https://github.com/haztecaso/remadbot";
        description = "Bot de telegram que envía avisos sobre nuevas bicicletas en el servicio de intercambio de objetos del ayuntamiento de Madrid, ReMAD.";
        license = lib.licenses.gpl3;
      };
    };
  in rec {
    packages = forAllSystems (system: {
      remadbot = nixpkgs.legacyPackages.${system}.callPackage remadbot { };
    });

    defaultPackage = forAllSystems (system: packages.${system}.remadbot);

    nixosModule = { config, lib, pkgs, ... }:
    let
      cfg = config.services.remadbot;
      pkg = pkgs.callPackage remadbot {};
    in
    {
      options.services.remadbot = with lib;{
        enable = mkEnableOption "remadbot service";
        frequency = mkOption {
          type = types.int;
          default = 30;
          description = "frequency of cron job in minutes.";
        };
        prod = mkOption {
          type = types.bool;
          default = false;
          description = "enable production mode";
        };
        configFile = mkOption {
          type = types.path;
          description = "path of remadbot config.json config file."; 
        };
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkg ];
        services.cron = {
          enable = true;
          systemCronJobs = let
            freq = lib.strings.floatToString cfg.frequency;
            conf = "--conf ${cfg.configFile}";
            prod = if cfg.prod then "--prod" else "";
          in [
            ''*/${freq} * * * *  root .  /etc/profile; ${pkg}/bin/remadbot ${conf} ${prod}''
          ];
        };
      };
    };

    devShell = forAllSystems (system: nixpkgs.legacyPackages.${system}.mkShell {
      nativeBuildInputs = with nixpkgs.legacyPackages.${system};
        requirements python310Packages ++ [ jq fx python310Packages.black ];
      shellHook = ''
        alias remadbot="python remadbot"
      '';
    });

    overlay = final: prev: {
      remadbot = final.callPackage remadbot {};
    };
  };
}

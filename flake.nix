{
  description = "R environment for replica project with database analysis tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # R environment with required packages
        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            RSQLite
            jsonlite
            dplyr
            # Additional useful packages for data analysis
            ggplot2
            tidyr
            readr
          ];
        };
      in
      {
        # Default package
        packages.default = rEnv;

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rEnv
            pkgs.sqlite
            # Additional development tools
            pkgs.git
            pkgs.gnumake
          ];
          
          shellHook = ''
            echo "🔬 R environment for replica project"
            echo "📊 Available R packages: RSQLite, jsonlite, dplyr, ggplot2, tidyr, readr"
            echo "🗄️  SQLite tools available"
            echo ""
            echo "To start R: r"
            echo "To load your function: source('get_data_from_db.R')"
          '';
        };

        # Apps for easy access
        apps.default = {
          type = "app";
          program = "${rEnv}/bin/R";
        };
      });
}

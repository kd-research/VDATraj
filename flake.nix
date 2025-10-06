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

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      flake-compat,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
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
            # Testing packages
            testthat
            purrr
          ];
        };
      in
      {
        # Default package
        packages.default = rEnv;

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rEnv
            sqlite
            # Additional development tools
            git
            gnumake
            # latest TeX Live for R Markdown and reports
            texliveFull
            (python3.withPackages (ps: with ps; [ pygments ]))
          ];
        };

        # Apps for easy access
        apps.default = {
          type = "app";
          program = "${rEnv}/bin/R";
        };

        # Checks - run testthat unit tests
        checks.default = pkgs.stdenv.mkDerivation {
          name = "find-variance-tests";
          src = ./.;
          
          buildInputs = [ rEnv ];
          
          buildPhase = ''
            # No build phase needed
          '';
          
          checkPhase = ''
            # Run testthat tests
            ${rEnv}/bin/Rscript tests/testthat.R
          '';
          
          installPhase = ''
            # Create a dummy output to satisfy Nix
            mkdir -p $out
          '';
          
          doCheck = true;
        };
      }
    );
}

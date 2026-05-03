{
  description = "R environment for replica project with database analysis tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      flake-compat,
      treefmt-nix,
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
            here
            DBI
            # Additional useful packages for data analysis
            ggplot2
            tidyr
            readr
            # Testing packages
            testthat
            purrr
            # LSP
            languageserver
            # Formatting
            styler
          ];
        };

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          settings.formatter = {
            R = {
              command = "${rEnv}/bin/Rscript";
              options = [
                "-e"
                "styler::style_file(commandArgs(trailingOnly=TRUE))"
              ];
              includes = [ "*.R" ];
            };
          };
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

        formatter = treefmtEval.config.build.wrapper;

        # Checks - run testthat unit tests
        checks.default = pkgs.stdenv.mkDerivation {
          name = "vdatraj-tests";
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

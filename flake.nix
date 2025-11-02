{
  description = "Dev shell for ExceptionHandling - provides dotnet SDK and helpful tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; }; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dotnet-sdk
            mono
            # Use wineWowPackages.stable which provides a 64-bit-capable wine build
            (wineWowPackages.stable)
            (wineWow64Packages.stable)
            winetricks
            git
            unzip
          ];

          shellHook = ''
            echo "Entering dev shell for ExceptionHandling"
            echo "dotnet --info:"
            dotnet --info || true

            # Ensure wine64 is available in PATH. Some nixpkgs wine builds expose only `wine`.
            if ! command -v wine64 >/dev/null 2>&1; then
              mkdir -p .direnv/bin
              if [ ! -x .direnv/bin/wine64 ]; then
                ln -sf "$(command -v wine)" .direnv/bin/wine64 || true
              fi
              PATH="$PWD/.direnv/bin:$PATH"
              export PATH
            fi
          '';
        };
      }
    );
}

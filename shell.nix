{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    dotnet-sdk
    mono
    # Use the 64-bit-capable wine from wineWowPackages.stable
  (wineWowPackages.stable)
  (wineWow64Packages.stable)
    winetricks
    git
    unzip
  ];

  shellHook = ''
    echo "Dev shell active. Run: dotnet restore && dotnet build"

    # Ensure wine64 is available in PATH by creating a local symlink if necessary.
    if ! command -v wine64 >/dev/null 2>&1; then
      mkdir -p .direnv/bin
      if [ ! -x .direnv/bin/wine64 ]; then
        ln -sf "$(command -v wine)" .direnv/bin/wine64 || true
      fi
      PATH="$PWD/.direnv/bin:$PATH"
      export PATH
    fi
  '';
}

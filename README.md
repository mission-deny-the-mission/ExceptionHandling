# ExceptionHandling — NixOS development environment

This repository is a small Windows Forms (.NET) project. The project targets `net8.0-windows` and uses Windows Forms, which is Windows-only.

This repository includes Nix dev environment files to help development on NixOS.

Files added
- `flake.nix` — a Nix flake devShell that provides `dotnet-sdk`, `mono`, `wine`, and helpers.
- `shell.nix` — a non-flake `nix-shell` variant providing the same tools.

Important notes and options

- Native GUI: Windows Forms is supported only on Windows. You cannot run the WinForms GUI natively on Linux.
- Build-only on Linux: You can still use the .NET SDK to restore and build the project, but some Windows-specific references may prevent running or executing designer-generated code.
- Run under Wine/Mono: As a workaround you can try running the built Windows binary under Wine or attempt running with Mono (requires retargeting to .NET Framework/Mono-compatible APIs). This is not guaranteed to fully work.
- Cross-platform port: The recommended long-term solution is to port the UI to a cross-platform framework (e.g., Avalonia). This may be the least fragile option.

How to use (flakes)

1. Enter the dev environment:

```fish
nix develop
```

2. Restore and build:

```fish
dotnet restore
dotnet build
```

3. If you need to run the Windows build under Wine (experimental):

```fish
dotnet publish -c Release -r win-x64 --self-contained false -o out
wine out/ExceptionHandling.exe
```

How to use (non-flakes)

```fish
nix-shell
dotnet restore
dotnet build
```

Direnv support

This repository includes a `.envrc` file that will automatically load the Nix dev shell when you `cd` into the project directory using `direnv`.

Steps to enable direnv (NixOS / Nix):

1. Install `direnv` and the nix integration (for example `nix-direnv`), for example via your system package manager or Nix:

```fish
# example (system dependent) - adapt if you use flakes/profiles
nix profile install nixpkgs#direnv nixpkgs#nix-direnv
```

2. Add the direnv hook to your shell if you haven't already. For fish, add this to your config.fish:

```fish
eval (direnv hook fish)
```

3. Allow the `.envrc` in this repository:

```fish
direnv allow
```

After that, direnv will automatically load the Nix dev shell when you enter the project directory (it prefers `flake.nix` and falls back to `shell.nix`). If you prefer not to use flakes, `shell.nix` will be used.


Recommendations

- If you want to support Linux users, consider porting the UI to a cross-platform UI toolkit such as Avalonia. It supports modern .NET and runs on Linux/Mac/Windows.
- If you only need to build and run tests, the dev shells above will provide `dotnet` and common tooling.

Limitations

- The current project is a Windows Forms app and will not run natively on Linux.
- The flake uses the `dotnet-sdk` attribute from `nixpkgs`; if your channel lacks that attribute, update `flake.nix` to point to a nixpkgs revision that provides .NET SDK 8 or adjust the attribute name.

If you'd like, I can:

- Add an automated script that attempts to publish and run the binary under Wine in the dev shell.
- Help port the project to Avalonia (I can scaffold the minimal UI and migrate code-behind logic).

Helper script

There's a helper script included that automates creating a 64-bit Wine prefix, publishing a self-contained (non-single-file) Windows build and running it under Wine:

```fish
# make it executable once
chmod +x scripts/setup-and-run-wine.sh

# then run inside the dev shell
bash scripts/setup-and-run-wine.sh
```

The script will back up any existing `~/.wine` to `~/.wine.bak.<timestamp>` and create a fresh 64-bit prefix, publish to `out-nofs/` and try to run the exe with `wine64`. If it fails the script saves a `wine-debug.log` with diagnostic output.

Project-local Wine prefix

By default the helper scripts now use a project-local Wine prefix at `./.wine` (inside the repository) so running this project won't interfere with any global `~/.wine` you may have. You can override this by setting the `WINEPREFIX` environment variable to another path.

Examples:

```fish
# use project-local prefix (default)
bash scripts/setup-and-run-wine.sh

# or explicitly set a custom prefix
WINEPREFIX=$HOME/.wine-project bash scripts/setup-and-run-wine.sh
```

{ pkgs }: pkgs.writeShellScriptBin "local-build" (builtins.readFile ./local-build.sh)

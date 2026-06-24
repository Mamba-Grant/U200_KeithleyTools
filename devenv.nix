{
  pkgs,
  lib,
  config,
  ...
}: {
  # https://devenv.sh/languages/
  languages = {
    python = {
      enable = true;
      venv = {
        enable = true;
        requirements = ''
          pyvisa
          pyvisa-py
          zeroconf
        '';
      };
    };
    lua.enable = true;
  };

  # See full reference at https://devenv.sh/reference/options/
}

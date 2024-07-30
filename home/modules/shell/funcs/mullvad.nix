{ pkgs, ... }: {
  evertras.home.shell.funcs = {
    mullvad-connect-select = {
      runtimeInputs = with pkgs; [ fzf ];
      body = ''
        cities=$(mullvad relay list | awk '/\sus/{print $1}' | awk -F- '{print $2}' | sort -u)
        city_code=$(fzf <<< "$cities")
        list=$(mullvad relay list | awk '/\sus-'"$city_code"'/{print $1}' | sort)
        relay=$(fzf <<< "$list")
        mullvad relay set location "$relay"
        mullvad connect
      '';
    };
  };
}

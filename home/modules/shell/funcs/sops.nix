{ pkgs, ... }: {
  evertras.home.shell.funcs = {
    sops-encrypt = {
      runtimeInputs = with pkgs; [ sops ];
      body = ''
        input_file="$1"

        base_name="''${input_file%%.*}"
        extension="''${input_file#*.}"
        output_file="''${base_name}.enc.''${extension}"

        sops -e "$input_file" > "$output_file"

        echo "Wrote to $output_file"
      '';
    };

    sops-decrypt = {
      runtimeInputs = with pkgs; [ sops ];
      body = ''
        input_file="$1"
        output_file="''${input_file/.enc/}"

        if [[ "$input_file" == "$output_file" ]]; then
          echo "$input_file does not have .enc"
          exit 1
        fi

        sops -e "$input_file" > "$output_file"

        echo "Wrote to $output_file"
      '';
    };
  };
}

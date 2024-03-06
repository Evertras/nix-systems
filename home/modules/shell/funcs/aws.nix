{ config, pkgs, ... }: {
  evertras.home.shell.funcs = {
    # Some AWS helpers
    aws-connect.body = ''
      aws ssm start-session --target "''${1}"
    '';

    aws-connect-name = {
      runtimeInputs = with pkgs; [ fzf ];
      body = ''
        filter=""

        if [ "$#" -eq 1 ]; then
          filter="$1"
        fi

        all_instances=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" |
          jq -r '.Reservations | .[] | .Instances | .[] | { Id: .InstanceId, Name: (.Tags[] | select(.Key == "Name") | .Value) } | [.Name, .Id] | @tsv' |
          sort |
          column -t)

        filtered=$(grep "$filter" <<< "$all_instances")

        if [ -z "$filtered" ]; then
          echo "No instances found that match filter: $filter"
          exit 1
        fi

        if [[ "$filtered" == *$'\n'* ]]; then
          filtered=$(${pkgs.fzf}/bin/fzf <<< "$filtered")
        fi

        target_name=$(awk '{print $1}' <<< "$filtered")
        target_aws_name=$(awk '{print $2}' <<< "$filtered")

        echo "Connecting to $target_name - $target_aws_name"

        aws ssm start-session --target "$target_aws_name"
      '';
    };

    aws-ec2-list.body = ''
      aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" |
        jq -r '.Reservations | .[] | .Instances | .[] | { Id: .InstanceId, Name: (.Tags[] | select(.Key == "Name") | .Value) } | [.Name, .Id] | @tsv' |
        sort |
        column -t
    '';

    aws-profiles.body = ''
      grep '\[profile' ~/.aws/config | awk '{print $2}' | tr -d ']'
    '';
  };
}

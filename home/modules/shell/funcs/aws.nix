{ pkgs, ... }: {
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
          jq -r '.Reservations | .[] | .Instances | .[] | { Id: .InstanceId, LaunchTime: .LaunchTime, Name: (.Tags[] | select(.Key == "Name") | .Value) } | [.Name, .Id, .LaunchTime] | @tsv' |
          sort |
          column -t)

        filtered=$(grep "$filter" <<< "$all_instances")

        if [ -z "$filtered" ]; then
          echo "No instances found that match filter: $filter"
          exit 1
        fi

        if [[ "$filtered" == *$'\n'* ]]; then
          filtered=$(fzf <<< "$filtered")
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

    aws-ec2-terminate = {
      runtimeInputs = with pkgs; [ gum ];
      body = ''
        todelete_raw=$(aws-ec2-list | gum choose)
        gum confirm "Deleting $todelete_raw" --affirmative="Delete" --negative="Cancel"
        instance_id=$(awk '{print $2}' <<< "$todelete_raw")
        aws ec2 terminate-instances --instance-ids "$instance_id"
      '';
    };

    aws-ec2-ami.body = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: aws-ec2-ami <name>" >&2
        exit 1
      fi

      instance_name="$1"

      if [[ $instance_name == i-* ]]; then
        instance_id="$instance_name"
      else
        instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" --query "Reservations[*].Instances[*].InstanceId" --output text)
        if [ -z "$instance_id" ]; then
          echo "Instance with name $instance_name not found." >&2
          exit 1
        fi
      fi

      aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[*].Instances[*].ImageId" --output text
    '';

    aws-profile-list.body = ''
      grep '\[profile' ~/.aws/config | awk '{print $2}' | tr -d ']'
    '';
  };
}

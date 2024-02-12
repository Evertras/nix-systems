{ config, ... }: {
  evertras.home.shell.funcs = {
    # Some AWS helpers
    aws-connect.body = ''
      aws ssm start-session --target "''${1}"
    '';

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

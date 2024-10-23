{ lib, nerdfonts, pkgs, ... }:

{
  evertras.home.shell.funcs = {
    # Using a local Nomad for now on purpose
    nomad-jobs-on-node.body = ''
      if [[ -z "$1" ]]; then
        echo "Requires search term"
        exit 1
      fi

      search="$1"

      # stderr so we can use this output in pipes
      echo "Searching for $search" >&2

      id=$(nomad node status -verbose | awk "/$search/ {print "'$1'"; exit }")

      echo "Node ID: $id" >&2

      jobs=$(nomad node status "$id" | awk '$6 == "running" && $3 != "monitor"')

      if [[ -z "$jobs" ]]; then
        echo "NONE"
      else
        echo "$jobs"
      fi
    '';

    nomad-nodes-by-ami.body = ''
      nodes=$(nomad node status | awk '$4 ~ /^i-/ && $NF == "ready" { print $4 }')

      for node in $nodes; do
        ami=$(aws-ec2-ami "$node")
        echo "$ami $node"
      done
    '';

    nomad-ineligible-by-name.body = ''
      if [[ -z "$1" ]]; then
        echo "Requires node name"
        exit 1
      fi

      name="$1"
      id=$(nomad node status | awk '$4 == "'"$name"'" { print $1 }')
      if [[ -z "$id" ]]; then
        echo "Failed to find node with name '$name'" >&2
        exit 1
      fi

      nomad node eligibility -disable "$id"
    '';

    nomad-cycle-node.body = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: nomad-cycle-node <instance-id>"
        exit 1
      fi

      function num_nodes() {
        nomad node status | awk '$4 ~ /^i-/ && $NF == "ready" { print $4 }' | wc -l
      }

      function node_is_running() {
        nomad node status |
          awk -v "c=1" '$4 == "'"$instance_id"'" && $NF == "ready" { c = 0 } END { exit c }'
      }

      instance_id="$1"

      starting_nodes=$(num_nodes)

      echo "Starting with $starting_nodes nodes"

      nomad-ineligible-by-name "$instance_id"

      while true; do
        jobs=$(nomad-jobs-on-node "$instance_id")

        if [[ "$jobs" == "NONE" ]]; then
          break
        else
          echo "Waiting due to jobs:"
          echo "$jobs"
        fi

        sleep 5
      done

      aws ec2 terminate-instances --instance-ids "$instance_id"

      while node_is_running; do
        echo "Node $instance_id still running, waiting..."
        sleep 5
      done

      while [[ "$starting_nodes" != "$(num_nodes)" ]]; do
        echo "Waiting for new node to come up..."
        sleep 5
      done

      echo "Cycle for $instance_id completed!"
    '';
  };
}

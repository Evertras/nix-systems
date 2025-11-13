{ ... }: {
  evertras.home.shell.funcs = {
    kubectl-show-open-tcp-connections.body = ''
      if [ $# -ne 1 ]; then
        echo "Usage: $0 <pod-name>"
        exit 1
      fi

      kubectl exec "$1" -- cat /proc/net/tcp | awk 'NR>1 {
        split($2,local,":"); split($3,remote,":");
        lip=sprintf("%d.%d.%d.%d",
          strtonum("0x" substr(local[1],7,2)),
          strtonum("0x" substr(local[1],5,2)),
          strtonum("0x" substr(local[1],3,2)),
          strtonum("0x" substr(local[1],1,2)));
        rip=sprintf("%d.%d.%d.%d",
          strtonum("0x" substr(remote[1],7,2)),
          strtonum("0x" substr(remote[1],5,2)),
          strtonum("0x" substr(remote[1],3,2)),
          strtonum("0x" substr(remote[1],1,2)));
        printf "Local: %-21s Remote: %-21s State: %s\n", lip ":" strtonum("0x" local[2]), rip ":" strtonum("0x" remote[2]), $4
      }'
    '';
  };
}

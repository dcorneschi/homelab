#!/bin/bash
# List all IPs for running Docker containers with network details

printf "%-25s %-18s %-12s %-18s %-18s %s\n" "CONTAINER" "IP" "PREFIX" "GATEWAY" "MAC" "NETWORK"
echo "--------------------------------------------------------------------------------------------------------------"

docker ps --format '{{.ID}} {{.Names}}' | while read -r id name; do
  docker inspect --format \
              '{{range $net, $conf := .NetworkSettings.Networks}}{{$conf.IPAddress}} {{$conf.IPPrefixLen}} {{$conf.Gateway}} {{$conf.MacAddress}} {{$net}}{{"\n"}}{{end}}' \
                  "$id" | while read -r ip prefix gw mac net; do
        [[ -n "$ip" ]] && printf "%-25s %-18s %-12s %-18s %-18s %s\n" "$name" "$ip" "/${prefix}" "$gw" "$mac" "$net"
          done
  done

  echo ""
  echo "=== Docker Networks ==="
  echo ""
  printf "%-20s %-10s %-20s %-10s %s\n" "NETWORK" "DRIVER" "SUBNET" "SCOPE" "INTERNAL"
  echo "-------------------------------------------------------------------------------"

docker network ls --format '{{.Name}}' | while read -r net; do
  docker network inspect --format \
              '{{.Name}} {{.Driver}} {{range .IPAM.Config}}{{.Subnet}}{{end}} {{.Scope}} {{.Internal}}' \
                  "$net" | while read -r nname driver subnet scope internal; do
        [[ "$internal" == "true" ]] && int="yes" || int="no"
              printf "%-20s %-10s %-20s %-10s %s\n" "$nname" "$driver" "${subnet:--}" "$scope" "$int"
                done
        done

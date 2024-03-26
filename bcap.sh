#!/bin/bash

trap "exit 1" TERM
export TOP_PID=$$
stop() { kill -s TERM $TOP_PID; }
error() { echo "Error: $1"; stop; }


# Docker helpers ##############################################################
dockerbasenstalled() {
  command -v docker > /dev/null 2>&1 && return 0 || return 1
}

deamon_running() {
  docker ps -q --filter "name=vnstat" | grep -q . && return 0 || return 1
}

launch_daemon() {
  docker run -d \
    --restart=unless-stopped \
    --network=host \
    -e HTTP_PORT=8685 \
    -v vnstat_data:/var/lib/vnstat \
    -v /etc/localtime:/etc/localtime:ro \
    -v /etc/timezone:/etc/timezone:ro \
    --name vnstat \
    vergoh/vnstat
}

# Helper functions ############################################################
iflist() { docker exec vnstat vnstat --iflist; }
list_interfaces() { iflist | awk '{for(i=3; i<=NF; i++) printf "%s ", $i}'; }

base() { docker exec vnstat vnstat -i $@; }

period_exceeded() {
  local interface=$1
  local type=$2
  local limit=$3
  local unit=$4
  local period=$5

  base $interface --alert 1 3 $period $type $limit $unit > /dev/null 2>&1
  local exit_code=$?
  return $exit_code
}

month_rx() { base $1 --oneline | awk -F';' '{print $9}'; }
month_tx() { base $1 --oneline | awk -F';' '{print $10}'; }
month_total() { base $1 --oneline | awk -F';' '{print $11}'; }

day_rx() { base $1 --oneline | awk -F';' '{print $4}'; }
day_tx() { base $1 --oneline | awk -F';' '{print $5}'; }
day_total() { base $1 --oneline | awk -F';' '{print $6}'; }

hour_last_line() { base $1 -h | tail -n 2 | awk 'NR==1'; }
hour_rx() { hour_last_line $1 | awk '{print $2 $3}'; }
hour_tx() { hour_last_line $1 | awk '{print $5 $6}'; }
hour_total() { hour_last_line $1 | awk '{print $8 $9}'; }

get_usage() {
  local type=$1
  local period=$2
  local interface=$3

  if [ $period == "m" ]; then
    command_str="month_$type"
  elif [ $period == "d" ]; then
    command_str="day_$type"
  else
    command_str="hour_$type"
  fi
  echo $(eval $command_str $interface)
}

# User Input ##################################################################
usage() {
  echo "Usage: $0"
  echo "  -h, --help: Display this help message"
  echo "  -i, --interfaces: List available interfaces. Can also provide" \
       " multiple interfaces to monitor, by separating them with a '+' sign." \
       " Alternatively, use 'all' to monitor all available interfaces"
  echo "  -t, --type: Type of limit to check. Can be rx, tx or total"
  echo "  -l, --limit: Limit to check"
  echo "  -u, --unit: Unit of the limit"
  echo "  -a, --exceeded_action: Action to take when limit is exceeded"
  echo "  -p, --period: Period to check the limit. Can be m, d or h for" \
       " month, day or hour respectively"
  echo "  -s, --sleep: Sleep time between checks in seconds (default: 60)"
  echo "  -f, --log_file: Optional log file to write the output"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) usage; exit 0 ;;
    -i|--interfaces) interfaces="$2"; shift ;;
    -t|--type) type="$2"; shift ;;
    -l|--limit) limit="$2"; shift ;;
    -u|--unit) unit="$2"; shift ;;
    -a|--exceeded_action) exceeded_action="$2"; shift ;;
    -p|--period) period="$2"; shift ;;
    -s|--sleep) sleep_time="$2"; shift ;;
    -f|--log_file) log_file="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# validate configuration
if [[ ! -z $log_file ]]; then
  if [ ! -f $log_file ]; then
    touch $log_file
  fi
  if [ ! -f $log_file ]; then
    error "Log file $log_file could not be created"
  fi
  exec > $log_file 2>&1
fi

if [[ -z $interfaces ]]; then
  error "Interfaces are required"
fi
if [[ $interfaces == "all" ]]; then
  interfaces=$(listbasenterfaces)
  interfaces=$(echo $interfaces | sed 's/ /+/g')
fi
available_interfaces=$(list_interfaces)
for interface in $(echo $interfaces | tr '+' ' '); do
  if ! echo $available_interfaces | grep -q $interface; then
    error_msg="Interface $interface is not available."
    error_msg+=" Available interfaces are: $available_interfaces"
    error "$error_msg"
  fi
done

if [[ ! $type =~ ^(rx|tx|total)$ ]]; then
  error "Type must be rx, tx or total. Got: $type"
fi

if [[ ! $unit =~ ^(B|KB|MB|GB|TB|PB|EB)$ ]]; then
  error "Unit must be B, KB, MB, GB, TB, PB or EB. Got: $unit"
fi

if [[ ! $period =~ ^(m|d|h)$ ]]; then
  error "Period must be m, d or h. Got: $period"
fi

if [[ -z $exceeded_action ]]; then
  error "Exceeded action is required"
fi

if [[ -z $sleep_time ]]; then
  sleep_time=1
fi

if ! [[ $sleep_time =~ ^[1-9][0-9]*$ ]]; then
  error "Sleep time must be a positive non zero number"
fi

# List configuration
echo "Interfaces: $interfaces"
echo "Type: $type"
echo "Limit: $limit"
echo "Unit: $unit"
echo "Exceeded action: $exceeded_action"

# Main ########################################################################
execute_exceeded_action() {
  echo "Limit exceeded, executing action: $exceeded_action"
  if [ -f "$exceeded_action" ]; then
    source $exceeded_action
  else
    eval "$exceeded_action"
  fi
}

log_current_bandwidth() {
  local interface=$1
  local type=$2
  local limit=$3
  local unit=$4
  local period=$5

  local rx=$(get_usage "rx" $period $interface)
  local tx=$(get_usage "tx" $period $interface)
  local total=$(get_usage "total" $period $interface)

  local rx_msg="rx: $rx"
  local tx_msg="tx: $tx"
  local total_msg="total: $total"

  if [ "$period" == "m" ]; then
    period_msg="month"
  elif [ "$period" == "d" ]; then
    period_msg="day"
  else
    period_msg="hour"
  fi

  if [ "$type" == "rx" ]; then
    rx_msg+=" (limit: $limit $unit per $period_msg)"
  elif [ "$type" == "tx" ]; then
    tx_msg+=" (limit: $limit $unit per $period_msg)"
  else
    total_msg+=" (limit: $limit $unit per $period_msg)"
  fi

  local datetime=$(date +"%Y-%m-%d %H:%M:%S")

  echo "Interfaces: $interfaces ($datetime)"
  echo "  $rx_msg"
  echo "  $tx_msg"
  echo "  $total_msg"
}

if ! dockerbasenstalled; then
  error "Docker is not installed"
fi

if ! deamon_running; then
  echo "Launching daemon..."
  launch_daemon
else
  echo "Daemon is already running"
fi

while true; do
  log_current_bandwidth $interfaces $type $limit $unit $period

  if ! period_exceeded $interfaces $type $limit $unit $period; then
    execute_exceeded_action
    stop
  fi

  sleep $sleep_time
done

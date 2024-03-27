# Bandwidth Cap

**Disclaimer:** This script is provided as is, and the author is not responsible for any issues that may arise from its use.
## Motivation

Some cloud providers offer a limited monthly bandwidth, and once this limit is exceeded, users are billed for extra bandwidth usage. This can be problematic, especially when these providers do not allow setting a bandwidth cap. For instance, if you set up a simple web page and it gets DDoS attacked, you could end up with a large bill for a small blog page. This is where a bandwidth cap can be useful. However, if you are doing something more serious, you might want to consider using a service like Cloudflare to protect against these sorts of attacks.

## Requirements

- Docker
- Bash

## Usage

```sh
./bcap.sh [OPTIONS]
```

## Options

- `-h, --help`: Display help message
- `-i, --interfaces`: List available interfaces or provide multiple interfaces to monitor, separated by a '+' sign. Alternatively, use 'all' to monitor all available interfaces.
- `-t, --type`: Type of limit to check. Can be rx (received), tx (transmitted), or total.
- `-l, --limit`: Limit to check.
- `-u, --unit`: Unit of the limit. Can be B, KB, MB, GB, TB, PB, or EB.
- `-a, --exceeded_action`: Action to take when limit is exceeded.
- `-p, --period`: Period to check the limit. Can be m (month), d (day), or h (hour).
- `-s, --sleep`: Optional sleep time between checks in seconds (default: 60).
- `-f, --log_file`: Optional log file to write the output.

## Example

```sh
./bcap.sh -i eth0 -t total -l 10 -u GB -a "echo 'Limit exceeded'" -p m -s 60
```

This command will monitor the total (tx + rx) bandwidth on the `eth0` interface, every 60 seconds. If the total bandwidth exceeds 10 GB in a month, it will echo "Limit exceeded".

## Example Action Script

This project includes an example script `example_action_script.sh` that can be run when the bandwidth limit is reached. In this example, the script will send an email using SendGrid, block all network traffic with `ufw`, and finally shut down the system. If you want to run this example, make sure to set the `SENDGRID_EMAIL_RECEIVER`, `SENDGRID_EMAIL_SENDER`, and `SENDGRID_API_KEY` environment variables. Lastly, provide it in the command:

```sh
./bcap.sh <all_other_options> -a <insert_path_to_file>/example_action_script.sh 
```

## Customizing vnstat settings

If you wish to change some of the settings of vnstat, such as the 'SaveInterval' for example, you can do so by editing the `vnstat.conf` file located in the same directory as the script. When launching, the script will copy this config file into the vnstat Docker container. The currently provided `vnstat.conf` is the default one, copied from [here](https://github.com/vergoh/vnstat/blob/master/cfg/vnstat.conf)

## Note

The script uses Docker to run a vnstat daemon. If the daemon is not running, the script will automatically start it.

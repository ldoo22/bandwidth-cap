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
- `-p, --period`: Period to check the limit until. Can be m, d, or h for month, day, or hour respectively. Upon each month, day, or hour, the total bandwidth usage is reset to 0.
- `-s, --sleep`: Optional sleep time between checks in seconds (default: 60).
- `-e, --echo_period`: Optional period to echo the current bandwidth usage, instead of echoing every vnstat check. Period defined in seconds (default: 0). Set to 0 to disable. Useful for not cluttering the logs.

## Examples

Listens to 'eth0' interface and checks the total bandwidth usage every 60 seconds. If the total bandwidth usage exceeds 10 GB in a month, it will echo "Limit exceeded".

```sh
./bcap.sh -i eth0 -t total -l 10 -u GB -a "echo 'Limit exceeded'" -p m -s 60
```

Listens to 'eth0' and 'docker0' interfaces and checks the rx bandwidth usage every 5 seconds. If the total bandwidth usage exceeds 100 GB in a month, it will run the script `example_action_script.sh`. Only log every 60 seconds

```sh
./bcap.sh --interfaces eth0+docker0 --type rx --limit 100 --limit 100 --unit GB --exceeded_action <path-to-your-script>/example_action_script.sh --period m --sleep 5 --echo_period 60
```

## Example Action Script

This project includes an example script `example_action_script.sh` that can be run when the bandwidth limit is reached. In this example, the script will send an email using SendGrid, stop all docker containers running, block all network traffic with `ufw` except for ssh connection, and finally shut down the system. If you want to run this example, make sure to set the `SENDGRID_EMAIL_RECEIVER`, `SENDGRID_EMAIL_SENDER`, and `SENDGRID_API_KEY` environment variables. Lastly, provide it in the command:

```sh
./bcap.sh <all_other_options> -a <insert_path_to_file>/example_action_script.sh 
```
Please be aware that if you configure this script to run at startup, such as with a crontab entry, you should exercise caution to avoid inadvertently locking yourself out of the system, as the script includes a system shutdown command. Here is an example of how you might set up a crontab entry:

```sh
@reboot sleep 300 && /path/to/bcap.sh <all_other_options> -a /path/to/example_action_script.sh
```

Note the 5 minute sleep before running the script to allow you time to edit the job in case of the limit being reached and you got locked out of the system.

## Customizing vnstat settings

If you wish to change some of the settings of vnstat, such as the 'SaveInterval' to increase the frequency of your checks, you can do so by editing the `vnstat.conf` file located in the same directory as the script. When launching, the script will copy this config file into the vnstat Docker container. The currently provided `vnstat.conf` is the default one, copied from [here](https://github.com/vergoh/vnstat/blob/master/cfg/vnstat.conf)

## Note

The script uses Docker to run a vnstat daemon. If the daemon is not running, the script will automatically start it.

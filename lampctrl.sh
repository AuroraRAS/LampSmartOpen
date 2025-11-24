#!/bin/bash
# lampctrl.sh
# This script wraps lampctrl and btmgmt to send BLE commands to the lamp.
# It reads the UUID from .env, converts it to an address, and generates
# advertising data using lampctrl.

#set -euo pipefail

LAMPCTRL="./build/lampctrl"
ENV_FILE=".env"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -i IDX        Bluetooth adapter index (default: 0)
  -d O,W        Dimming mode, orange and white values, e.g. -d 128,64
  -n            Night dimming mode
  -b N          Binding mode, e.g. -b 1
  -o 0|1        Lamp on/off, e.g. -o 1 (on), -o 0 (off)
  -h            Show this help message

Notes:
  * The lamp address is derived from the UUID stored in .env (key: "lu").
  * Only one command (-d, -n, -b, or -o) should be specified at a time.
EOF
}

IDX=0
declare -a lamp_args=()

# Parse script options
while getopts ":i:d:nb:o:h" opt; do
    case "$opt" in
        i)
            IDX="$OPTARG"
            ;;
        d)
            # Dimming, pass as-is to lampctrl: "-d ORANGE,WHITE"
            lamp_args=(-d "$OPTARG")
            ;;
        n)
            # Night dimming, no argument
            lamp_args=(-n)
            ;;
        b)
            # Binding, integer argument
            lamp_args=(-b "$OPTARG")
            ;;
        o)
            # On/Off, 0 or 1
            lamp_args=(-o "$OPTARG")
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
        \?)
            echo "Error: Unknown option -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

# Ensure exactly one operation is specified
if [ "${#lamp_args[@]}" -eq 0 ]; then
    echo "Error: No command specified. You must use one of -d, -n, -b, or -o." >&2
    usage
    exit 1
fi

# --- Derive address from UUID in .env ---

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found." >&2
    exit 1
fi

# Read raw UUID string from .env (JSON) key "lu"
uuid=$(jq -r '.lu' "$ENV_FILE")

if [ -z "$uuid" ] || [[ "$uuid" == "null" ]]; then
    echo 'Error: Key "lu" not found or empty in .env.' >&2
    exit 1
fi

# Example UUID: 89815eb1-27c7-500e-9d7f-d147a47ce477
# We need: "27c7-500e" -> "27c7500e" (hex) -> +1
hex=$(echo "$uuid" | cut -d- -f2-3 | tr -d -)

if ! [[ "$hex" =~ ^[0-9a-fA-F]+$ ]]; then
    echo "Error: Invalid hex segment extracted from UUID: $hex" >&2
    exit 1
fi

addr=$(printf "0x%08x\n" $(( 0x$hex + 1 )))

# --- Generate advertising data with lampctrl ---

if [ ! -x "$LAMPCTRL" ]; then
    echo "Error: lampctrl binary not found or not executable at: $LAMPCTRL" >&2
    exit 1
fi

# lampctrl prints '-u xxxx -u yyyy ...'
adv_data=$("$LAMPCTRL" -a "$addr" "${lamp_args[@]}")

# --- Control btmgmt to send advertising ---

sudo btmgmt --index "$IDX" power on
sudo btmgmt --index "$IDX" le on
sleep 0.1
sudo btmgmt --index "$IDX" clr-adv
sudo btmgmt --index "$IDX" add-adv -c -g $adv_data -D 2 1
sleep 0.1
sudo btmgmt --index "$IDX" clr-adv
sudo btmgmt --index "$IDX" le off


#!/bin/bash

SYSFS_DRM="/sys/class/drm"
DEBUGFS_DRM="/sys/kernel/debug/dri/0"

# --- Helper Functions ---

print_help() {
    echo "Usage: $(basename "$0") [COMMAND]"
    echo ""
    echo "Check for or force usage of Display Stream Compression (DSC)"
    echo "per DisplayPort link. Most functions require root."
    echo ""
    echo "Commands:"
    echo "  scan                        Scan all DP interfaces and check DSC usage"
    echo "  force enable  <interface>   Force enable DSC on some interface (e.g., DP-1)"
    echo "  force disable <interface>   Force disable DSC on some interface"
    echo "  force auto    <interface>   Revert to automatic DSC mode"
}

scan_interfaces() {
    echo "Scanning DisplayPort interfaces via Sysfs..."

    # Loop through all DP interfaces found in sysfs
    for dp_sys_dir in "$SYSFS_DRM"/card0-DP-*; do
        # Handle cases where no DP interfaces exist
        [ -e "$dp_sys_dir" ] || continue

        port_name=$(basename "$dp_sys_dir" | sed 's/card0-//')
        status_file="$dp_sys_dir/status"

        # Check if the port is physically connected/active
        if [ -f "$status_file" ] && [ "$(cat "$status_file")" = "connected" ]; then
            dsc_status="Unknown (Requires root/sudo to read debugfs)"

            # Map back to debugfs for DSC telemetry
            dsc_file="$DEBUGFS_DRM/$port_name/dsc_bits_per_pixel"
            if [ -r "$dsc_file" ]; then
                read -r dsc_bpp < "$dsc_file"

                if [[ -n "$dsc_bpp" && "$dsc_bpp" != "0" ]]; then
                    dsc_status="Enabled ($dsc_bpp bpp)"
                else
                    dsc_status="Disabled"
                fi
            fi

            echo -e "\e[32m[+]\e[0m $port_name: ACTIVE | DSC: $dsc_status"
        else
            echo -e "\e[31m[-]\e[0m $port_name: INACTIVE"
        fi
    done
}

force_interface() {
    local card="$DEBUGFS_DRM/$2"

    if [ "$EUID" -ne 0 ]; then
        echo "Error: 'force' actions require root privileges (run with sudo)." >&2
        exit 1
    fi

    if [ ! -d "$card" ]; then
        echo "Error: no interface $card" >&2
        exit 1
    fi

    case "$1" in
        enable)
            echo "Force enabling DSC for $2"
            echo "1" > "$card/dsc_clock_en"
            ;;
        disable)
            echo "Force disabling DSC for $2"
            echo "2" > "$card/dsc_clock_en"
            ;;
        auto)
            echo "Using DSC auto-detection for $2"
            echo "0" > "$card/dsc_clock_en"
            ;;
    esac
}

# --- Main Argument Parser ---

case "$1" in
    help|--help|-h)
        print_help
        exit 0
        ;;
    force)
        if [[ "$2" != "enable" && "$2" != "disable" && "$2" != "auto" ]] || [ -z "$3" ]; then
            echo "Error: Invalid force command syntax." >&2
            print_help
            exit 1
        fi
        force_interface "$2" "$3"
        ;;
    scan|"")
        # No arguments provided, default to scanning
        scan_interfaces
        ;;
    *)
        echo "Error: Unknown argument '$1'" >&2
        print_help
        exit 1
        ;;
esac

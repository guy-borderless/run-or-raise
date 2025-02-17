#!/bin/bash

# todo:
# - test
# - register from file
# - --help: explaining everything and usage completions
# - import from file
# install (aur, apt, fedora, script / with extension)
# readme + how to export shortcuts
# help finding wm_class / title
# show run-or-raise shortcuts from dconf (export to file)



usage() {
    echo "Usage: $0 --mode \"\" --command \"\" --wm_class \"\" --title \"\""
    exit 1
}

# Defaults
mode=""
command=""
wm_class=""
title=""

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            mode="$2"
            shift 2
        ;;
        --command)
            command="$2"
            shift 2
        ;;
        --wm_class)
            wm_class="$2"
            shift 2
        ;;
        --title)
            title="$2"
            shift 2
        ;;
        *)
            echo "Unknown option: $1"
            usage
        ;;
    esac
done

# Require at least command to be provided
if [[ -z $command ]]; then
    echo "Error: --command must be specified."
    usage
fi

# Construct the DBus argument in the form: mode,command,wm_class,title
dbus_arg="${mode},${command},${wm_class},${title}"

# Call the DBus method
gdbus call --session \
--dest org.gnome.Shell \
--object-path /org/gnome/Shell/Extensions/RunOrRaise \
--method org.gnome.Shell.Extensions.RunOrRaise.Call "${dbus_arg}"
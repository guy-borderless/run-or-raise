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
    cat <<EOF
Run-or-raise CLI interface

Usage: $0 [options]

Options:
  --mode      Optional. Special modes that modify behavior:
              - isolate-workspace: Switch windows on active workspace only
              - minimize-when-unfocused: Minimizes target when unfocusing
              - switch-back-when-focused: Switch back to previous window when focused
              - move-window-to-active-workspace: Move window to current workspace before focusing
              - center-mouse-to-focused-window: Centers mouse on newly focused window
              - always-run: Both runs command and raises window
              - run-only: Only runs command, never raises windows
              - register(N): Register current window with number N
              - raise(N): Raise window previously registered with number N
              - raise-or-register: Register window first time, raise it next time
              - raise-or-register(N): Like raise-or-register but with numbered slot
              - verbose: Show debug details via notify-send
              Multiple modes can be combined with colons, e.g. "raise-or-register:move-window-to-active-workspace"

  --command   Required. Either:
              - A command line instruction to spawn
              - Name of an application's .desktop file to activate

  --wm_class  Optional. Window class to match (case-sensitive)
              Can use regular expressions between slashes, e.g. "/Google-chrome$/"

  --title     Optional. Window title to match (case-sensitive)
              Can use regular expressions between slashes

If neither wm_class nor title is set, lowercase command is compared with lowercase window classes and titles.

Example:
  $0 --command firefox --wm_class Firefox
  $0 --mode "raise-or-register" --command "gnome-terminal"
  $0 --command chrome --wm_class "/Google-chrome$/" --title "Gmail"
EOF
    exit 1
}

# Defaults
mode=""
command=""
wm_class=""
title=""

# Valid modes
valid_modes=(
    "isolate-workspace"
    "minimize-when-unfocused"
    "switch-back-when-focused"
    "move-window-to-active-workspace"
    "center-mouse-to-focused-window"
    "always-run"
    "run-only"
    "verbose"
)

# Validate mode
validate_mode() {
    local mode_to_check="$1"
    # Split combined modes on colon
    IFS=':' read -ra MODES <<<"$mode_to_check"

    for single_mode in "${MODES[@]}"; do
        # Strip any parentheses and numbers for register/raise modes
        base_mode=$(echo "$single_mode" | sed 's/([0-9]\+)//')

        # Check if it's a register/raise mode
        if [[ "$base_mode" =~ ^(register|raise|raise-or-register)$ ]]; then
            # Verify the number format if present
            if [[ "$single_mode" =~ ^[^(]+\([0-9]+\)$ ]]; then
                continue
            elif [[ "$single_mode" == "$base_mode" ]]; then
                continue
            else
                echo "Error: Invalid format for mode '$single_mode'. Should be '$base_mode' or '$base_mode(N)' where N is a number."
                exit 1
            fi
        fi

        # Check against valid modes list
        local valid=0
        for valid_mode in "${valid_modes[@]}"; do
            if [[ "$single_mode" == "$valid_mode" ]]; then
                valid=1
                break
            fi
        done

        if [[ $valid -eq 0 ]]; then
            echo "Error: Invalid mode '$single_mode'"
            echo "Valid modes are:"
            printf -- "- %s\n" "${valid_modes[@]}"
            echo "- register(N)"
            echo "- raise(N)"
            echo "- raise-or-register"
            echo "- raise-or-register(N)"
            exit 1
        fi
    done
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --mode)
        mode="$2"
        if [[ -n "$mode" ]]; then
            validate_mode "$mode"
        fi
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

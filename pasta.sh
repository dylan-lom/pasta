#!/usr/bin/env sh
#
# pasta: simple ssh pastebin client
# author: Dylan Lom <djl@dylanlom.com>

debugopts() {
    printf "==== Arguments ====\n"
    printf "concat: %s\n" "$concat"
    printf "get: %s\n" "$get"
    printf "png: %s\n" "$png"
    printf "mirror: %s\n" "$mirror"
    printf "xclip: %s\n" "$xclip"
    printf "name: %s\n" "$name"
    printf "==== Options ======\n"
    printf "sshdomain: %s\n" "$sshdomain"
    printf "destpath: %s\n" "$destpath"
    printf "destdomain: %s\n" "$destdomain"
    printf "randomlen: %s\n" "$randomlen"
    printf "hiderandom: %s\n" "$hiderandom"
}

confirm() {
    test -n "$1" && msg="$1" || msg="Confirm"
    printf "%s [Y/n]: " "$msg"
    read resp
    test -z "$resp" -o "$resp" = "Y" -o "$resp" = "y" \
        && return 0 \
        || return 1
}

truthy() {
    test -z "$1" -o "$1" = "false" \
        && return 1 \
        || return 0
}

configpath="$HOME/.config/pastarc"
argv0="$0"

# TODO: There are a number of not-great things about the config setup at the moment
#       - No default values
#       - No validation of values (ie. a way to test options without overwriting)
#       - No guided way to only modify some of the options
#       - Seperation between setup and firsttimesetup and checkconfig (ie. multiple fn calls needed)

# checkconfig name value
checkconfig() {
    if [ -z "$2" ]; then
        echo "Invalid option '$1' in config file $configpath. Please manually update the config file, or remove it and re-run $argv0 for a guided setup." > /dev/stderr
        exit 1
    fi
}

setup() {
    printf "SSH Domain (e.g. user@ssh.example.com): "; read sshdomain
    printf "Remote destination (e.g. /var/www/paste.example.com): "; read destpath
    printf "Remote URL (e.g. http://paste.example.com): "; read destdomain
    printf "Random paste name length (e.g. 5): "; read randomlen
    confirm "Hide random pastes (prefixes names with '.' character)" && hiderandom="true" || hiderandom="false"

    printf "sshdomain='$sshdomain'\ndestpath='$destpath'\ndestdomain='$destdomain'\nrandomlen='$randomlen'\nhiderandom='$hiderandom'\n" > "$configpath"
}

firsttimesetup() {
    echo "Configuration file ($configpath) not found!"
    confirm "Create?" || exit
    test -d ~/.config || mkdir -p ~/.config
    setup
}

isinstalled() {
    command -v "$1" > /dev/null \
        && return 0 \
        || (echo "ERROR: Executable '$1' not found!"; return 1)
}

usage() {
    echo "usage: $argv0 [-c|-g|-m <url>|-p] [-x] [filename]" > /dev/stderr
    exit 1
}

test -f "$configpath" \
    && . "$configpath" \
    || firsttimesetup

# Make sure all config is correct
checkconfig sshdomain "$sshdomain"
checkconfig destpath "$destpath"
checkconfig destdomain "$destdomain"
checkconfig randomlen "$randomlen"
checkconfig hiderandom "$hiderandom"

while getopts "cgm:px" opt; do
    case "$opt" in
        c) concat=true ;;
        g) get=true ;;
        m) mirror="$OPTARG" ;;
        p) png=true ;;
        x) xclip=true ;;
        *) usage ;;
    esac
done

# shift past all options to the [filename] part of args
shift "$(($OPTIND-1))"
if [ "$#" = 0 ]; then
    # Filename was not provided, generate a random one -- making sure not to
    # accidentally change path with a '/'
    name="$(base64 < /dev/urandom | head "-c$randomlen" | tr '/' 'A')"
    truthy "$hiderandom" && name=".$name"
    truthy "$png" && name="$name.png"
else
    name="$1"
fi

[ -z "$name" ] && usage


if truthy "$xclip"; then
    isinstalled xclip || exit 1

   echo "$destdomain/$name" | \
       tr -d '\n' | \
       xclip -selection clipboard
fi

if truthy "$get"; then
    curl "$destdomain/$name"
    exit
fi

if truthy "$concat"; then
   ssh "$sshdomain" "cat >> $destpath/$name"
elif truthy "$mirror"; then
   ssh "$sshdomain" "command -v curl > /dev/null \
        && curl -Lso \"$destpath/$name\" \"$mirror\" \
        || wget -qO \"$destpath/$name\" \"$mirror\""
else
    isinstalled import || exit 1
    (truthy "$png" && import png:- || cat) | \
        ssh "$sshdomain" "cat > \"$destpath/$name\""
fi

echo "$destdomain/$name"


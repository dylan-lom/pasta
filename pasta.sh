#!/usr/bin/env sh
#
# pasta: simple ssh pastebin client
# author: Dylan Lom <djl@dylanlom.com>

configpath="$HOME/.config/pastarc"
argv0="$0"

setup() {
    printf "SSH Domain: "; read sshdomain
    printf "Remote destination: "; read destpath
    printf "Remote URL: "; read destdomain
    printf "sshdomain='$sshdomain'\ndestpath='$destpath'\ndestdomain='$destdomain'\n" > "$configpath"
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
	echo "usage: $argv0 [-p|-c|-g] [-x] [filename]" > /dev/stderr
	exit 1
}

test -f "$configpath" \
    && . "$configpath" \
    || firsttimesetup

while getopts "pcgx" opt; do
    case "$opt" in
        p) png=true ;;
        c) concat=true ;;
        g) get=true ;;
        x) xclip=true ;;
        *) usage ;;
    esac
done

# shift past all options to the [filename] part of args
shift "$(($OPTIND-1))"
if [ "$#" = 0 ]; then
    # Filename was not provided, generate a random one
    name="$(base64 < /dev/urandom | head -c10)"
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
else
    isinstalled import || exit 1
    (truthy "$png" && import png:- || cat) | \
        ssh "$sshdomain" "cat > $destpath/$name"
fi

echo "$destdomain/$name"


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

echon() {
    echo "$@" | tr -d '\n'
}

configpath="$HOME/.config/pastarc"
argv0="$0"

reconfigure() {
    opt="$1"
    desc="$2"
    val=`eval echo '$'$opt`

    echon "$desc"
    test -z "$val" || echon " [$val]"
    echon ": "

    read "$opt"
    newval=`eval echo '$'$opt`
    if [ -z $newval ]; then
        eval $opt=$val
    fi
}

setup() {
    reconfigure "sshdomain" "SSH Domain"
    reconfigure "destpath" "Remote destination"
    reconfigure "destdomain" "Hosted content location"
    reconfigure "randomlen" "Random filename length"
    confirm "Hide random pastes (prefixes names with '.' character)" \
        && hiderandom="true" \
        || hiderandom="false"

    cat << EOF > "$configpath"
    sshdomain="$sshdomain"
    destpath="$destpath"
    destdomain="$destdomain"
    randomlen="$randomlen"
    hiderandom="$hiderandom"
EOF
}

isinstalled() {
    command -v "$1" > /dev/null \
        && return 0 \
        || (echo "ERROR: Executable '$1' not found!"; return 1)
}

usage() {
    echo "usage: $argv0 [-c|-g|-m <url>|-p|-R] [-x] [filename]" > /dev/stderr
    exit 1
}

if [ -f "$configpath" ]; then
    . "$configpath"
fi

# Validate configuration
for opt in sshdomain destpath destdomain randomlen hiderandom; do
    if [ -z `eval echo '$'$opt` ]; then
        echo "Invalid configuration file ($configpath), please follow prompts to fix, and re-run command!" > /dev/stderr
        setup
        exit 1
    fi
done

while getopts "cgm:pxR" opt; do
    case "$opt" in
        c) concat=true ;;
        g) get=true ;;
        m) mirror="$OPTARG" ;;
        p) png=true ;;
        x) xclip=true ;;
        R) setup; exit 0 ;;
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


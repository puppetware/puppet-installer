#!/usr/bin/env bash
#
# Ryan Skoblenick <ryan@skoblenick.com>
# 2013.10.07
#

# Prompt for sudo password upfront
sudo -v

os_family() {
    case $( uname -s ) in
        Darwin)
            echo "Darwin"
        ;;
        Linux)
            case $( lsb_release -si ) in
                Debian|Ubuntu)
                    echo "Debian"
                ;;
                RedHat|CentOS)
                    echo "RedHat"
                ;;
                *)
                echo "Unsupported Linux distribution."
                exit 9
            esac
        ;;
        *)
            echo "Unsupported operating system."
            exit 9
    esac
}

install_deps() {
    local config=${1}

    install_jq

    if [ ! -f "${config}" ]; then
        echo 'No config found.'
        exit 1
    fi

    if [ $( os_family ) == "Darwin" ]; then

        packages=($(cat "${config}" | jq -r -c '.dependencies[].source[] | select(.platform == "Darwin").uri'))

        for package in "${packages[@]}"
        do
            # Extract the filename from the URL
            filename=$( basename ${package} )

            # Download
            curl -L -o "/tmp/${filename}" ${package}


            # Mount disk image
            hdiutil attach -nobrowse -readonly -noidme "/tmp/${filename}" -mountpoint "/Volumes/${filename}"

            # Install
            pkg=$( ls "/Volumes/${filename}" | grep '.pkg' )
            sudo installer -pkg "/Volumes/${filename}/${pkg}" -target /

            # Unmount disk image
            hdiutil detach "/Volumes/${filename}"

            # Clean up
            rm -f "/tmp/${filename}"
        done

        # Ensure puppet group is present
        sudo puppet resource group puppet ensure=present

        # Ensure puppet user is present
        sudo puppet resource user puppet ensure=present gid=puppet shell="/sbin/nologin"

        # Hide the puppet user; otherwise it will appear on the login screen
        sudo defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add puppet
    else
        echo "Feature not implemented"
        exit 2
    fi
}

install_jq() {
    # Install Command Line JSON parser
    # http://stedolan.github.io/jq/
    local os=''

    if [ ! -f /usr/bin/jq ]; then
        if [ $( os_family ) == "Darwin" ]; then
            os='osx64'
        else
            os='linux64'
        fi
        sudo curl -L -o '/usr/bin/jq' "http://stedolan.github.io/jq/download/${os}/jq"
        sudo chmod a+x '/usr/bin/jq'
        echo 'Command Line JSON parser installed...'
    else
        echo 'Command Line JSON parser already installed... skipping...'
    fi
}

usage() {
    echo "Usage: $0 [-c]" 1>&2; exit 1;
}


# Parse getopts
optspec=":hc-:"

while getopts "${optspec}" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                config)
                    echo "Feature not implemented"
                    exit 2
                    ;;
            esac;;
        c)
            val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
            #echo "Parsing option: '-${optchar}', value: '${val}' " >&2
            install_deps ${val}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

exit 0
#!/bin/bash -e 

_help() {
    cat <<EOF
gen-dnsmasq.sh - Generate dnsmasq.conf based on list of PXE roms
Usage:
  gen-dnsmasq.sh [OPTIONS]
Options:
  -h --help    Show this help menu
  -r --romdir  The directory to read the PXE rom filenames from
                 (default is ../out)
  -o --out     The file location to save the dnsmasq.conf file
                 (default is ../out/dnsmasq.conf)
  --dhcp-ip    The IP address of the DHCP server
                 (default is <dhcp_ipaddr>)
  --tftp-ip    The IP address of the TFTP server
                 (default is <tftp_ipaddr>)
Help:
  For help using this tool, please open an issue on the GitHub repository:
  https://github.com/nderjung/pxe-roms
EOF
}

# Default program parameters
DIR=$(dirname $0)
ROMDIR=$DIR/../out
OUT=$DIR/../out/dnsmasq.conf
DHCPIP="<dhcp_ipaddr>"
TFTPIP="<tftp_ipaddr>"
HELP=n

# Parse arguments
for i in "$@"; do
  case $i in
    -r=*|--romdir=*)
      ROMDIR="${i#*=}"
      shift
      ;;
    -o=*|--out=*)
      OUT="${i#*=}"
      shift
      ;;
    --dhcp-ip=*)
      DHCPIP="${i#*=}"
      shift
      ;;
    --tftp-ip=*)
      TFTPIP="${i#*=}"
      shift
      ;;
    -h|--help)
      HELP=y
      shift
      ;;
    *)
      ;;
  esac
done

# Show help menu if requested
if [[ $HELP == 'y' ]]; then
    _help
    exit
fi

# Does the dnsmasq.conf file exist already?
if [[ -f $OUT ]]; then
  while true; do
    read -p "$OUT already exists.  Would you like to append or remove? [a/r]: " REPLY
    case $REPLY in
      [A|a|append]*)
        break
        ;;
      [R|r|replace]*) 
        rm $OUT
        break
        ;;
      *)
        ;;
    esac
  done
fi

# Only find files that start with 'pxelinux.' and use the power of unix pipes to
# sanitize the file names
ROMS=($(find $ROMDIR -type f -name "pxelinux.*" \
     | xargs -I{} echo {} \
     | sed "s#$ROMDIR##g" \
     | sed "s#/##g"))

# No ROMS? No business.
if [[ -z $ROMS ]]; then
  echo
  echo " <!> No ROMS found!  Cannot make dnsmasq.conf!  Aborting!"
  echo
  exit 1
fi

# Print out a usable config
for ROM in "${ROMS[@]}"; do
  TAG=$(echo $ROM | sed "s/pxelinux.//g")
  cat <<EOF >> $OUT
dhcp-boot=tag:$TAG, $ROM, $DHCPIP, $TFTPIP
EOF
  done

cat <<EOF >> $OUT

# Define a new DHCP option for retrieving the preseed URL,
# and define the specific preseed URLs for the relevant tags.
# ${preseed-url} will be replaced in relevant PXE config files
# dhcp-option=244, preseed-url
# dhcp-option=tag:<tag>, 244, "https://pub.nderjung.net/preseeds/ubuntu.trusty64.cfg"

# Set device-specific ROMs (adjust accordingly)
# dhcp-host=<hwaddr>, set:<tag>, <ipaddr>, <hostname>
EOF

cat $OUT
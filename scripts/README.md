# Helpful scripts

## `gen-dnsmasq.sh`

```bash
$ ./gen-dnsmasq.sh --help
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
```
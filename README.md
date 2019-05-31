# PXE ROM Builder

This is an all-in-one solution for self-hosting and managing [PXE](https://en.wikipedia.org/wiki/Preboot_Execution_Environment) ROMs, Linux
kernels and kernel preseeds.  Use the provided [`Makefile`](/Makefile) to build
custom PXE ROMs which point to a self-hosted [TFTP](https://help.ubuntu.com/community/TFTP) and HTTP server.

## Usage

1. Build the PXE ROMS,

   1. Build on native host simply by calling `make`.

   2. Or, build use the provided [`Dockerfile`](Dockerfile):
      ```bash
      $ make container
      $ docker run -it --rm \
        -v $(pwd)/out:/pxe-roms/out:rw \
        nderjung.net/pxe-roms:latest \
        make
      ```

      You can also specify specific roms, e.g. `make ubuntu/xenial64` or create
      your own by adding them into the [`config/custom`](config/custom) directory.

2. Set up a TFTP server to host the PXE ROMs,

   1. Set the hostname, e.g. `tftp`.

   2. Expose port `udp/69`.

   3. Install and run the TFTP server:

      1. You can use the built in TFTP server:
         ```bash
         $ DOCKER_TARGET=serve make container
         $ docker run -it --rm -p 69:69/udp nderjung.net/pxe-roms:latest
         ```

      2. Or, install one via package manager, e.g:
         ```bash
         # apt install -y tftpd-hpa tftp-hpa xinetd
         ```
         
         Then copy the contents from `out/` to the TFTP server:
         ```
         $ scp -r out/ 10.1.0.69:/srv/tftp
         ```

3. (Optional) Set up a HTTP server to host preseeds and kernels.  A pre-built
   server is included in the [`docker-compose.yml`](docker-compose.yml) file as an
   example.  In the rest of this tutorial, I will be referring to
   [`https://pub.nderjung.net`](https://pub.nderjung.net) as the self-hosted HTTP
   server.

4. Set up a DHCP server to indicate to the network bootable server a ROM is
   available,

   1. Set the hostname, e.g. `router`.

   2. Edit `/etc/dnsmasq.conf` and be sure to replace `router` and `tftp` with
      the IP addresses relevant to your network:
      ```
      # Define PXE ROMs as seperate tags (from `out/`)
      dhcp-boot=tag:ubuntu-trusty64-serial, pxelinux.ubuntu-trusty64-serial, router, tftp
      dhcp-boot=tag:ubuntu-trusty64-preseed, pxelinux.ubuntu-trusty64-preseed, router, tftp
      dhcp-boot=tag:ubuntu-xenial64-serial, pxelinux.ubuntu-xenial64-serial, router, tftp
      dhcp-boot=tag:ubuntu-xenial64-preseed, pxelinux.ubuntu-xenial64-preseed, router, tftp

      # (Optional from 3.) Define a new DHCP option for retrieving the preseed URL,
      # and define the specific preseed URLs for the relevant tags.
      # ${preseed-url} will be replaced in relevant PXE config files
      dhcp-option=244,preseed-url
      dhcp-option=tag:ubuntu-trusty64-preseed,244,"https://pub.nderjung.net/preseeds/ubuntu.trusty64.cfg"
      dhcp-option=tag:ubuntu-xenial64-preseed,244,"https://pub.nderjung.net/preseeds/ubuntu.xenial64.cfg"
      
      # Set device-specific ROMs (adjust accordingly)
      dhcp-host=<hwaddr>, set:ubuntu-trusty64-serial, <ipaddr>, <hostname>
      dhcp-host=<hwaddr>, set:ubuntu-xenial64-preseed, <ipaddr>, <hostname>
      ```

   3. Restart the service:
      ```
      # /etc/init.d/dnsmasq restart
      ```

5. Reboot <hostname> and viola!

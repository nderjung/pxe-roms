# PXE ROM Builder

This is an all-in-one solution for self-hosting and managing PXE ROMs, Linux
kernels and kernel preseeds.  Use the provided [`Makefile`](/Makefile) to build
custom PXE ROMs which point to a self-hosted TFTP and HTTP server.

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

   1. Define a static IP, e.g. `10.1.0.69`.

   2. Set the hostname, e.g. `tftp`.

   3. Expose port `udp/69`.

   4. Install and run the TFTP server:

      1. You can use the built in TFTP server:
         ```bash
         $ DOCKER_TARGET=serve make container
         $ docker run -it --rm -p 69:69/udp nderjung.net/pxe-roms:latest
         ```

      2. Or, install [`tftp-hpa`]() manually, e.g:
         ```bash
         # apt install -y tftpd-hpa tftp-hpa xinetd
         ```
         Then copy the contents from `out/` to `10.1.0.69:/srv/tftp`. 

3. Set up a HTTP server to host preseeds and kernels.  A pre-built server is
   included in the [`docker-compose.yml`](docker-compose.yml) file as an
   example.  In the rest of this tutorial, I will be referring to
   [`https://pub.nderjung.net`](https://pub.nderjung.net) as the HTTP server.

4. Set up a DHCP server to indicate to the network bootable server a ROM is
   available,

   1. Define a static IP, e.g. `10.1.0.1`. 

   2. Set the hostname, e.g. `router`.

   3. Set up `/etc/dnsmasq.conf`:


      ```
      # Define pxelinux ROMs as seperate tags
      dhcp-boot=tag:ubuntu-trusty64,pxelinux.ubuntu-trusty64
      dhcp-boot=tag:ubuntu-xenial64,pxelinux.ubuntu-xenial64

      # Define remote tftp server
      dhcp-option=option:tftp-server,10.1.0.69

      # Define remote http server
      dhcp-option=option:http-server,https://pub.nderjung.net
      
      # Set device-specific ROMs
      dhcp-host=<hwaddr>,set:ubuntu-xenial64,<ipaddr>,<hostname>
      ```

4. Reboot <hostname> and viola!

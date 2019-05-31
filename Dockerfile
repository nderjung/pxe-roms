FROM alpine:3.9 AS build

WORKDIR /pxe-roms
COPY . /pxe-roms

RUN apk --no-cache add \
      alpine-sdk \
      perl \
      xz-dev \
 && make

FROM alpine:3.9 AS serve

RUN apk --no-cache add \
      tftp-hpa

COPY --from=build /pxe-roms/out /var/tftpboot

EXPOSE 69/udp

ENTRYPOINT ["in.tftpd"]
CMD ["-L", "--secure", "/var/tftpboot"]

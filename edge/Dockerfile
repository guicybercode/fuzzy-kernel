FROM zig:0.11-alpine AS builder

WORKDIR /app

COPY build.zig .
COPY config ./config
COPY src ./src

RUN zig build -Dtarget=arm-linux-musleabihf -Drelease-safe

FROM alpine:latest

RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=builder /app/zig-out/bin/microkernel-edge .

ENV DEVICE_ID=device-001
ENV MQTT_BROKER_HOST=localhost
ENV MQTT_BROKER_PORT=1883
ENV MQTT_USE_TLS=false

CMD ["./microkernel-edge"]


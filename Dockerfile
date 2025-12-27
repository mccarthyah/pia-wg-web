FROM golang:1.22-alpine AS builder
WORKDIR /build

RUN apk add --no-cache git ca-certificates

# Clone upstream pia-wg-config
RUN git clone https://github.com/kylegrantlucas/pia-wg-config.git

# Copy web server
COPY main.go .
COPY templates ./templates

# Build pia-wg-config
WORKDIR /build/pia-wg-config
RUN go build -o /build/pia-wg-config-bin

# Build web server
WORKDIR /build
RUN go build -o server main.go


FROM alpine:3.20
WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /build/server /app/server
COPY --from=builder /build/pia-wg-config-bin /app/pia-wg-config
COPY --from=builder /build/templates /app/templates

EXPOSE 8080
CMD ["./server"]

FROM golang:1.22-alpine AS builder

WORKDIR /build

# Copy web server
COPY main.go .
COPY templates ./templates

# Copy upstream repo (subtree)
COPY vendor/pia-wg-config ./pia-wg-config

# Build pia-wg-config
WORKDIR /build/pia-wg-config
RUN go build -o /build/pia-wg-config-bin

# Build web server
WORKDIR /build
RUN go build -o server main.go


# -------- Runtime image --------
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /build/server /app/server
COPY --from=builder /build/pia-wg-config-bin /app/pia-wg-config
COPY --from=builder /build/templates /app/templates

EXPOSE 8080
CMD ["./server"]

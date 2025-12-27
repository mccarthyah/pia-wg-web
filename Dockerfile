# ===== Builder Stage =====
FROM golang:1.25-alpine AS builder

WORKDIR /build

# Install git and certificates for building
RUN apk add --no-cache git ca-certificates

# Clone upstream pia-wg-config
RUN git clone https://github.com/kylegrantlucas/pia-wg-config.git /build/pia-wg-config

# Build pia-wg-config binary
WORKDIR /build/pia-wg-config
RUN go mod tidy
RUN go build -o /build/pia-wg-config-bin

# Copy web server source
WORKDIR /build
COPY main.go .
COPY templates ./templates

# Build web server
RUN go build -o server main.go


# ===== Runtime Stage =====
FROM alpine:3.20

WORKDIR /app

# Required for Go TLS/certs
RUN apk add --no-cache ca-certificates

# Copy binaries and templates from builder
COPY --from=builder /build/server /app/server
COPY --from=builder /build/pia-wg-config-bin /app/pia-wg-config
COPY --from=builder /build/templates /app/templates

# Ensure binaries are executable
RUN chmod +x /app/server /app/pia-wg-config

# Expose container port
EXPOSE 8080

# Run server
CMD ["./server"]
# ===== Builder Stage =====
FROM golang:1.25-alpine AS builder

WORKDIR /build

RUN apk add --no-cache git ca-certificates

# Clone pia-wg-config
RUN git clone https://github.com/kylegrantlucas/pia-wg-config.git /build/pia-wg-config

WORKDIR /build/pia-wg-config
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o /build/pia-wg-config-bin

# Copy server source
WORKDIR /build
COPY main.go .
COPY templates ./templates
RUN CGO_ENABLED=0 go build -o /build/server main.go

# ===== Runtime Stage =====
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /build/server /app/server
COPY --from=builder /build/pia-wg-config-bin /app/pia-wg-config
COPY --from=builder /build/templates /app/templates

RUN chmod +x /app/server /app/pia-wg-config

EXPOSE 8080

CMD ["./server"]
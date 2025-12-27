# ===== Builder Stage =====
FROM golang:1.25-alpine AS builder

WORKDIR /build

RUN apk add --no-cache git ca-certificates

# --- Clone upstream pia-wg-config ---
RUN git clone https://github.com/kylegrantlucas/pia-wg-config.git /build/pia-wg-config

# --- Build pia-wg-config binary ---
WORKDIR /build/pia-wg-config
RUN go mod tidy
RUN go build -o /build/pia-wg-config-bin

# --- Copy web server source ---
WORKDIR /build
COPY main.go .
COPY templates ./templates

# --- Build web server ---
RUN go build -o server main.go


# ===== Runtime Stage =====
FROM alpine:3.20

WORKDIR /app

RUN apk add --no-cache ca-certificates

# Copy binaries and templates
COPY --from=builder /build/server /app/server
COPY --from=builder /build/pia-wg-config-bin /app/pia-wg-config
COPY --from=builder /build/templates /app/templates

EXPOSE 8080
CMD ["./server"]

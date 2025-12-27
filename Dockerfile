FROM golang:1.22-alpine

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY pia-wg-config /app/pia-wg-config
COPY main.go /app/
COPY templates /app/templates

RUN chmod +x /app/pia-wg-config
RUN go build -o server main.go

EXPOSE 8080

CMD ["./server"]

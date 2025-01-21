FROM golang:1.21 AS builder

WORKDIR /app

COPY main.go go.mod .

RUN CGO_ENABLED=0 GOOS=linux go build -o main . 

FROM alpine:latest

WORKDIR /

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]

# docker build . -f Dockerfile -t simplewebapp
# docker run -p8080:8080 -it simplewebapp
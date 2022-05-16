# Step 1: Modules caching
FROM golang:1.17.1-alpine3.14 as modules
# COPY <all> <the> <things> <last-arg-is-destination>
COPY go.mod go.sum /modules/
WORKDIR /modules
RUN go mod download

# Step 2: Builder
FROM golang:1.17.1-alpine3.14 as builder
COPY --from=modules /go/pkg /go/pkg
COPY . /app
WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -tags migrate -o /bin/app ./cmd/app
# go build [-o output] [build flags] [packages]

# Step 3: Final
FROM scratch
COPY --from=builder /app/config /config
COPY --from=builder /app/migrations /migrations
COPY --from=builder /bin/app /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
CMD ["/app"]

# 可以参考Dockerfile多From用法
# 最后生成的镜像，仍以最后一条 FROM 为准，之前的 FROM 会被抛弃
# 每一条 FROM 指令都是一个构建阶段，多条 FROM 就是多阶段构建，虽然最后生成的镜像只能是最后一个阶段的结果，但是，能够将前置阶段中的文件拷贝到后边的阶段中，这就是多阶段构建的最大意义。
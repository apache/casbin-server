FROM golang:1.27 AS BACK

RUN apt-get update && \
    apt-get -y install unzip build-essential autoconf libtool

WORKDIR /go/src
COPY . .

# Install protobuf from source
RUN curl -LjO https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.17.3.zip && \
    unzip v3.17.3.zip && \
    cd protobuf-3.17.3 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    make clean && \
    cd .. && \
    rm -r protobuf-3.17.3 && \
    rm v3.17.3.zip

# Go environment variable to enable Go modules
ARG TARGETOS
ARG TARGETARCH
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH}

# Download dependencies
RUN go mod download

# Install protoc-gen-go
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0

# Copy the source and generate the .proto file
ADD . /go/src/github.com/casbin/casbin-server
WORKDIR $GOPATH/src/github.com/casbin/casbin-server
RUN protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=require_unimplemented_servers=false \
    --go-grpc_opt=paths=source_relative proto/casbin.proto

# Install app
RUN go install .

RUN cd /go/src && go build -o casbin-server

FROM alpine:latest as STANDARD
WORKDIR /app
COPY --from=BACK /go/src/casbin-server /app/
ENTRYPOINT ./casbin-server

EXPOSE 50051

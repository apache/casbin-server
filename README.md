Casbin Server
====

<p align="center">
  <a href="https://hub.docker.com/r/casbin/casbin-server">
    <img alt="docker pull casbin/casbin-server" src="https://img.shields.io/docker/pulls/casbin/casbin-server.svg">
  </a>
  <a href="https://github.com/apache/casbin-server/actions/workflows/ci.yml">
    <img alt="GitHub Workflow Status (branch)" src="https://github.com/apache/casbin-server/actions/workflows/ci.yml/badge.svg">
  </a>
  <a href="https://github.com/apache/casbin-server/releases/latest">
    <img alt="GitHub Release" src="https://img.shields.io/github/v/release/apache/casbin-server.svg">
  </a>
  <a href="https://coveralls.io/github/casbin/casbin-server?branch=master">
    <img alt="Coverage Status" src="https://coveralls.io/repos/github/casbin/casbin-server/badge.svg?branch=master">
  </a>
  <a href="https://hub.docker.com/r/casbin/casbin-server">
    <img alt="Docker Image Version (latest semver)" src="https://img.shields.io/badge/Docker%20Hub-latest-brightgreen">
  </a>
</p>

<p align="center">
  <a href="https://github.com/apache/casbin-server/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/apache/casbin-server?style=flat-square" alt="license">
  </a>
  <a href="https://discord.gg/5rPsrAzK7S">
    <img alt="Discord" src="https://img.shields.io/discord/1022748306096537660?style=flat-square&logo=discord&label=discord&color=5865F2">
  </a>
</p>


Casbin Server is the ``Access Control as a Service (ACaaS)`` solution based on [Casbin](https://github.com/casbin/casbin). It provides [gRPC](https://grpc.io/) interface for Casbin authorization.

## What is ``Casbin Server``?

Casbin-Server is just a container of Casbin enforcers and adapters. Casbin-Server performs the policy enforcement check, which may take a fair amount of processing depending on the model and number of policies, interfacing to external data stores such as databases for policy data. Just like how native Casbin library works, each Casbin enforcer in Casbin-Server can use its own adapter, which is linked with external database for policy storage.

Of course, you can setup Casbin-Server together with your policy database in the same machine. But they can be separated. If you want to achieve high availability, you can use a Redis cluster as policy storage, then link Casbin-Server's adapter with it. In this sense, Casbin enforcer can be viewed as stateless component. It just retrieves the policy rules it is interested in (via sharding), does some computation and then returns ``allow`` or ``deny``.

## Architecture

Casbin-Server uses the client-server architecture. Casbin-Server itself is the server (in Golang only for now). The clients for Casbin-Server are listed here:

Language | Author | Client
----|----|----
Golang | Casbin | https://github.com/casbin/casbin-go-client
Java | [Accept008](https://github.com/Accept008) | https://github.com/Accept008/grpc-client
PHP | Casbin | https://github.com/php-casbin/casbin-client
Python | [@prathik-kaliyambath](https://github.com/prathik-kaliyambath)| https://github.com/prathik-kaliyambath/casbin-python-client

Contributions for clients in other languages are welcome :)

## Prerequisites

### Protobuf (if not installed):

As Casbin-Server uses ``gRPC``, you need to [install Protocol Buffers](https://github.com/golang/protobuf#installation) first to generate the ``.proto`` file. The command is:

```
protoc -I proto --go_out=plugins=grpc:proto proto/casbin.proto
```

Alternatively, you can also [run it from an IDE](https://github.com/casbin/casbin-server/blob/6b46c48c8845dc1b8021f2872be08b8e1a62b092/main.go#L15).

## Installation

    go get github.com/casbin/casbin-server

## Database Support

Similar to Casbin, Casbin-Server also uses adapters to provide policy storage. However, because Casbin-Server is a service instead of a library, the adapters have to be implemented inside Casbin-Server. As Golang is a static language, each adapter requires to import 3rd-party library for that database. We cannot import all those 3rd-party libraries inside Casbin-Server's code, as it causes dependency overhead.

For now, [Gorm Adapter](https://github.com/apache/casbin-server/blob/master/server/adapter.go) (with ``mssql``, ``mysql``, ``postgres``), MongoDB und Redis Adapter are built-in imports all commented. If you want to use ``Gorm Adapter`` with one of those databases, you should uncomment that import line, or add your own import, or even use another adapter by modifying Casbin-Server's source code.

To allow Casbin-Server to be production-ready, the adapter configuration supports environment variables. For example, assume we created a ``postgres`` database for our RBAC model and want Casbin-Server to use it. Assuming that the environment in which the Casbin-Server runs contains the necessary variables, we can simply use the ``$ENV_VAR`` notation to provide these to the adapter.

```
{
  "driver": "postgres",
  "connection": "host=$DB_HOST port=$DB_PORT user=$DB_USERNAME dbname=$DB_NAME password=$DB_PASSWORD",
  "enforcer": "examples/rbac_policy.csv",
  "dbSpecified" : true
}
```
The connection config file path can also be set using the environment variable `CONNECTION_CONFIG_PATH`. If this variable is not set, connection config is read from the path "config/connection_config.json".

## Docker Way

```
docker run -id -p 50051:50051 --name my-casbin-server casbin/casbin-server
```

If you want to define your own connection file

```
docker run -id -p 50051:50051 \
-e CONNECTION_CONFIG_PATH=/data/connection_config.json \
-v ${your local file path}:/data \
--name my-casbin-server \
-d casbin/casbin-server
```

If you want to build your own image

```
docker build -f ./Dockerfile -t my-casbin-server-image .
```

## Limitation of ABAC

Casbin-Server also supports the ABAC model as the Casbin library does. You may wonder how Casbin-Server passes the Go structs to the server-side via network? Good question. In fact, Casbin-Server's client dumps Go struct into JSON and transmits the JSON string prefixed by ``ABAC::`` to Casbin-Server. Casbin-Server will recognize the prefix and load the JSON string into a pre-defined Go struct with 11 string members, then pass it to Casbin. So there will be several limitations for Casbin-Server's ABAC compared to Casbin's ABAC:

1. The Go struct should be flat, all members should be primitive types, e.g., string, int, boolean. No nested struct, no slice or map.

2. All members should be public (first letter capitalized).

3. The Go struct is limited to 11 members at most. If you want to have more members, you should modify [Casbin-Server's source code](https://github.com/casbin/casbin-server/blob/5e21d10e863c7d8461f951417eb1c63fa00204fb/server/abac.go#L27-L40) by adding more members and rebuild it.

## Getting Help

- [Casbin](https://github.com/casbin/casbin)

## License

This project is under Apache 2.0 License. See the [LICENSE](LICENSE) file for the full license text.

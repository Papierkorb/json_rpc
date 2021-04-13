# JSON-RPC Client and Server [![Build Status](https://travis-ci.org/Papierkorb/json_rpc.svg?branch=master)](https://travis-ci.org/Papierkorb/json_rpc)

Use and provide services using JSON-RPC!

## Transports

| Transport | Client  | Server  |
|-----------|---------|---------|
| HTTP      | Yes     | Planned |
| Websocket | Planned | Planned |
| TCP       | Yes     | Yes     |

Custom transports can be easily created.  Have a look at `JsonRpc::TcpClient`.

## Features

* Multi-transport
* Doesn't require trailing new-line after JSON documents
* Lenient towards non-conform implementations
* Built-in protection
  * Flood-protection
  * Against huge documents
  * Configurable!

## Usage

Here's a quick HTTP client getting your bitcoin testnet wallets balance:

```crystal
# Sample code for Bitcoin RPC:
require "json_rpc"

# Set up the HTTP client
http_client = HTTP::Client.new("localhost", 18332)
http_client.basic_auth "rpc_user", "rpc_password"

# Turn it into a JSON-RPC client
client = JsonRpc::HttpClient.new http_client

# Check your balance!
pp client.call(Float64, "getbalance")
```

[Source](https://github.com/Papierkorb/json_rpc/tree/master/samples/http_client.cr)

But there's more to find in `samples/`:

For a simple case, see
[tcp_client.cr](https://github.com/Papierkorb/json_rpc/tree/master/samples/tcp_client.cr)
and
[tcp_server.cr](https://github.com/Papierkorb/json_rpc/tree/master/samples/tcp_server.cr).

If you want to see a full application, have a look at
[tcp_chat.cr](https://github.com/Papierkorb/json_rpc/tree/master/samples/tcp_chat.cr).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  json_rpc:
    github: Papierkorb/json_rpc
```

## Contributing

1. Fork it ( https://github.com/Papierkorb/json_rpc/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

### Running tests

1. Install dependencies: `shards install`
2. Run them: `crystal spec`

## Contributors

- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig - creator, maintainer

## Have a nice day!

*Connect all the things*

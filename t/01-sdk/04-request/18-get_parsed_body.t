use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;

plan tests => repeat_each() * (blocks() * 3);

run_tests();

__DATA__

=== TEST 1: request.get_parsed_body() returns arguments with application/x-www-form-urlencoded
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args, err, mime = sdk.request.get_parsed_body()

            ngx.say("type=", type(args))
            ngx.say("test=", args.test)
            ngx.say("mime=", mime)
        }
    }
--- request
POST /t
test=post
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- response_body
type=table
test=post
mime=application/x-www-form-urlencoded
--- no_error_log
[error]



=== TEST 2: request.get_parsed_body() returns arguments with application/json
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args, err, mime = sdk.request.get_parsed_body()

            ngx.say("type=", type(args))
            ngx.say("test=", args.test)
            ngx.say("mime=", mime)
        }
    }
--- request
POST /t
{
  "test": "json"
}
--- more_headers
Content-Type: application/json
--- response_body
type=table
test=json
mime=application/json
--- no_error_log
[error]



=== TEST 3: request.get_parsed_body() returns arguments with multipart/form-data
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args, err, mime = sdk.request.get_parsed_body()

            ngx.say("type=", type(args))
            ngx.say("test=", args.test)
            ngx.say("mime=", mime)
        }
    }
--- request
POST /t
--AaB03x
Content-Disposition: form-data; name="test"

form-data
--AaB03x--
--- more_headers
Content-Type: multipart/form-data; boundary=AaB03x
--- response_body
type=table
test=form-data
mime=multipart/form-data
--- no_error_log
[error]



=== TEST 4: request.get_parsed_body() returns error when missing content type header
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = sdk.request.get_parsed_body()

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
test=post
--- response_body
error: missing content type
--- no_error_log
[error]



=== TEST 5: request.get_parsed_body() returns error when using unsupported content type
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = sdk.request.get_parsed_body()

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
test=post
--- more_headers
Content-Type: application/x-unsupported
--- response_body
error: unsupported content type 'application/x-unsupported'
--- no_error_log
[error]



=== TEST 6: request.get_parsed_body() returns error with invalid json body
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = sdk.request.get_parsed_body()

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
--- more_headers
Content-Type: application/json
--- response_body
error: invalid json body
--- no_error_log
[error]



=== TEST 7: request.get_parsed_body() content type value is case-insensitive
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args, err, mime = sdk.request.get_parsed_body()

            ngx.say("type=", type(args))
            ngx.say("test=", args.test)
            ngx.say("mime=", mime)
        }
    }
--- request
POST /t
test=post
--- more_headers
Content-Type: APPLICATION/x-WWW-form-Urlencoded
--- response_body
type=table
test=post
mime=application/x-www-form-urlencoded
--- no_error_log
[error]



=== TEST 8: request.get_parsed_body() with application/x-www-form-urlencoded returns request post arguments
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args = sdk.request.get_parsed_body()
            ngx.say("Foo: ", args.Foo)
            ngx.say("Bar: ", args.Bar)
            ngx.say("Accept: ", table.concat(args.Accept, ", "))
        }
    }
--- request
POST /t
Foo=Hello&Bar=World&Accept=application%2Fjson&Accept=text%2Fhtml
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- response_body
Foo: Hello
Bar: World
Accept: application/json, text/html
--- no_error_log
[error]



=== TEST 9: request.get_parsed_body() with application/x-www-form-urlencoded returns empty table with header Content-Length: 0
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            ngx.say("next: ", next(sdk.request.get_parsed_body()))
        }
    }
--- request
POST /t
Foo=Hello&Bar=World
--- more_headers
Content-Type: application/x-www-form-urlencoded
Content-Length: 0
--- response_body
next: nil
--- no_error_log
[error]



=== TEST 10: request.get_parsed_body() with application/x-www-form-urlencoded returns request post arguments case-sensitive
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args = sdk.request.get_parsed_body()
            ngx.say("Foo: ", args.Foo)
            ngx.say("foo: ", args.foo)
            ngx.say("fOO: ", args.fOO)
        }
    }
--- request
POST /t
Foo=Hello&foo=World&fOO=Too
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- response_body
Foo: Hello
foo: World
fOO: Too
--- no_error_log
[error]



=== TEST 11: request.get_parsed_body() with application/x-www-form-urlencoded fetches 100 post arguments by default
--- config
    location = /t {
        access_by_lua_block {
            local args = {}
            for i = 1, 200 do
                args["arg-" .. i] = "test"
            end
            ngx.req.read_body()
            ngx.req.set_body_data(ngx.encode_args(args))
        }

        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args = sdk.request.get_parsed_body("application/x-www-form-urlencoded")

            local n = 0

            for _ in pairs(args) do
                n = n + 1
            end

            ngx.say("number of query arguments fetched: ", n)
        }
    }
--- request
POST /t
--- response_body
number of query arguments fetched: 100
--- no_error_log
[error]



=== TEST 12: request.get_parsed_body() with application/x-www-form-urlencoded fetches max_args argument
--- config
    location = /t {
        access_by_lua_block {
            local args = {}
            for i = 1, 100 do
                args["arg-" .. i] = "test"
            end
            ngx.req.read_body()
            ngx.req.set_body_data(ngx.encode_args(args))
        }

        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local headers = sdk.request.get_parsed_body("application/x-www-form-urlencoded", 60)

            local n = 0

            for _ in pairs(headers) do
                n = n + 1
            end

            ngx.say("number of query arguments fetched: ", n)
        }
    }
--- request
POST /t
--- response_body
number of query arguments fetched: 60
--- no_error_log
[error]



=== TEST 13: request.get_parsed_body() with application/x-www-form-urlencoded raises error when trying to fetch with max_args invalid value
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = pcall(sdk.request.get_parsed_body, "application/x-www-form-urlencoded", "invalid")

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
--- response_body
error: max_args must be a number
--- no_error_log
[error]



=== TEST 14: request.get_parsed_body() with application/x-www-form-urlencoded raises error when trying to fetch with max_args < 1
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = pcall(sdk.request.get_parsed_body, "application/x-www-form-urlencoded", 0)

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
--- response_body
error: max_args must be >= 1
--- no_error_log
[error]



=== TEST 15: request.get_parsed_body() with application/x-www-form-urlencoded raises error when trying to fetch with max_args > 1000
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local _, err = pcall(sdk.request.get_parsed_body, "application/x-www-form-urlencoded", 1001)

            ngx.say("error: ", err)
        }
    }
--- request
POST /t
--- response_body
error: max_args must be <= 1000
--- no_error_log
[error]



=== TEST 16: request.get_parsed_body() with application/x-www-form-urlencoded returns nil + error when the body is too big
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local args, err = sdk.request.get_parsed_body()
            ngx.say("error: ", err)
        }
    }
--- request eval
"POST /t\r\n" . ("a=1" x 20000)
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- response_body
error: request body in temp file not supported
--- no_error_log
[error]

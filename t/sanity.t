# vim:set ft= ts=4 sw=4 et:

use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);
use Test::Nginx::Socket 'no_plan';

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";

    lua_shared_dict ipdb 10m;

    init_by_lua '
        local monip = require "resty.17monip"
        iplocater = monip:new{ datfile = "t/17monipdb.dat" }

        local ipdb = ngx.shared.ipdb
        ipdb:set("17monipdb", iplocater.index_buffer)
    ';
};

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local iplocater = iplocater

            local t = {"127.0.0.1", "115.216.25.67"}

            for i=1, #t, 1 do
                local res, err = iplocater:query(t[i])
                if not res then
                    ngx.say(err)
                    return
                end
                ngx.say(res[1], " ", res[2], " ", res[3], "$")
            end
        ';
    }
--- request
    GET /t
--- response_body
本机地址 本机地址 $
中国 浙江 宁波$
--- no_error_log
[error]
[warn]


=== TEST 2: update from data
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local iplocater = iplocater

            local ipdb = ngx.shared.ipdb
            local data = ipdb:get("17monipdb")
            local ok, err = iplocater:update{ data = data }
            if not ok then
                ngx.say(err)
                return
            end

            local res, err = iplocater:query("112.112.1.1")
            if not res then
                ngx.say(err)
                return
            end
            ngx.say(res[1], " ", res[2], " ", res[3])
        ';
    }
--- request
    GET /t
--- response_body
invalid db format
--- no_error_log
[error]
[warn]


=== TEST 3: invalid ip format
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local iplocater = iplocater

            local res, err = iplocater:query("112.112.1.a")
            if not res then
                ngx.say(err)
                return
            end
            ngx.say(res[1], " ", res[2], " ", res[3])
        ';
    }
--- request
    GET /t
--- response_body
invalid ip format
--- no_error_log
[error]
[warn]

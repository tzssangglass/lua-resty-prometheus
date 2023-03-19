use Test::Nginx::Socket::Lua;

log_level('info');
no_long_string();
repeat_each(1);
plan('no_plan');

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = $block->http_config // <<_EOC_;
    init_worker_by_lua_block {
        local prometheus = require("lib.resty.prometheus")
        local ok, err = prometheus:init_worker()
        if err then
            ngx.say(err)
            return
        end
    }

    lua_package_path "lua-resty-lmdb/lib/?.lua;./?.lua;;";
_EOC_
    $block->set_value("http_config", $http_config);

    my $main_config = $block->main_config // <<_EOC_;
lmdb_environment_path ../dbless.lmdb;
lmdb_map_size         128m;
_EOC_
    $block->set_value("main_config", $main_config);
});

run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /t {
        content_by_lua_block {
            ngx.say("ok")
        }
    }
--- request
GET /t
--- response_body
ok



=== TEST 2: counter
--- config
    location /t {
        content_by_lua_block {
            local prometheus = require("lib.resty.prometheus")
            local ok, err = prometheus.counter("test_counter", 1)
            if err then
                ngx.say(err)
                return
            end
            ngx.say("ok")
        }
    }
--- request
GET /t
--- response_body
ok



=== TEST 3: collect
--- config
    location /t {
        content_by_lua_block {
            local prometheus = require("lib.resty.prometheus")
            local val = prometheus.collect("test_counter")
            ngx.say(val)
        }
    }
--- request
GET /t
--- response_body
1

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
        local prometheus_inst, err = prometheus.init()
        if err then
            ngx.say(err)
            return
        end

        local metrics = {}
        metrics.status = prometheus_inst:counter("http_status", "HTTP status codes", {"code"})

        if err then
            ngx.say(err)
            return
        end

        _G.metrics = metrics
        _G.prometheus_inst = prometheus_inst
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

=== TEST 2: counter
--- config
    location /t {
        content_by_lua_block {
            local metrics = _G.metrics
            ngx.log(ngx.WARN, " metrics: ", require("inspect")(metrics))
            metrics.status.inc("200")

            local prometheus_inst = _G.prometheus_inst
            local val = prometheus_inst:collect("200")
            ngx.say(val)
        }
    }
--- request
GET /t
--- response_body
1


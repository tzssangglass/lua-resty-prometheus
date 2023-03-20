local lmdb_txn          = require "resty.lmdb.transaction"
local txn               = require("resty.lmdb.transaction")
local lmdb              = require("resty.lmdb")
local ngx_get_phase     = ngx.get_phase
local new_tab           = require "table.new"
local type              = type
local tostring          = tostring
local tonumber          = tonumber

-- copy form https://github.com/knyar/nginx-lua-prometheus/blob/main/prometheus.lua#L73-L87
local TYPE_COUNTER    = 0x1
local TYPE_GAUGE      = 0x2
local TYPE_HISTOGRAM  = 0x4
local TYPE_LITERAL = {
    [TYPE_COUNTER]   = "counter",
    [TYPE_GAUGE]     = "gauge",
    [TYPE_HISTOGRAM] = "histogram",
}

local _M = {}
local mt = { __index = _M }

function _M.init()
    if ngx_get_phase() ~= "init_worker" then
        return nil, "only can be called in init_worker phase"
    end

    local t = lmdb_txn.begin(1)
    t:db_open(true)
    local ok, err = t:commit()
    if not ok then
        return nil, "failed to create and open the LMDB database, err: " .. err
    end

    local self = setmetatable({}, mt)
    self.registry = new_tab(8, 0)
    self.initialized = true
    return self
end


local function inc(key)
    local value = lmdb.get(key)
    if not value then
        value = 0
    end

    value = tonumber(value)

    value = value + 1

    value = tostring(value)

    local t = txn.begin(128)
    t:db_drop(false)
    t:set(key, value)
    local ok, err = t:commit()
    if not ok then
        return nil, err
    end
end

function _M:counter(name, help, labels)
    if not name then
        return nil, "name is required"
    end

    if not labels then
        return nil, "labels is required"
    end

    local metric = new_tab(0, 8)
    metric.name = name
    metric.help = help
    metric.labels = labels
    metric.type = TYPE_COUNTER
    metric.inc = inc

    self.registry[name] = metric
    return metric
end


function _M:collect(key)
    ngx.header.content_type = "text/plain"
    local value = lmdb.get(key)
    return value
end


return _M

local lmdb_txn = require "resty.lmdb.transaction"
local txn = require("resty.lmdb.transaction")
local lmdb = require("resty.lmdb")

local type = type
local tostring = tostring

local _M = {}


function _M.init_worker()
    local t = lmdb_txn.begin(1)
    t:db_open(true)
    local ok, err = t:commit()
    if not ok then
        return nil, "failed to create and open the LMDB database, err: " .. err
    end
end


function _M.counter(key, value)
    if not key then
        return nil, "key is required"
    end

    if not value then
        return nil, "value is required"
    end

    if type(value) ~= "number" then
        return nil, "value must be a number"
    end

    value = tostring(value)

    local t = txn.begin(128)
    t:db_drop(false)
    t:set(key, value)
    local ok, err = t:commit()
    if not ok then
        return nil, err
    end
end


function _M.collect(key)
    local value = lmdb.get(key)
    return value
end


return _M

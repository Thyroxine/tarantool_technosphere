#!/usr/bin/env tarantool
---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by kirill.
--- DateTime: 4/2/21 8:14 PM
---


local clock = require('clock')
local fio = require('fio')
local http_server = require('http.server')
local digest = require('digest')
local host = 'localhost'
local port = tonumber(arg[1])

if port == nil then
    error('Invalid port')
end

local work_dir = fio.pathjoin('data', port)
fio.mktree(work_dir)
box.cfg({
    listen = port,	
    work_dir = work_dir,
})
box.schema.user.passwd('admin', 'test')

local requests_timestamps = {}

local function stats()
    local current_time = clock.monotonic64()
    table.insert(requests_timestamps, current_time)
    while table.maxn(requests_timestamps) ~= 0 and current_time - requests_timestamps[1] > 1e9 do
        table.remove(requests_timestamps, 1)
    end 
    body = host..':'..port..': '..tostring(table.maxn(requests_timestamps))
    return {
        body = body,
        status = 200,
    }
end

local httpd = http_server.new('localhost', 8080, {log_requests = true})

local router = require('http.router').new()

router:route({method = 'GET', path = '/'}, stats)
httpd:set_router(router)

httpd:start()
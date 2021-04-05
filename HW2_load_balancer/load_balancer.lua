#!/usr/bin/env tarantool
---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by kirill.
--- DateTime: 4/2/21 7:26 PM
---


local log = require('log')
local netbox = require('net.box')
local http_server = require('http.server')
local http_router = require('http.router')
local fio = require('fio')
local yaml = require('yaml')
local clock = require('clock')





if fio.path.is_file("config.yml") then
    config_file = fio.open("config.yml")
else
    os.exit(1)
end

yaml_buffer=config_file:read()
config_file:close()
--print(yaml_buffer)
config=yaml.decode(yaml_buffer)

port=config["proxy"]["port"]
proxy_host=config["proxy"]["bypass"]["host"]
proxy_port=config["proxy"]["bypass"]["port"]


local hosts = {
    'admin:test@localhost:3301',
    'admin:test@localhost:3302',
    'admin:test@localhost:3303',
}

local connections = {}
for _, host in ipairs(hosts) do
    local conn = netbox.connect(host)
    assert(conn)
    log.info('Connected to %s', host)
    table.insert(connections, conn)
end

local req_num = 1
local function handler()
    local conn = connections[req_num]
    if req_num == #connections then
        req_num = 1
    else
        req_num = req_num + 1
    end

    local result = conn:call('exec')

    return {
        body = result,
        status = 200,
    }
end

local httpd = http_server.new('0.0.0.0', '8080', {log_requests = false})
httpd:route({method = 'GET', path = '/'}, handler)
httpd:start()

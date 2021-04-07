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
local console = require('console')

local hosts = {}
local httpd = {}
local connections = {}
local config = {}
local port = 0
local req_num = 1
local requests_timestamps = {}

local function rpc(conn)
    if conn ~= nil and conn:is_connected() then
        local result = conn:call('exec')
        return {
            body = result,
            status = 200,
        }
    else
        return {
            status = 502,
        }
    end
end

local function request_stats()
    local current_time = clock.monotonic64()
    table.insert(requests_timestamps, current_time)
    while #requests_timestamps ~= 0 and current_time - requests_timestamps[1] > 1e9 do
        table.remove(requests_timestamps, 1)
    end
    return #requests_timestamps
end

local function get_connection_id()
    if req_num >= #connections then
        req_num = 1
    else
        req_num = req_num + 1
    end
    return req_num
end

local function handler()
    if request_stats() > config["limit"] then
        return {
            body = "Too many requests",
            status = 429
        }
    end
    while #connections > 0 do
        local id = get_connection_id()
        local conn = connections[id]
        local result = rpc(conn)
        if result["status"] == 200 then
            return result
        else
            print("Host "..hosts[id].." is disconnected")
            conn:close()
            table.remove(connections,id)
            table.remove(hosts,id)
        end
    end
    if #connections == 0 then
        return {
            body = "No backend servers avaliable",
            status = 502
        }
    end
end

local function load_config()
    local config_file={}
    if fio.path.is_file("config.yml") then
        config_file = fio.open("config.yml")
    else
       os.exit(1)
    end
    local yaml_buffer=config_file:read()
    config_file:close()
    config = yaml.decode(yaml_buffer)["load_balancer"]
    port = tonumber(config["port"])
end

local function start_server(handler)
    httpd = http_server.new('0.0.0.0', port, {log_requests = false})
    local router = http_router.new()
    router:route({method = 'GET', path = '/'}, handler)
    httpd:set_router(router)
    httpd:start()
end

local function stop_server()
    httpd:stop()
end

local function connect()
    for _, host in ipairs(config["hosts"]) do
        local host_string = host["login"]..":"..host["password"].."@"..host["host"]..":"..host["port"]
        table.insert(hosts,host_string)
    end

    for _, host in ipairs(hosts) do
        local conn = netbox.connect(host)
        assert(conn)
        log.info('Connected to %s', host)
        table.insert(connections, conn)
    end
end

local function disconnect()
    while #connections > 0 do
        for id, conn in ipairs(connections) do
            log.info('Disconnected from %s', hosts[id])
            conn:close()
            table.remove(connections,id)
            table.remove(hosts,id)
        end
    end
end

function shutdown(do_exit)
    if do_exit then
        print("Shutting down the load balancer")
    else
        print("Reloading load balancer")
    end
    disconnect()
    stop_server()
    if do_exit then
        os.exit(0)
    end
end

local function startup()
    print("Starting the load balancer")
    load_config()
    connect()
    start_server(handler)
end

function reload()
    shutdown(false)
    startup()
end

startup()
console.listen("0.0.0.0:"..config["admin_port"])
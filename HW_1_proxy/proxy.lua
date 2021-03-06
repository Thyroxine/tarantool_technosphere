#!/usr/bin/env tarantool
---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Kirill Kopylov.
--- DateTime: 3/24/21 7:56 PM
---
---
box.cfg {
   listen = 3301,
   background = true,
   log = '1.log',
   pid_file = '1.pid'
}


local function proxy(req)
    local client=require('http.client').new()
    local json=require('json')
    local urlencode=require('urlencode')
    ---    print("Proxy working")
    print(req:method())
    print(req:path())
    print("Request query")
    print(req:query())
    local req_headers=req:headers()
    ---print("Request headers")
    ---for key,value in pairs(req_headers) do print(key,value) end
    print("Request params")
    local method = req:method()
    for key,value in pairs(req:param()) do print(key,value) end
    local uri_params=""
    if method == "POST" then
        req_headers['content-length']=nil
        if req_headers['content-type'] == 'application/x-www-form-urlencoded' then
            uri_params=urlencode.table(req:param())
        end
        if req_headers['content-type'] == 'application/json' then
            uri_params=json.encode(req:param())
        end
        print(uri_params)

    end
    --local resp = client:request(req:method(),proxy_host..":"..proxy_port..req:path(),uri_params,
    local resp = client:request(req:method(),proxy_host..":"..proxy_port..req:path().."?"..req:query(),uri_params,
            {headers=req_headers,follow_location=false, verbose=true, max_header_name_len=128, accept_encoding=true})
    ---print(resp.body)
    print(resp.status)
    --for key,value in pairs(resp.headers) do print(key,value) end
 --   for key,value in pairs(client:stat()) do print(key,value) end
    resp.headers["transfer-encoding"]=nil
    resp.headers["server"]=nil
    return {
        status = resp.status,
        body = resp.body,
        headers = resp.headers
    }
end

local fio=require('fio')
local yaml=require('yaml')

---yaml_buffer = require('buffer').ibuf()

if fio.path.is_file("proxy.yml") then
    config_file = fio.open("proxy.yml")
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
print(port)
print(proxy_host)
print(proxy_port)

local router = require('http.router').new()
router:route({ method = 'ANY', path = '/(.*)' }, proxy)
router:route({ method = 'ANY', path = '/' }, proxy)

local server = require('http.server').new('localhost', port)
server:set_router(router)

server:start()

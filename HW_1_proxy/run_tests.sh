#!/bin/bash

docker-compose up -d
tarantool proxy.lua
echo "Waiting for tarantool to start"
sleep 10

echo "Testing POST queries"
curl -X POST -H "Content-Type: application/json" -d '{"a":"b"}' http://localhost:8080/ -o POST_original.out
curl -X POST -H "Content-Type: application/json" -d '{"a":"b"}' http://localhost:9001/ -o POST_proxied.out
cat POST_original.out | sed 's/,//g' |  grep -v "host" | grep -v "connection" | sort > POST_original_sorted.out
cat POST_proxied.out | sed 's/,//g' | grep -v "host" | grep -v "connection" | sort > POST_proxied_sorted.out
if cmp -s "proxied_sorted.out" "original_sorted.out"; then
    echo "Pass: POST queries identical"
else
    echo "Fail: POST queries differ"
fi

echo "Testing GET queries"
curl -X GET -o GET_original.out 'http://localhost:8080/test?a=foo&b=bar' 
curl -X GET -o GET_proxied.out 'http://localhost:9001/test?a=foo&b=bar' 
cat GET_original.out | sed 's/,//g' |  grep -v "host" | grep -v "connection" | sort > GET_original_sorted.out
cat GET_proxied.out | sed 's/,//g' | grep -v "host" | grep -v "connection" | sort > GET_proxied_sorted.out
if cmp -s "proxied_sorted.out" "original_sorted.out"; then
    echo "Pass: GET queries identical"
else
    echo "Fail: GET queries differ"
fi

rm -f POST_original.out POST_proxied.out GET_original.out GET_proxied.out GET_original_sorted.out GET_proxied_sorted.out POST_original_sorted.out POST_proxied_sorted.out
docker-compose down

kill -s SIGTERM $(cat 1.pid)

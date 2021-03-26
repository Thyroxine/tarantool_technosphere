# Proxy

# Run simple tests

1. Install docker and docker-compose
2. Install tarantool and http module
3. Run `run_tests.sh`

# Real test using joomls

1. Install joomla by using `docker-compose.yml` in repo root:
```bash
docker-compose up -d
```
Navidate to http://localhost:8080 and finish the installation with the following parameters:
```
Database host: db
Database name: joomla
Database user: joomla
Database password: joomla
```
2. Run proxy
```
tarantool proxy.lua
```
It reads settings from `proxy.yml`

3. Navigate to proxied joomla to http://localhost:8080 

3. Stop joomla container by `docker-compose down` when not needed.

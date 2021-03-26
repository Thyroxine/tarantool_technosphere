# Proxy

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

3. Stop joomla container by `docker-compose down` when not needed.

##Homework #2 Load balancer.

How to launch load balancer:

1. Fill the YAML file `config.yml`
```yaml
---
load_balancer:
  port: 8080 # Listening HTTP port
  admin_port: 8888 # admin console port
  limit: 1000 # Maximum requests per second
  hosts: #Backend servers
    - host: localhost
      port: 3030
      login: admin
      password: test
    - host: localhost
      port: 3031
      login: admin
      password: test
    - host: localhost
      port: 3032
      login: admin
      password: test
```
2. Start backend servers
```shell
tarantool -i server.lua 3030 admin test #Port, login, password 
```
3. Run load balancer
```shell
tarantool -i load_balancer.lua
```
4. To add/remove servers you should change their records in `config.yml`, then either type `reload()`
in local tarantool console or connect to admin console:
```shell
tarantoolctl connect localhost:8888
```
and type `reload()`. Do the same to reset load balancer for reconnecting to the failed server.
5. You can shutdown load balancer by typing `shutdown(true)` in local or remote console.
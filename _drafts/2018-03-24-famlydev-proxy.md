---
layout: post
title: "Famlydev: Proxy"
date: 2018-03-24 12:00:00
colors: pinkred
---

`famlydev` has evolved quite a lot since I gave [a talk][famlydev-talk] about it
last year. One of the biggest changes is we've loosened the requirement that
everything should run inside of Docker. Instead the developer should be able
to mix-and-match between having things running on the host, in docker, or in
our staging environment. To make this possible we run a proxy whose
configuration I'll go through in this blog post.

## Background

I alluded to the goal in the in the teaser, but I'll spend a few sentences
clearing up the use-case a bit as all of this might be very Famly specific 😉

All of our services can be configured through environment variables and we use
these to configure how the services can find each other - in production we use
Kubernetes' DNS based service discovery, e.g. we simply set `FAMLYAPI` to
`famlyapi-service` and kubernetes takes takes of the rest. During development we
used Dockers DNS resolver to achieve the same thing. Here's a bit from an
internal issue on our `famlydev` repository explaining the need for the proxy.

  > The original vision was that everything would be running inside of Docker
  > so routing could be handled entirely by Dockers DNS server but in practice
  > this hasn't resulted in a nice developer experience. Some examples: App's
  > compilation speed is roughly doubled if you run it inside of a container
  > using Docker for Mac. If we were to run our Scala code in watch mode in
  > docker we would end up compiling everything twice: once in the IDE and
  > once in Docker. So we needed to be able to mix and match what we're
  > running in Docker, what we're running locally and what we're routing to
  > staging. This is why we have a proxy in famlydev.

Alright, so we introduced a proxy that's running on port `80` which routes to
the right services. However, this came with its own set of issues, namely
that if you wanted to switch out a service you'd had to jump through a few
hoops. Here's another excerpt from the same issue.

  > If you want to route traffic to a local version of `famlyapi`, for example,
  > you have to update your `environment.env` file, update the `nginx.conf`
  > file and restart the relevant containers as updated environment variables
  > aren't propagated into running containers.

The whole purpose of `famlydev` is that everything should just work™️ so forcing
people to remember these kinds of workflows just to route traffic to a locally
running service isn't good enough.

Our current **solution** is to use DNS for service discovery together with NGINX
upstream definitions to encode a specific precedence when routing traffic to a
service. I'll cover each of these techniques in the next two sections.

## Service discovery through DNS

In order to use DNS for service discovery we have to make sure that all of the
relevant host names can be resolved on the host as well as inside of Docker;
luckily this was pretty straightforward.

### On the host

To configure the DNS resolution on the host we simply add a bunch of entires
to the `/etc/hosts` file. Here's what the famly part of my `/etc/hosts` looks
like:

```
127.0.0.1	famlyapi.famly.local
127.0.0.1	app.famly.local
127.0.0.1	api.famly.local
127.0.0.1	docs.famly.local
127.0.0.1	demo.famly.local
127.0.0.1	signin.famly.local
```

### In Docker

In docker we simply use Dockers [network alias][network-alias] feature:

```
version: "2"

services:
  proxy:
    image: nginx:1.13.3-alpine
    ports:
      - "80:80"
    volumes:
      - ../etc/proxy.conf:/etc/nginx/nginx.conf
    networks:
      default:
        aliases:
          - famlyapi.famly.local
          - api.famly.local
          - app.famly.local
          - docs.famly.local
          - demo.famly.local
          - signin.famly.local
```

Alright, so now `famlyapi.famly.local` will route to `localhost` if resolved
on the host and will route to NGINX if resolved inside of Docker. So now we just
need to make sure that the NGXIN proxy routes the traffic to the correct place.

## NGINX upstream definitions

Now that all traffic goes to NGINX we have to make sure it sends the traffic to
the right service. To do this we define a [server block][server] for each
service and use [upstream][upstream] blocks to define a set of ports it should
try to connect to a specific service on.

The trick here is that we've defined a precedence for each "configuration" of a
service. E.g. running `famlyapi` locally on the host should receive traffic
before the `famlyapi` instance running inside of Docker (if one is running there
at all) - we use the port number to distinguish between the various
configurations.

Here's the full NGINX configuration - I've annotated it with plenty of comments
to explain some of the oddities of the configuration.

```nginx
# famlydevs proxy configuration - all traffic goes through this proxy.
#
# Notes.
#
# 1. Routing everything through docker.for.mac.host.internal
#
#    We have to do this as nginx won't start if there are DNS names in an
#    upstream definition it can't resolve during it's boot process.
#
#    Imagine you aren't running famlyapi in docker and we had defined the
#    famlyapi upstream with the following server definition
#    'server famlyapi:8090 backup' As we arent running famlyapi Dockers DNS
#    server can't resolve `famlyapi` and thus NGINX won't boot.
#    To work around this we expose a fixed port for each service and map it
#    out to the Mac, as it can resolve `docker.for.mac.host.internal`
#    just fine.
#

worker_processes auto;

events {
  worker_connections 1024;
}

http {

  #
  # General configuration.
  #

  sendfile on;
  access_log off;
  error_log stderr;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  #
  # gzip
  #

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_types
    text/plain text/css text/xml text/javascript
    application/json application/xml application/javascript;

  #
  # DNS
  #

  # We use dockers internal DNS to resolve the docker.for.mac.host.internal
  # host which we rely heavily on.
  resolver 127.0.0.11 valid=5s;
  resolver_timeout 10s;

  #
  # Proxy
  #

  proxy_http_version      1.1;
  proxy_redirect          off;
  proxy_next_upstream     error timeout invalid_header http_502;
  proxy_connect_timeout   2;
  proxy_set_header        Connection "";
  proxy_set_header        Host            $host;
  proxy_set_header        X-Real-IP       $remote_addr;
  proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;

  #
  # Upsteam definitions
  #

  upstream famlyapi {
    server docker.for.mac.host.internal:8090;
    server docker.for.mac.host.internal:8091 backup;
  }

  upstream api {
    server docker.for.mac.host.internal:8080;        # local
    server docker.for.mac.host.internal:8081 backup; # dev
    server docker.for.mac.host.internal:8082 backup; # prebuilt
    server docker.for.mac.host.internal:8083 backup; # prod
  }

  upstream app {
    server docker.for.mac.host.internal:4200;        # local
    server docker.for.mac.host.internal:4201 backup; # dev
    server docker.for.mac.host.internal:4202 backup; # prebuilt
    server docker.for.mac.host.internal:4203 backup; # prod
  }

  upstream demo {
    server docker.for.mac.host.internal:8060;
    server docker.for.mac.host.internal:8061 backup;
  }

  upstream docs {
    server docker.for.mac.host.internal:8000;
  }

  upstream signin {
    server docker.for.mac.host.internal:4500;
    server docker.for.mac.host.internal:4501 backup;
  }

  #
  # Server definitions
  #

  server {
    listen 80;
    server_name app.famly.local;

    location / {
      add_header Cache-Control no-cache;
      proxy_pass http://app;
    }
    location /api { proxy_pass http://api; }
    location /graphql { proxy_pass http://famlyapi; }
  }

  server {
    listen 80;
    server_name famlyapi.famly.local;
    location / { proxy_pass http://famlyapi; }
  }

  server {
    listen 80;
    server_name api.famly.local;
    location / { proxy_pass http://api; }
  }

  server {
    listen 80;
    server_name demo.famly.local;
    location / { proxy_pass http://demo; }
  }

  server {
    listen 80;
    server_name docs.famly.local;
    location / { proxy_pass http://docs; }
  }

  server {
    listen 80;
    server_name signin.famly.local;
    location / { proxy_pass http://signin; }
  }
}
```

I realize this might be incredibly Famly specific, but I hope you still got something out of it 😉

[famlydev-talk]: https://speakerdex.co/mads-hartmann/automating-developer-environments-ee3c577a
[network-alias]: https://docs.docker.com/compose/compose-file/#aliases
[server]: https://nginx.org/en/docs/http/ngx_http_core_module.html#server
[upstream]: https://nginx.org/en/docs/http/ngx_http_upstream_module.html

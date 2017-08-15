---
layout: post
title: "Deploying your prototypes"
date:   2017-08-13 06:00:00
colors: pinkred
---

About a year ago my [brother][mikkel-hartmann.com] started moving from
experimental physics into machine learning and I've been helping him out with
some of the more practical aspects of the field (such as automation, code
style, linting, structuring of project, etc.). Most recently I helped him
deploy one of his projects to AWS -- in this post I'll go through how we took
his locally running [flask][flask] application and put it into ''production''.

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Motivation

Why would you want to go through the hassle of deploying your prototypes or
small hobby projects in the first place? I think there are a couple of things
that makes it worth your effort.

First off, I personally get way more __motivated__ when I know that the thing
I'm working on is actually live somewhere on the web, even if it's behind an
obscure IP address. It's way more fun to add a feature or fix a bug when you
know you can push it live easily.

Secondly, in the best case scenario your prototype will grow into a proper
product at some point and you'll have to deploy it anyway. By deploying early,
even if all it does is print ''Hello World'', you'll __catch issues along the way__
which will allow you to incrementally improve your product in a way that's still
deployable in the end.

Finally I hope to show you that if you're willing to compromise on some of the
aspects of deploying your service (such as availability, auto scaling etc.) then
it really isn't a lot of work. In fact I'll show you a single shell script you
can run that gets the job done.

---

It was a fun experience helping my brother deploy his service as the requirements
were so different from what I usually have to deal with when automating our
deployments at [Famly][famly]. Usually I worry about the availability of the service,
configuring auto-scaling, ensuring the logs are persisted and querable, and 
things like that. However, in this case we didn't really care about any of these
things -- Instead our main focus was __simplicity__ and __ease of automation__.

Simplicity in this case meant having as few moving parts as possible and keeping
the number of new concepts my brother had to learn to a minimum, while ensuring
that the ones he did have to learn would be useful for him in other contexts
as well. I decided that the simplest solution would be to use [docker][docker]
and [docker-machine][docker-machine]. In the rest of the post I'll outline the
steps we had to go through in order to take his locally running flask app and
put it into ''production''.

## Why Docker

One of the reasons I picked Docker is that I truely believe that even if docker
died tomorrow the concept of containers, as popularlized by docker, will still
thrive. So learning the basics around containerizing your apps won't hurt.

The last nice thing is that once you have your Docker image you can run it on a
range of cloud providers really easily, so even if you aren't using AWS you can
still use your knowledge of Docker.

## Writing a Dockerfile

The first step is to write a [Dockerfile][dockerfile] for your application. You
can base it off a Linux distribution you know or simply go for one of the
official [python images][python-images].

I won't go into the details of Docker in this post -- there are plenty of good
guides and introductions on the web already. However, I will say that the
ability to be able to iterate quickly on the Dockerfile and run it locally
before trying to deploy it to AWS; once it runs locally it should be able to
run on AWS just fine as well. This was in stark contrast to one evening where
we tried to get the service running on [Elastic Beanstalk][elastic-beanstalk]

If you don't want to write a Dockerfile for one of your own projects but still
want to try deploying something to AWS then feel free to use the [small
example][example] I've created.

## Deploying to AWS

Now that we have a Docker image that we've seen work locally it's time to 
deploy it 🚀

{::options parse_block_html="true" /}
<div class="sidenote">
Before you can do _anything_ with AWS you need to [create an account][create-aws-account],
[install their cli tool][install-aws-cli], and [configure it][configure-aws] -- don't worry it won't take more
than a couple of minutes and you only have to do it once.
</div>

### Provisioning a machine

`docker-machine` is a cool little tool that makes it possible to run `docker`
command on your machine as you're used to, but in reality they will be running
on a remote machine.

Before we can deploy it we need to have somewhere to deploy it to; we need to
rent a server. Normally with AWS you'd have to launch and EC2 instance,
give it the right roles etc. Luckily d

```sh
docker-machine create \
    --amazonec2-open-port 80 \
    --amazonec2-region eu-central-1 \
    --amazonec2-instance-type t2.micro \
    --driver amazonec2 \
    <YOUR_MACHINE_NAME>
```

You can read the documentation for each of the command line arguments 
[here][docker-machine-cli].

{::options parse_block_html="true" /}
<div class="sidenote">
If you have installed [Docker for Mac][docker-mac] then you might have an outdated version
of `docker-machine` 😱

`docker-machine --version` should be `0.12.2` or higher. If you've installed
`docker-machine` through homebrew you'll need to modify your shell `$PATH` like
this

```sh
export PATH="/usr/local/Cellar/docker-machine/0.12.2/bin:$PATH"
```
</div>

### Deploying the service

To run your `docker` commands on the remote Docker machine you first have to
tell `docker` to execute commands in that context. You do that by using the
following command.

```sh
eval $(docker-machine env <YOUR_MACHINE_NAME>)
```

Future `docker` commands in your shell session will be executed on the remote
docker machine. If you close your terminal you'll have to run the command
above again in case you want to speak with the remote docker machine.

Build the Docker image on the remote machine. This will basically transfer all
of the files in your current folder unto the machine and then build the image
on the machine. If you're using my small [example][example] then you can build
the image with the following command

```sh
docker build --tag deploying-prototypes:local .
```

And finally run it.

```sh
docker run \
    --detach \
    --publish 80:80 \
    deploying-prototypes:local
```

See that it works

```sh
echo http://$(docker-machine ip <YOUR_MACHINE_NAME>)
```

You might want to terminate the machine again so you won't be billed.

```sh
docker-machine stop <YOUR_MACHINE_NAME>
```

## A simple deploy script

```sh
#!/bin/bash
#
# usage: deploy <machine-name> <image-name> <container-name>
#

set -euo pipefail

#
# Functions
#

# Convenience function for logging text to stdout in pretty colors.
function log {
    local message="$@"

    local green="\\033[1;32m"
    local reset="\\033[0m"

    if [[ $TERM == "dumb" ]]
    then
        echo "${message}"
    else
        echo -e "${green}${message}${reset}"
    fi
}

# Check if a container with a given name already exists
function container_exists {
    local container_name=$1

    if [[ -z "$(docker ps -q -f name=${container_name})" ]]
    then false
    else true
    fi
}

# Get the image tag version based on the git SHA
function version {
    git rev-parse HEAD | cut -c1-8
}

# Build the Docker image and deploy it to a given Docker machine and
# give the container a specific name.
# Remove any containers that already exist with the given name.
function deploy {
    local machine_name=$1
    local image_name=$2
    local container_name=$3

    log "Connection to machine"
    eval $(docker-machine env ${machine_name})

    log "Building image"
    docker build --tag ${image_name}:$(version) .

    if container_exists ${container_name}
    then
        log "Deleting exiting container"
        docker rm -f ${container_name}
    fi

    log "Starting containter"
    docker run \
        --detach \
        --publish 80:80 \
        --name ${container_name} \
        ${image_name}:$(version)

    log "Now running on http://$(docker-machine ip ${machine_name})"
}

#
# Main
#

machine_name=$1
image_name=$2
container_name=$3

deploy ${machine_name} ${image_name} ${container_name}
```

[flask]: http://flask.pocoo.org/docs/0.12/
[famly]: https://famly.co/
[docker]: https://www.docker.com/
[docker-machine]: https://docs.docker.com/machine/
[docker-machine-cli]: https://docs.docker.com/machine/drivers/aws/#options
[docker-mac]: https://docs.docker.com/docker-for-mac/
[dockerfile]: https://docs.docker.com/engine/reference/builder/
[mikkel-hartmann.com]: http://mikkelhartmann.dk/
[python-images]: https://hub.docker.com/_/python/
[example]: https://github.com/mads-hartmann/mads-hartmann.github.com/tree/master/_examples/deploying-your-prototypes
[elastic-beanstalk]: https://aws.amazon.com/elasticbeanstalk
[create-aws-account]: https://aws.amazon.com/free
[install-aws-cli]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[configure-aws]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

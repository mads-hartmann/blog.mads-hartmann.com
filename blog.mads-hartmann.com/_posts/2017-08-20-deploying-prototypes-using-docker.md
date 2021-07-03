---
layout: post
title: "Deploying Prototypes using Docker"
date:   2017-08-20 10:00:00
colors: pinkred
---

About a year ago my [brother][mikkel-hartmann.com] started moving from
experimental physics into machine learning and I've been helping him out with
some of the more practical aspects of the field (such as automation, code
style, linting, structuring of projects, etc.). Most recently I helped him
deploy one of his projects to AWS -- in this post I'll go through how we took
his locally running [flask][flask] application and put it into ''production''.

## Table of contents
{: .no_toc }
* TOC
{:toc}

## Motivation

Why would you want to go through the hassle of deploying your prototypes in the
first place? I think there are a couple of things that makes it worth your
effort.

First off, I personally get way more __motivated__ when I know that the thing
I'm working on is actually live somewhere on the web, even if it's behind an
obscure IP address. It's much more fun to add a feature or fix a bug when you
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
deployments at [Famly][famly]. I worry about the availability of the service,
configuring auto-scaling, ensuring the logs are persisted and queryable, and
things like that. However, in this case we didn't really care about any of these
things -- Instead our main focus was __simplicity__ and __ease of automation__.

Simplicity in this case meant having as few moving parts as possible and keeping
the number of new concepts my brother had to learn to a minimum, while ensuring
that the ones he did have to learn would be useful to him in other contexts as
well. I decided that the simplest solution would be to use [docker][docker] and
[docker-machine][docker-machine].

## Why Docker

From the perspective of using tools that might be useful to know in other
contexts I believe that Docker is an obvious choice; if you know how to
containerize your application then you'll be able to run it almost anywhere
(contrast that to learning how to set up your application using Elastic
Beanstalk for example). Given that you can containerize almost anything this
means that if you're familiar with Docker you'll be able to run almost anything
almost anywhere 😉

The ability to iterate quickly on the Dockerfile and run it locally
before trying to deploy it was also a key factor; once it runs locally it you
should be able to deploy it easily as well.

## Writing a Dockerfile

The first step is to write a [Dockerfile][dockerfile] for your application. In
the case of python you can base it off a Linux distribution you know or simply go
for one of the official [python images][python-images].

I won't go into the details of writing a Dockerfile in this post -- The
[official documentation][dockerfile] and [best-practices guide][dockerfile-guide]
contains all the information you need to get started.

If you don't want to write a Dockerfile for one of your own projects but still
want to try deploying something to AWS then feel free to use the
[small example][example] I've created.

## Deploying to AWS

At this point I assume you have a Docker image that you've been able to run
locally, so now it's time to deploy it. 🚀

{::options parse_block_html="true" /}
<div class="sidenote">
Before you can do _anything_ with AWS you need to [create an account][create-aws-account],
[install their cli tool][install-aws-cli], and [configure it][configure-aws] -- don't worry it won't take more
than a couple of minutes and you only have to do it once.
</div>

### Provisioning a machine

`docker-machine` is a tool that makes it possible to run `docker` commands on
your machine as you're used to, but in reality they will be running on a remote
machine.

Before you can deploy anything you need to have somewhere to deploy it to; you
need to rent a server. Normally with AWS you'd have to launch an [EC2][ec2]
instance, give it the right roles etc. This is where `docker-machine` comes in
handy. The following command will provision a machine and open port 80 so it can
accept HTTP traffic.

```sh
docker-machine create \
    --amazonec2-open-port 80 \
    --amazonec2-region eu-central-1 \
    --amazonec2-instance-type t2.micro \
    --driver amazonec2 \
    <YOUR_MACHINE_NAME>
```

The instance type is set to `t2.micro` which is one of the cheapest server you
can buy (See the [full list][aws-ec2-prices] of instance types here for the
various regions).

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

**Note**: As of Docker for Mac 17.09.0-ce-mac35 (19611) it ships with version
0.12.2 of `docker-machine` so you don't have to install it separately.
</div>

### Deploying the service

Now that we have a machine we can deploy our service to it. To run your `docker`
commands on the remote Docker machine you first have to tell `docker` to execute
commands in that context. You do that by using the following command.

```sh
eval $(docker-machine env <YOUR_MACHINE_NAME>)
```

Future `docker` commands in your shell session will be executed on the remote
docker machine. If you close your terminal you'll have to run the command
above again in case you want to speak with the remote docker machine.

{::options parse_block_html="true" /}
<div class="sidenote">
If you're curious how this works then simply run
`docker-machine env <YOUR_MACHINE_NAME>` without the `eval` prefix. You'll
see that all it does it set some environment variables that Docker reads
in order to know what Docker machine to talk to.
</div>

Before you can run the image on the machine you first have to build the image on
it. This will basically transfer all of the files in your current folder unto
the machine and then build the image there. If you're using my small
[example][example] then you can build the image with the following command

```sh
docker build --tag deploying-prototypes:local .
```

Finally start a Docker container based on the image.

```sh
docker run \
    --detach \
    --publish 80:80 \
    deploying-prototypes:local
```

See that it works 🎉

```sh
echo http://$(docker-machine ip <YOUR_MACHINE_NAME>)
```

Once you're done experimenting you might want to stop the machine so you
won't be billed if you're not using it.

```sh
docker-machine stop <YOUR_MACHINE_NAME>
```

## A simple deploy script

In the section above you deployed the service manually by writing a set of
commands in the shell. Once you've done that a couple of times you'll get tired
of it, so here's a deploy script that I wrote that automates it for you. It
assumes that your Docker image listens for HTTP traffic on port 80 and that port
80 is exposed on the machine (which it is if you used the `docker-machine`
command above to create it).

<script src="https://gist.github.com/mads-hartmann/415cba506a538f35a992598c9221432d.js"></script>

Download the script and make it executable.

```sh
curl https://gist.githubusercontent.com/mads-hartmann/415cba506a538f35a992598c9221432d/raw/98260522a6358feb6c4b70ad503c2e6bbe9b5ce8/prototype-deploy.sh > prototype-deploy.sh
chmod +x prototype-deploy.sh
```

Now you can deploy any Docker service to any Docker machine like this
(assuming your current folder contains the script and a `Dockerfile`)

```sh
./prototype-deploy.sh <YOUR_MACHINE_NAME> <IMAGE_NAME> <CONTAINER_NAME>
```

Where the `<IMAGE_NAME>` and `<CONTAINER_NAME>` is completely up to you.

Have fun deploying your next prototype, and let me know in the comments below
if you found it useful or have any questions 🙌

[flask]: http://flask.pocoo.org/docs/0.12/
[famly]: https://famly.co/
[docker]: https://www.docker.com/
[docker-machine]: https://docs.docker.com/machine/
[docker-machine-cli]: https://docs.docker.com/machine/drivers/aws/#options
[docker-mac]: https://docs.docker.com/docker-for-mac/
[dockerfile]: https://docs.docker.com/engine/reference/builder/
[dockerfile-guide]: https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/
[mikkel-hartmann.com]: http://mikkelhartmann.dk/
[python-images]: https://hub.docker.com/_/python/
[example]: https://github.com/mads-hartmann/mads-hartmann.github.com/tree/master/examples/deploying-your-prototypes
[elastic-beanstalk]: https://aws.amazon.com/elasticbeanstalk
[create-aws-account]: https://aws.amazon.com/free
[install-aws-cli]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[configure-aws]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
[ec2]: aws.amazon.com/ec2
[aws-ec2-prices]: https://aws.amazon.com/ec2/pricing/on-demand/

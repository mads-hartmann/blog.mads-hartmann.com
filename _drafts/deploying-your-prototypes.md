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

Why would you want to go through the hassle of deploying your prototypes or
small hobby projects? I think there are a couple of things that makes it worth
your effort.

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

## Writing a Dockerfile

Verifying locally

## Deploying to AWS

### Provisioning a machine

Using docker-machine to provision the machine

### Deploying the service

Wrote a handy script

[flask]: http://flask.pocoo.org/docs/0.12/
[famly]: https://famly.co/
[docker]: https://www.docker.com/
[docker-machine]: https://docs.docker.com/machine/
[mikkel-hartmann.com]: http://mikkelhartmann.dk/

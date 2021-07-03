---
layout: post
title: "Automating Developer Environments"
date: 2017-01-15 13:00:00
excerpt_separator: <!--more-->
colors: blueish
---

Recently I've been thinking about what the ideal developer environment
looks like to me and tried to implement some of those thoughts
at [Famly](https://famly.co).

I don't mean developer environment in the sense of an IDE but rather the
set of tools and services you are running in order to develop on your
various projects. If you're working on a backend that might be
[Postgres](https://www.postgresql.org/), [Redis](https://redis.io/), and
your backend. To me this is your developer environment; the developer
environment is agnostic to what tools you use to manipulate the source
code.

<!--more-->

I've seen a lot of blog posts and conference talks about automating your
deployments but I haven't seen much about automating your developer
environment. In this post I'll go through what we're trying to achieve
at Famly and give some details about the implementation.


<div class="notice">
    <p>
        We've open-sourced a version of our internal tool for automating our
        developer environment a Famly Check out
        <a href="https://github.com/famly/plan" target="_blank">famly/plan</a>.
    </p>
    <small>24. February 2017</small>
</div>


## Goal

To me the ultimate developer environment is one that takes zero effort
to setup and once it's running gets out of your way. The developer
should be able to focus on the task at hand rather than the mechanics of
the developer environment.

This is of course rather abstract, so here are some very concrete goals.

-   **Setup should be 100% automated**: The developer shouldn't have to
    wade though several READMEs in order to get things running (assuming
    READMEs exists). If you can put it in a README it's likely you can
    automate it as well.

-   **Observing your changes should be automatic**: Whenever you change
    the source code of a given service it should detect it and take
    whatever steps are necessary for you to observe those changes. If
    you're working on the frontend this means recompiling and refreshing
    the browser (or ideally, hot-reload the changed module). The same
    goes if you're working on the backend; recompiling and restarting
    the server shouldn't be a manual task.

-   **Running everything locally should be possible (and trivial), but
    optional**: This is somewhat implied by the previous bullet – you
    can't observe your changes if you aren't running the service
    locally. But this also goes for services you have no intention of
    changing, that is, if you're exclusively working on the frontend you
    might still want to run the backend(s) locally simply to have your
    own dataset and ensure that if somehow your staging environment
    breaks you can still work on your feature. Other times you won't
    care and it will be easier to work against the staging environment.
    It should be trivial to change between the two.

This is a rather tall order, but I think we've come pretty close at
Famly. There are two parts to the solution. We've decided to rely on
Docker to run services locally, so for each service we've defined a
specialized Dockerfile for running the service during development.
Secondly we've created a script, `famlydev`, for managing the local
developer environment. First off I'll introduce `famlydev` and then I'll
show the patterns we've arrived at for creating Docker images that work
well for development.

## famlydev

We decided to create a single Git repository that contains all of our
code related to managing the developer environment. This repository is
the main entrypoint for developers and it takes care of setting up the
developer environment, as well as managing it once it's running.

<a href="/images/famlydev.png" target="_blank">
    <img src="/images/famlydev.png" width="100%"/>
</a>

It consists of a rather small
[Makefile](http://blog.mads-hartmann.com/2016/08/20/make.html), a collection
of Bash scripts, and a very small README. The Makefile take care of
cloning the relevant Famly repositories, installing various system
dependencies (such as Docker and the docker-rsync gem) as well as
installing our home-grown `famlydev` script which is the developers
interface to the developer environment. It also knows when to rebuild
the various Docker images. This is how we've achieved the **100%
automated setup**.

The repository also contains a collection of `docker-compose.yml`
definitions. Currently we have one for each common use-case and you can
switch between them using `famlydev switch fullstack|frontend|backend`.
This is how we've made it **optional to run some services locally**. For
now having these predefined configurations works well for us but I can
imagine that in the future we'll want to make it easier to pick and
chose which services to run.

I think having a script like `famlydev` is a crucial part of creating a
great automated development environment. It also makes it easy to share
automated work-flows. As an example, the other day my coworker
[Christian](https://twitter.com/Chr_Harrington) added a new command `db`
which for now has one use-case, `famlydev db regen`, which will nuke the
current database and re-run migrations to provide a clean database. To
make `famlydev` easier and more enjoyable to use we've implemented
context-sensitive tab-completion (just for ZSH for now) – that is
`famlydev kick <tab>` will tab-complete based on the services you have
running – and you can get more information about each command using
`famlydev help <command>`.

## A single service

For each service we've created a
[Dockerfile](https://docs.docker.com/engine/reference/builder/). These
Dockerfiles are slightly different from ones you would normally create
for a production environment. They only install the required system
libraries and don't contain any of the source code or library
dependencies (though we do warm-up the relevant caches so you don't have
to wait for `yarn`, or similar tools, to finish downloading whenever you
boot the service). The images are empty shells that only work if you
mount in the source code from the host – I'll get to why we've chosen
this approach later.

Each service has an
[entrypoint](https://docs.docker.com/engine/reference/builder/#/entrypoint)
script which generally follow the same structure.

-   Install library dependencies (e.g. `yarn install` for the frontend)

-   Start the service in the background (For our PHP code that would be
    Apache). This service should know how to react to changes to the
    source code.

-   Detect if a configuration (like `package.json` or `composer.json`)
    file changes (detected using
    [inotify](http://man7.org/linux/man-pages/man7/inotify.7.html)) or a
    [SIGHUP](https://en.wikipedia.org/wiki/Unix_signal#SIGHUP) signal is
    sent and then re-install library dependencies and restart the
    service. The `SIGHUP` signal enables us to use
    `famlydev kick <service>` if a service gets stuck for one reason or
    another.

This approach is working nicely for us. The advantage of not having
baked very much into the images is that we can re-use a running
container in many different environments. For example you can switch
between the master and staging branches and the container will perform
the necessary steps. This means that for the most part you don't worry
about the containers. You simply run `famlydev up` in the morning and
`famlydev down` when you leave. You can keep switching branches, adding
library dependencies or changing the source code as you always have.

## Going Forward

The current state of `famlydev` is the result of roughly 2 months of
experimenting with various solutions. So far I'm happy with the approach
of using Make for setup and dependency tracking, docker-compose for
configuring which services to run, and Bash for providing the developer
with an enjoyable CLI.

I have no doubt that over the next couple of months we'll continue to
improve it and try out new things. I'll keep you posted. If you've done
something similar, or solved the same problems in a different way I'd
love to hear about it.


FROM gitpod/workspace-full:latest

RUN cd /usr/local && \
    curl -L https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.2.19 sudo sh

RUN go install cuelang.org/go/cmd/cue@latest

$(if $(shell which jekyll),,$(error "Jekyll is required."))

SHELL = /usr/bin/env bash
QUIET ?= @

build: ; ./_scripts/build.sh
clean: ; $(QUIET)rm -f $(build_targets)
distclean: ; $(QUIET)rm -rf $(distclean_targets)
watch: ; ./_scripts/watch.sh

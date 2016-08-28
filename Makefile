$(if $(shell which jekyll),,$(error "Jekyll is required."))

SHELL = /usr/bin/env bash
QUIET ?= @

org_version := 8.3.4
emacs_daemon_name := mads-hartmann-github-com

src.dir := _org/_posts
build.dir := _posts
setup.dir := _setup

# Find the names of all the.org files, prefix the with the build dir
# and change the extension from .org to .html. The result is all the
# html files we want yo produce.
build_targets := \
	$(patsubst %.org,%.html, \
		$(addprefix $(build.dir)/, \
			$(notdir $(wildcard $(src.dir)/*.org))))

watch_targets := \
	_watch-continous-make \
	_watch-jekyll-server \
	_watch-emacs-server

setup_targets := \
	$(setup.dir) \
	$(setup.dir)/org-$(org_version)

distclean_targets := \
	$(setup.dir) _site

#
# Targets - The ones that's exposed to the user.
#

build: $(build_targets)

clean:
	$(QUIET)rm -f $(build_targets)

distclean:
	$(QUIET)rm -rf $(distclean_targets)

watch:
	$(call make-parallel, $(watch_targets))

setup: $(setup_targets)

#
# Targets - The implementation of the various watch related targets.
#

# Calls `make build` every second.
_watch-continous-make:
	$(QUIET)while true; do \
		sleep 1; \
		$(MAKE) \
			-f $(firstword $(MAKEFILE_LIST)) \
			--no-print-directory \
			build WATCH_MODE=1 \
		| grep -v "Nothing to be done for" ; \
	done

# Starts emacs in server-mode, blocks until SIGINT/SIGHUP/SIGKILL is
# sent and then shuts down the emacs server instance.
_watch-emacs-server:
	$(QUIET)emacs \
		--quick \
		--directory $(abspath $(setup.dir)/org-$(org_version)/lisp) \
		--script init.el \
		--daemon=$(strip $(emacs_daemon_name)) $(if $(QUIET),&> /dev/null,)
	$(QUIET)sh wait-and-shutdown.sh $(emacs_daemon_name)

# Starts jekyll in watch-mode.
_watch-jekyll-server:
	$(QUIET)jekyll serve \
		--quiet \
		--watch \
		--host localhost \
		--port 8080 $(if $(QUIET),> /dev/null,)

#
# Targets - The implementation of various setup targets
#

$(setup.dir):
	mkdir -p $(setup.dir)

$(setup.dir)/org-$(org_version): $(setup.dir)
	curl "http://orgmode.org/org-$(org_version).tar.gz" \
        | tar xz -C $(setup.dir)

#
# Helpful targets
#

# Show the content of variable %
print-%:
print-%: ; @echo $* is $($*)

#
# Rules
#

$(build.dir)/%.html: $(src.dir)/%.org
	$(call build-rule.org, $<)

#
# Functions
#

# $(call print-rule, variable, extra)
#   Used to decorate the output for each function *-rule below
define print-rule
	@echo "[$(shell date +%H:%M:%S)] $(strip $1): $(strip $2)"
endef

# $(call build-rule.org, org-file)
#   Used to build a .html file from an .org file. If WATCH_MODE is set
#   it will use emacsclient to connect to an emacs daemon instead.
ifndef WATCH_MODE
define build-rule.org
	$(call print-rule, $0, $1)
	$(QUIET)emacs \
		--quick \
		--directory $(abspath $(setup.dir)/org-$(org_version)/lisp) \
		--script init.el \
		--eval "(org-publish-file \"$(abspath $1)\" nil nil)" $(if $(QUIET),&> /dev/null,)
endef
else
define build-rule.org
	$(call print-rule, $0 [watch], $1)
	$(QUIET)emacsclient \
		--server-file=$(strip $(emacs_daemon_name)) \
		--eval "(org-publish-file \"$(abspath $1)\" nil nil)" $(if $(QUIET),&> /dev/null,)
endef
endif

# $(call make-parallel, targets)
#   Runs (sub) make targets, with each target running in a separate process
define make-parallel
	$(call print-rule,$0,$1 - [$(words $1) targets])
	$(QUIET)echo $1 \
	| xargs \
		-n 1 \
		-P $(words $(sort $1)) \
		$(MAKE) --no-print-directory -f $(firstword $(MAKEFILE_LIST))
endef

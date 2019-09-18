### User-changable variables.

BUILD_DIR := _build

### Variables

markdown_sources := \
	$(shell find site -name "*.md")

html_pages := \
	$(foreach f, $(markdown_sources), \
		$(subst site/,$(BUILD_DIR)/, \
			$(dir $(f)))$(basename $(notdir $(f)))/index.html)

# Alternative way to achieve the same thing as html_pages
html_pages_alternative := \
	$(patsubst site/%.md,$(BUILD_DIR)/%/index.html,$(markdown_sources))

### Targets

build: setup $(html_pages)
setup: node_modules/.installed
clean: ; rm -rf $(BUILD_DIR)
distclean: ; rm -rf $(BUILD_DIR) node_modules
print-%: ; @echo $* is $($*)

### Rules

$(BUILD_DIR)/%/index.html: site/%.md
	@mkdir -p $(dir $@)
	node_modules/.bin/marked --input $< --output $@

node_modules/.installed: requirements.txt
	rm -rf node_modules
	npm install $(shell cat $<)
	touch $@

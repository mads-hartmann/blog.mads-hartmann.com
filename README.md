# mads-hartmann.com

## With Docker

```sh
docker-compose up
```

## Without Docker

This depends on having [Ruby](https://www.ruby-lang.org/en/) and [Bundler](https://rubygems.org/gems/bundler) installed locally.

```sh
bundle install
bundle exec jekyll serve \
    --watch \
    --drafts \
    --source mads-hartmann.com
```

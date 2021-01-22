# mads-hartmann.com

## With Docker

```sh
docker-compose up
```

To get a clean install in case I've changed the Gemfile, configuration, and things like that.

```sh
docker-compose up --build --renew-anon-volumes
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

---
layout: post
title: "Dealing with multiple AWS profiles"
date:   2017-04-27 18:00:00
---

I use [AWS][aws] in two different contexts. We use it quite extensively at
[Famly][famly] and personally I use it for various smaller hobby projects.

For one of my hobby project I wrote a small python script that automates the
setup and deployment of [AWS Lambda's][aws-lambda], [API Gateway][api-gateway],
etc. so the script is creating and deleting a bunch of different AWS entities.
You can probably already guess what happened. One night I ran my deployment
script while using the AWS profile for Famly's staging environment which
resulted in my little script going rogue and deleting all of our lambdas in the
staging environment 😱

After having panicked for a bit I decided it might be best to find a proper way
to deal with having multiple AWS profiles; this blog post outlines my current
approach.

## Basics of AWS config

The AWS CLI (and SDK) supports multiple profiles very well. You can create a
profile by using `aws configure --profile myprofile`. Your configuration and
credentials are stored in `~/.aws/config` and `~/.aws/credentials` respectively
and it looks something like this

```
$ cat ~/.aws/config
[profile myprofile]
region = eu-central-1
```

```
$ cat ~/.aws/credentials
[myprofile]
aws_access_key_id = ...
aws_secret_access_key = ...
```

When deciding which profile to use the AWS CLI will consider the following
sources.

1. Optional `--profile` arugment to your command.
   Example `aws --profile myprofile s3 ls`
2. The environment variable `AWS_PROFILE`.
   Example `AWS_PROFILE=myprofile aws s3 ls`
3. The environment variable `AWS_DEFAULT_PROFILE`.
   Example `AWS_DEFAULT_PROFILE=myprofile aws s3 ls`

If you don't specify a profile it will use the `default` profile. See the
[documentation][aws-cli-configuration] for more information.

## Don't have a default profile

**Update(2020-10-31):** In [Abusing the AWS SDK](https://blog.ryanjarv.sh/2020/10/17/abusing-the-aws-sdk.html) Ryan shows how it's possible for an attacker with access to your local subset to potentially steal secrets uploaded to the SSM parameter store. When you don't have a default profile set, the AWS CLI will try to ask a locally running meta-data server for credentials. The attacker can run their own little meta-data server and serve a set of credentials they control. It's a bit of en edge case, but if you want to get around it you have to set `AWS_EC2_METADATA_DISABLED=true` in your shell.

Don't set `AWS_PROFILE` or `AWS_DEFAULT_PROFILE` or any of the other
environment variables in your shell's profile file (`~/.zshrc`, `~/.profile`,
etc.). Remove any information your have in the `[default]` section of your
`~/.aws/config` and `~/.aws/credentials` files.

This way you always have to explicitly specify which profile to use.

## Switch between profiles

Switching between profiles is now simply a matter of setting `AWS_PROFILE`.
To do this I've created a little convenience [Zsh][zsh] function `aws-switch`

```zsh
function aws-switch() {
    case ${1} in
        "")
        clear)
            export AWS_PROFILE=""
            ;;
        *)
            export AWS_PROFILE="${1}"
            ;;
    esac
}
```

And as always it's nice to provide a little completion script

```zsh
#compdef aws-switch
#description Switch the AWS profile

_aws-switch() {

    local -a aws_profiles

    aws_profiles=$( \
        grep '\[profile' ~/.aws/config \
        | awk '{sub(/]/, "", $2); print $2}' \
        | while read -r profile; do echo -n "$profile "; done \
    )

    _arguments \
        ':Aws profile:($(echo ${aws_profiles}) clear)'
}

_aws-switch "$@"
```

## Show the active AWS profile in prompt

Now that you always know which AWS profile the CLI is going to use and you have
a convenient way to switch between your profiles the final piece is to ensure
that you're always aware which profile is active.

The best way I've found to do this is simply to put it in your prompt. You can
see my prompt configuration in my [~/.zshrc][zshrc] file.

**TIP** Give your profiles names that you'll notice. I named my profile for
Famly's staging environment 🔥🔥🔥 which should hopefully signal an alarm the
next time I'm hacking around 😆

[aws]: https://aws.amazon.com
[aws-lambda]: aws.amazon.com/lambda
[api-gateway]: aws.amazon.com/api-gateway‎
[famly]: https://famly.co/about
[aws-cli-configuration]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
[zsh]: http://www.zsh.org/
[zshrc]: https://github.com/mads-hartmann/dotfiles/blob/master/home/zshrc

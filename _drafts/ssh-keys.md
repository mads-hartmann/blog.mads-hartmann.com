# ssh keys

At some point I'd like to act like a responsible developer and have a
tidy setup with my SSH keys. The following are notes I did one evening
when I tried to clean up my setup a bit. I never got around to
finishing this post - for now.

--

A very brief blog post about ssh keys.

Short outline of how it works. There's a ssh-agent running etc.

How to add keys (ssk-add), remove keys, list keys (ssh-add -l).

Q: Using multiple identities. This gist has a couple of good comments.
https://gist.github.com/jexchan/2351996#gistcomment-1322912 it seems
that a combination of using ssh-add -K to store password in the
keychain and then using the `~/.ssh/config` to tell ssh which identities
to use it a good combination.

Q: How many identities does it load during boot?

Steps

- Generate a key and use a pass phrase
- Add the key to you ssh agent and store the passphrse in your key-chain
  ssh add -K ~/.ssh/config/xyx
- Update your ~/.ssh/config so it knows to you that one for github and use the keychian

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github
  UseKeychain yes
  IdentitiesOnly yes

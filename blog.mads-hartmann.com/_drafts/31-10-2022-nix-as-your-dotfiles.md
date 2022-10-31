"Nix for portable dotfiles"

	Idea:
		- Have a shell.nix file in a repo which contains your shell config
			Example: 
				- starship (for a nice shell)
				- cheat ( or other tldr tools)
				- kubectl, maybe that log tool
		- Show how to start a shell loading that env remotely (e.g. a one-liner I can use in a Gitpod Workspace or Google Cloud Shell)


---

NOTE: I started playing around with this in the nix branch of computer.mads-hartmannn.com

I'm playing around withe a folder structure like this:
	
www
    Anything related to the actual site
nix
    fragments
        kubernetes.nix
            kubens
            kubectx
            kubectl
            stern
            (Any other nice tools)
        tailscale.nix
    envs
        gitpod.nix -> kubernetes.nix, tailscale.nix
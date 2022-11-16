FROM madshartmann/gitpod-nix-base:1

# This populates the Nix store with all the packages needed by shell.nix
#
# Ideally I would have placed this in an 'init' task in my gitpod.yml but at the moment
# Gitpod Prebuilds only save files stored in /workspace. The nix store is located in /nix and
# I wasn't able to move it to /workspace/nix so as a temporary workaround we populate the nix store
# here in the Dockerfile instead.
#
# Gitpod only rebuilds the image when the Dockerfile changes (it appears) so I'm using this
# environment variable to manually bump the version whenever I want it to trigger a prebuilt.
ENV TRIGGER_PREBUILD=1
COPY ./nix /workspace/nix-boot/nix
COPY ./shell.nix /workspace/nix-boot/shell.nix
RUN . /home/gitpod/.nix-profile/etc/profile.d/nix.sh \
    && cd /workspace/nix-boot \
    && nix-shell --run "exit 0"

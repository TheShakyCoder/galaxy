# Nakama with this project's runtime modules baked in, for the Coolify
# deploy (docker-compose.coolify.yml). Copying modules/ into the image means
# every deploy ships exactly the modules in the commit being deployed,
# without relying on a bind mount of the repository on the Coolify host.
# Local dev (docker-compose.yml) still bind-mounts this folder so module
# edits only need a restart.
# Docker Hub's copy of the official image (same digest as
# registry.heroiclabs.com/heroiclabs/nakama:3.37.0, sha256:b475a1d7...).
# Coolify builds with --pull, and Heroic's registry rate-limits (429) repeated
# pulls from one server; Docker Hub's anonymous limit is far higher.
FROM docker.io/heroiclabs/nakama:3.37.0
COPY modules /nakama/data/modules

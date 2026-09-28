# Nakama with this project's runtime modules baked in, for the Coolify
# deploy (docker-compose.coolify.yml). Copying modules/ into the image means
# every deploy ships exactly the modules in the commit being deployed,
# without relying on a bind mount of the repository on the Coolify host.
# Local dev (docker-compose.yml) still bind-mounts this folder so module
# edits only need a restart.
FROM registry.heroiclabs.com/heroiclabs/nakama:3.37.0
COPY modules /nakama/data/modules

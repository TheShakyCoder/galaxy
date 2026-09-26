# Deploying Galaxy on Coolify

Galaxy runs as two Coolify resources, both built from this public repo
(`https://github.com/TheShakyCoder/galaxy`):

| Resource | Build pack | Source | Serves |
|---|---|---|---|
| **galaxy-server** | Docker Compose | `nakama-server/docker-compose.coolify.yml` | Nakama + Postgres at `https://galaxy-api.stupidly.uk` |
| **galaxy-web** | Dockerfile | `Dockerfile` (repo root) | HTML5 build of the game at `https://galaxy.stupidly.uk` |

```
 browser ──https──▶ galaxy.stupidly.uk      ──▶ galaxy-web (nginx, static files)
    │
    └──https/wss──▶ galaxy-api.stupidly.uk  ──▶ galaxy-server: nakama :7350 ──▶ postgres
                    (Coolify proxy, TLS)
```

The web build gets the server address when it's built, not at runtime. If you
change the API domain or server key, redeploy **galaxy-web** too.

---

## 0. Prerequisites

- A Coolify server with outbound internet (the web build downloads `bob.jar`
  and compiles native extensions on Defold's build server, `build.defold.com`).
- Two DNS `A` records pointing at the Coolify server:
  `galaxy.stupidly.uk` and `galaxy-api.stupidly.uk`.
- Secrets to paste into Coolify. Generate them locally:

  ```sh
  for v in POSTGRES_PASSWORD NAKAMA_SERVER_KEY NAKAMA_CONSOLE_PASSWORD \
           NAKAMA_CONSOLE_SIGNING_KEY NAKAMA_SESSION_ENCRYPTION_KEY \
           NAKAMA_REFRESH_ENCRYPTION_KEY NAKAMA_HTTP_KEY; do
    echo "$v=$(openssl rand -hex 24)"
  done
  ```

  Keep this output somewhere safe, such as a password manager. Never commit it.

---

## 1. Deploy the Nakama server (galaxy-server)

1. **Projects → your project → + New → Public Repository**
   - Repository URL: `https://github.com/TheShakyCoder/galaxy`
   - Branch: `master`
   - Build pack: **Docker Compose**
   - Base Directory: `/nakama-server`
   - Docker Compose Location: `/docker-compose.coolify.yml`

   Use the `.coolify.yml` file, **not** `docker-compose.yml`. The plain file
   is for local development only: it publishes host ports 7349–7351 and uses
   fixed container names, which would clash with any other Nakama (e.g.
   SuperShips) on the same server.

2. **Environment Variables:** Coolify lists every required variable from the
   compose file. Fill them in from the generated secrets, and set a username:

   | Variable | Value |
   |---|---|
   | `POSTGRES_PASSWORD` | generated |
   | `NAKAMA_SERVER_KEY` | generated. You'll reuse this for galaxy-web |
   | `NAKAMA_CONSOLE_USERNAME` | e.g. `admin` |
   | `NAKAMA_CONSOLE_PASSWORD` | generated |
   | `NAKAMA_CONSOLE_SIGNING_KEY` | generated |
   | `NAKAMA_SESSION_ENCRYPTION_KEY` | generated |
   | `NAKAMA_REFRESH_ENCRYPTION_KEY` | generated |
   | `NAKAMA_HTTP_KEY` | generated |

   A missing variable makes the deploy fail rather than fall back to Nakama's
   well-known defaults. That's on purpose.

3. **Domains:** on the `nakama` service, set
   `https://galaxy-api.stupidly.uk:7350`. The `:7350` tells Coolify's proxy
   which container port to route to. Players still connect on 443. Give
   `postgres` no domain.

   *Optional admin console:* add a second domain to the `nakama` service,
   e.g. `https://galaxy-admin.stupidly.uk:7351`. It's protected only by the
   console username and password, so leave it off unless you need it.

4. **Deploy**, then check:

   ```sh
   curl https://galaxy-api.stupidly.uk/healthcheck
   # → {}
   ```

   Postgres data is kept in the `data` volume and survives redeploys.
   Schedule backups under the resource's **Backups** / **Storages** tab.

---

## 2. Deploy the web client (galaxy-web)

1. **+ New → Public Repository** again, same repository and branch.
   - Build pack: **Dockerfile**
   - Base Directory: `/`
   - Dockerfile Location: `/Dockerfile`
   - Ports Exposes: `80`

2. **Environment Variables:** add these and tick **Build Variable** /
   **Available at Buildtime** on each (the label varies by Coolify version).
   They go into the bundle at build time and do nothing at runtime.

   | Variable | Value |
   |---|---|
   | `NAKAMA_HOST` | `galaxy-api.stupidly.uk` (no `https://`, no port) |
   | `NAKAMA_PORT` | `443` |
   | `NAKAMA_USE_SSL` | `1` |
   | `NAKAMA_SERVER_KEY` | same value as galaxy-server's `NAKAMA_SERVER_KEY` |
   | `DEFOLD_VERSION` | *(optional)* defaults to `1.13.1` |

   The server key ships inside every client build, so it identifies the
   client rather than acting as a secret. The Docker `SecretsUsedInArgOrEnv`
   warning about it in the build log is expected. The other galaxy-server
   variables are real secrets and never go here.

3. **Domains:** `https://galaxy.stupidly.uk`

4. **Deploy.** The first build takes a few minutes: it resolves the
   `game.project` dependencies and sends the native extensions to Defold's
   build server. Then open `https://galaxy.stupidly.uk`.

---

## 3. Auto-deploy on push (optional)

Public-repository resources don't deploy on push by default. Either:

- switch the source to a **GitHub App** (Sources → + Add → GitHub App), or
- use each resource's **Webhooks** tab to set a GitHub webhook secret, then
  add that webhook URL under GitHub → repo **Settings → Webhooks**.

Then set **Watch Paths** so each resource rebuilds only when its own files
change:

- galaxy-server: `nakama-server/**`
- galaxy-web:
  ```
  main/**
  assets/**
  input/**
  render/**
  game.project
  Dockerfile
  deploy/**
  ```

---

## How the server address reaches the game

`main/network.lua` reads its connection settings from the `[nakama]` section
of `game.project`:

```ini
[nakama]
host = 127.0.0.1
port = 7350
use_ssl = 0
server_key = defaultkey
```

The committed values point at the local docker-compose server, so running the
game from the Defold editor still works with
`docker compose up` in `nakama-server/`. The `Dockerfile` writes the build
variables to an override file and passes it to bob with `--settings`, which
replaces only those keys in the web build.

## Building and testing the web image locally

```sh
docker build -t galaxy-web \
  --build-arg NAKAMA_HOST=127.0.0.1 --build-arg NAKAMA_PORT=7350 .
docker run --rm -p 8080:80 galaxy-web
# open http://localhost:8080, with the local Nakama running
# (cd nakama-server && docker compose up)
```

Only the single-threaded `wasm-web` target is built. The pthread variant needs
cross-origin isolation headers (COOP/COEP), and those break third-party
scripts such as the Poki SDK.

## Upgrading Defold

When you upgrade the Defold editor, update `DEFOLD_VERSION` to match (the
`ARG` default in `Dockerfile`, or the Coolify build variable). If a new
release changes its bundled JDK, update the `eclipse-temurin:<N>-jdk` tag to
match. The editor's JDK is in
`Defold.app/Contents/Resources/packages/jdk-*`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Game loads but never connects; console shows *mixed content* | `NAKAMA_USE_SSL` isn't `1`. An https page can't open `ws://`. |
| `401` / *Server key invalid* | `NAKAMA_SERVER_KEY` differs between the two resources. Fix it, then redeploy galaxy-web. |
| Still connecting to the old server after changing variables | Build variables apply only on rebuild. Redeploy galaxy-web and hard-refresh the browser. |
| Build fails at `resolve` or `Building engine` | No outbound internet from the build, or `build.defold.com` is down. Retry. |
| Build fails with `UnsatisfiedLinkError … .so` | The build image is missing a system library bob needs. Add it to the `apt-get install` line. |
| `Platform … not supported` | `bob.jar` version doesn't match the flags. Keep `DEFOLD_VERSION` current. |
| Nakama container restarts in a loop | A required variable is empty, or `POSTGRES_PASSWORD` changed after the database was first created. Postgres keeps the original password; restore it or reset the volume. |

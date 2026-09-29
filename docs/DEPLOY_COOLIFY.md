# Deploying Galaxy on Coolify

Galaxy runs as three Coolify resources:

| Resource | Build pack | Source | Serves |
|---|---|---|---|
| **galaxy-site** | Dockerfile | the website repo (`TheShakyCoder/galaxy-laravel`) | Laravel website at `https://fig.limited`: accounts, dashboard, Play |
| **galaxy-server** | Docker Compose | this repo, `nakama-server/docker-compose.coolify.yml` | a game server: Nakama + Postgres at `https://api1.fig.limited` |
| **galaxy-web** | Dockerfile | this repo, `Dockerfile` (root) | HTML5 build of the game at `https://play.fig.limited` |

```
 browser ──https──▶ fig.limited        ──▶ galaxy-site (Laravel): register, log in, Play
    │
    ├──https──▶ play.fig.limited ──▶ galaxy-web (nginx) ──asks──▶ fig.limited: logged in?
    │             (game files only for logged-in players; /play-token passed to the site)
    │
    └──https/wss──▶ api1.fig.limited ──▶ galaxy-server: nakama :7350 ──▶ postgres
                    (Coolify proxy, TLS)
```

Accounts live on the website. When a verified player presses Play, the site
picks a game server (a row in its `game_servers` table) and the game fetches a
short-lived **play token** from it, signed with that server's
`PLAY_TOKEN_SECRET`. The game signs in to that server's Nakama with it
(`nakama-server/modules/auth.lua`). The site tells the game which server to
connect to at runtime, so adding a server needs no game rebuild.

---

## 0. Prerequisites

- A Coolify server with outbound internet (the web build downloads `bob.jar`
  and compiles native extensions on Defold's build server, `build.defold.com`).
- DNS `A` records pointing at the Coolify server: `fig.limited`,
  `www.fig.limited`, `play.fig.limited` and `api1.fig.limited`.
- Secrets to paste into Coolify. Generate them locally:

  ```sh
  for v in POSTGRES_PASSWORD NAKAMA_SERVER_KEY NAKAMA_CONSOLE_PASSWORD \
           NAKAMA_CONSOLE_SIGNING_KEY NAKAMA_SESSION_ENCRYPTION_KEY \
           NAKAMA_REFRESH_ENCRYPTION_KEY NAKAMA_HTTP_KEY TICKET_SECRET; do
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
   SuperShips) on the same server. The `.coolify.yml` file also builds Nakama
   from `nakama-server/Dockerfile`, which copies `modules/` (sign-in,
   economy and the shared game rules) into the image, so each deploy runs
   the modules from the commit being deployed.

2. **Environment Variables:** Coolify lists every required variable from the
   compose file. Fill them in from the generated secrets, and set a username:

   | Variable | Value |
   |---|---|
   | `POSTGRES_PASSWORD` | generated |
   | `NAKAMA_SERVER_KEY` | generated. The website hands it to the game (`--server-key` in step 4) |
   | `NAKAMA_CONSOLE_USERNAME` | e.g. `admin` |
   | `NAKAMA_CONSOLE_PASSWORD` | generated |
   | `NAKAMA_CONSOLE_SIGNING_KEY` | generated |
   | `NAKAMA_SESSION_ENCRYPTION_KEY` | generated |
   | `NAKAMA_REFRESH_ENCRYPTION_KEY` | generated |
   | `NAKAMA_HTTP_KEY` | generated. The website uses it for server-to-server calls |
   | `TICKET_SECRET` | generated. Signs the tickets players use to enter a star system |
   | `SERVER_ID` | this server's slug on the website, e.g. `api1` |
   | `PLAY_TOKEN_SECRET` | printed by `php artisan galaxy:server` on the website (step 4 below) |

   Mark them **Available at Runtime** only; none is needed at build time
   (the image build just copies the modules). If one is missing, Nakama
   refuses to start and its log says which ("required setting … is empty"),
   rather than running on Nakama's well-known defaults. That's on purpose.

3. **Domains:** on the `nakama` service, set
   `https://api1.fig.limited:7350`. The `:7350` tells Coolify's proxy
   which container port to route to. Players still connect on 443. Give
   `postgres` no domain.

   *Optional admin console:* add a second domain to the `nakama` service,
   e.g. `https://admin.fig.limited:7351`. It's protected only by the
   console username and password, so leave it off unless you need it.

4. **Deploy**, then check:

   ```sh
   curl https://api1.fig.limited/healthcheck
   # → {}
   ```

   Postgres data is kept in the `data` volume and survives redeploys.
   Schedule backups under the resource's **Backups** / **Storages** tab.

5. **Register it on the website.** In galaxy-site's **Terminal** (Coolify),
   run:

   ```sh
   php artisan galaxy:server api1 --name="Api One" --host=api1.fig.limited \
     --server-key=<NAKAMA_SERVER_KEY> --http-key=<NAKAMA_HTTP_KEY>
   ```

   It prints `SERVER_ID` and a new `PLAY_TOKEN_SECRET`. Set both on
   galaxy-server and redeploy it. Run the command again with `--closed` to
   stop players joining, or with new values to change them (secrets are kept
   unless you pass new ones).

---

## 2. Deploy the web client (galaxy-web)

1. **+ New → Public Repository** again, same repository and branch.
   - Build pack: **Dockerfile**
   - Base Directory: `/`
   - Dockerfile Location: `/Dockerfile`
   - Ports Exposes: `80`
   - Health check path: `/healthz` (everything else needs a login)

2. **Environment Variables:** none are required.

   | Variable | Value |
   |---|---|
   | `LARAVEL_URL` | *(optional, runtime)* the website, default `https://fig.limited` |
   | `DEFOLD_VERSION` | *(optional, build-time)* defaults to `1.13.1` |

   nginx asks `LARAVEL_URL/play/auth-check` on every page load and sends
   anyone not logged in to `LARAVEL_URL/login`. The game server address comes
   from the website at runtime, so the old `NAKAMA_*` build variables are only
   used by debug builds and can be removed.

3. **Domains:** `https://play.fig.limited`

4. **Deploy.** The first build takes a few minutes: it resolves the
   `game.project` dependencies and sends the native extensions to Defold's
   build server. Then open `https://play.fig.limited`.

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

## The website (galaxy-site)

Deployed from its own repo with its own Dockerfile (see that repo). Besides
its database and mail settings, it needs:

| Variable | Value |
|---|---|
| `SESSION_DOMAIN` | `.fig.limited`, so the login cookie also reaches `play.fig.limited` |
| `GALAXY_PLAY_URL` | *(optional)* default `https://play.fig.limited` |

## Switching to website accounts (0.2.0)

Game servers no longer have email accounts, so existing players can't carry
over. Wipe the game server's database once when deploying 0.2.0: stop
galaxy-server, delete its `data` volume (**Storages** tab), then deploy. This
permanently deletes all accounts and progress on that server.

## How the server address reaches the game

Release builds get it from the website (`/play-token`). Debug builds signing
in with a dev token (`php artisan galaxy:dev-token` on a local website, then
`#dev_token=...` on the page or `GALAXY_PLAY_TOKEN` for desktop builds) use
the `[nakama]` section of `game.project`:

```ini
[nakama]
host = 127.0.0.1
port = 7350
use_ssl = 0
server_key = defaultkey
```

The committed values point at the local docker-compose server
(`docker compose up` in `nakama-server/`).

## Building and testing the web image locally

```sh
docker build -t galaxy-web .
docker run --rm -p 8080:80 -e LARAVEL_URL=https://fig.limited galaxy-web
curl -i http://localhost:8080/          # 302 to the login page
curl -i http://localhost:8080/healthz   # 200
```

Only the single-threaded `wasm-web` target is built. The pthread variant needs
cross-origin isolation headers (COOP/COEP), and those break third-party
scripts loaded from other domains.

## Upgrading Defold

When you upgrade the Defold editor, update `DEFOLD_VERSION` to match (the
`ARG` default in `Dockerfile`, or the Coolify build variable). If a new
release changes its bundled JDK, update the `eclipse-temurin:<N>-jdk` tag to
match. The editor's JDK is in
`Defold.app/Contents/Resources/packages/jdk-*`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `play.fig.limited` always redirects to the login page, even when logged in | galaxy-site's `SESSION_DOMAIN` isn't `.fig.limited` (log in again after changing it), or `LARAVEL_URL` is wrong. |
| Game says *Your login has expired* straight away | The game server refused the play token: `PLAY_TOKEN_SECRET` or `SERVER_ID` on galaxy-server doesn't match the website's `galaxy:server` row. |
| Game loads but never connects; console shows *mixed content* | The website's server row is `--insecure`. An https page can't open `ws://`. |
| `401` / *Server key invalid* | The website's `--server-key` for that server differs from galaxy-server's `NAKAMA_SERVER_KEY`. |
| Dashboard says a server can't be reached | Wrong `--http-key`, or the website can't reach the server's address. |
| Build fails at `resolve` or `Building engine` | No outbound internet from the build, or `build.defold.com` is down. Retry. |
| Build fails with `UnsatisfiedLinkError … .so` | The build image is missing a system library bob needs. Add it to the `apt-get install` line. |
| `Platform … not supported` | `bob.jar` version doesn't match the flags. Keep `DEFOLD_VERSION` current. |
| Nakama container restarts in a loop | A required variable is empty, or `POSTGRES_PASSWORD` changed after the database was first created. Postgres keeps the original password; restore it or reset the volume. |

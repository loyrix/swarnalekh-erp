# Cloudflare — Flutter web PWA

The Flutter app in `apps/mobile` is deployed as a PWA to Cloudflare, built from
`main` on every push. The NestJS API stays on Vercel; this covers only the web
client.

Cloudflare was chosen because its free tier permits commercial use, which
Vercel's Hobby plan does not. Bandwidth was not the deciding factor: Vercel's
100 GB/month would comfortably serve this app.

It runs on **Workers static assets**, not Pages. Cloudflare now steers new
projects to Workers, and the dashboard's "Create application" flow builds a
Worker even when the goal is a static site. The practical differences from
Pages: configuration lives in `wrangler.jsonc` rather than dashboard fields,
there is no "build output directory" setting, and deployment runs through
`npx wrangler deploy`.

## Cloudflare dashboard settings

Create a Worker connected to `loyrix/swarnalekh-erp`, then set:

| Setting        | Value                              |
| -------------- | ---------------------------------- |
| Project name   | `swarnalekh`                       |
| Build command  | `bash scripts/cloudflare-build.sh` |
| Deploy command | `npx wrangler deploy` (default)    |

Everything else — the asset directory, the SPA fallback, the Worker name — is
read from `wrangler.jsonc` at the repo root, so it is version-controlled rather
than living in dashboard state.

The app is served at `swarnalekh.<account-subdomain>.workers.dev`.

## Environment variables

None are required. The only dart-define the app reads is `API_BASE_URL`
(`apps/mobile/lib/core/network/api_client.dart`), and it already defaults to
the production API, so a build with an empty environment is correct.

Set these in the dashboard only if you need to override:

| Variable       | Purpose                                                  |
| -------------- | -------------------------------------------------------- |
| `API_BASE_URL` | Point a preview deployment at a non-production API.      |
| `FLUTTER_REF`  | Pin the Flutter SDK to a tag/branch instead of `stable`. |

The `SUPABASE_URL` / `SUPABASE_ANON_KEY` entries in `apps/mobile/.env` are
vestigial — there is no Supabase package in `pubspec.yaml` and nothing reads
them. Do not copy them into Cloudflare.

## How the build works

`scripts/cloudflare-build.sh` clones the Flutter SDK (Cloudflare's build image
has Node but no Flutter), writes a generated `apps/mobile/.env.cloudflare.local`,
and runs `flutter build web --release --dart-define-from-file=...` — the same
mechanism `scripts/flutter_with_env.sh` uses locally, so local and deployed
builds are configured identically. `npx wrangler deploy` then uploads
`apps/mobile/build/web` as declared in `wrangler.jsonc`.

The clone adds roughly 1-2 minutes per build, putting a full build in the 5-8
minute range.

The script is safe to run on a dev machine (`pnpm web:build:cloudflare`): it
reuses a `flutter` already on `PATH` rather than cloning a second SDK, and
writes to a scratch env file rather than overwriting your `apps/mobile/.env`.

## Routing and caching

`apps/mobile/web/_headers` is copied verbatim into `build/web/` by
`flutter build web` and applied by Cloudflare when serving assets.

- **Routing.** go_router runs on the default hash strategy (`/#/route`), so
  every request already lands on `index.html` and no rewrite is strictly
  needed. `not_found_handling: "single-page-application"` in `wrangler.jsonc`
  is the SPA fallback, kept so deep links survive a later move to
  `usePathUrlStrategy`.
- **Caching.** Flutter's entrypoints (`index.html`, `flutter_bootstrap.js`,
  `main.dart.js`, `flutter_service_worker.js`) are not content-hashed, so they
  are set to revalidate on every request. Without this a returning user stays
  pinned to the previous deploy until their cache expires — the standard
  Flutter-web-on-a-CDN failure. Versioned payloads under `canvaskit/` and
  `assets/` are cached hard.

## Known caveats

- **`flutter_secure_storage` is materially weaker on web.** On Android it is
  backed by the Keystore; on web it is WebCrypto over `localStorage`, so any
  XSS can exfiltrate a session token. This matters more here than in a typical
  app because the PWA holds billing and KYC data.
- **`printing` and `image_picker` behave differently on web.** Invoice printing
  is worth an explicit manual test after any Flutter SDK bump.
- **No Content-Security-Policy is set.** Flutter web needs `wasm-unsafe-eval`
  for CanvasKit, so a naive CSP breaks the app; adding one needs its own pass.
- **Watch the request meter after launch.** The Workers free plan meters
  requests per day. Static asset requests are not supposed to count against
  that on an assets-only Worker, but confirm on the dashboard rather than
  assuming it.

## Rollback

Cloudflare keeps previous versions. Roll back from the dashboard
(the Worker → Deployments → the last good version), no rebuild needed.

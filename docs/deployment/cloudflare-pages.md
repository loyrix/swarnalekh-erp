# Cloudflare Pages — Flutter web PWA

The Flutter app in `apps/mobile` is deployed as a PWA to Cloudflare Pages,
built from `main` on every push. The NestJS API stays on Vercel; this covers
only the web client.

Cloudflare was chosen over the alternatives because its free tier does not
meter bandwidth (Firebase Hosting's Spark tier caps transfer at 360 MB/day,
which a multi-MB CanvasKit bundle burns through quickly) and, unlike Vercel's
Hobby plan, it permits commercial use.

## Cloudflare dashboard settings

Create a Pages project connected to `loyrix/swarnalekh-erp`, then set:

| Setting                | Value                              |
| ---------------------- | ---------------------------------- |
| Framework preset       | None                               |
| Root directory         | `/` (repo root)                    |
| Build command          | `bash scripts/cloudflare-build.sh` |
| Build output directory | `apps/mobile/build/web`            |
| Production branch      | `main`                             |

## Environment variables

None are required. The only dart-define the app reads is `API_BASE_URL`
(`apps/mobile/lib/core/network/api_client.dart`), and it already defaults to
the production API, so a build with an empty environment is correct.

Set these in the Pages dashboard only if you need to override:

| Variable       | Purpose                                                  |
| -------------- | -------------------------------------------------------- |
| `API_BASE_URL` | Point a preview deployment at a non-production API.      |
| `FLUTTER_REF`  | Pin the Flutter SDK to a tag/branch instead of `stable`. |

The `SUPABASE_URL` / `SUPABASE_ANON_KEY` entries in `apps/mobile/.env` are
vestigial — there is no Supabase package in `pubspec.yaml` and nothing reads
them. Do not copy them into Cloudflare.

## How the build works

`scripts/cloudflare-build.sh` clones the Flutter SDK (Pages' image has Node but
no Flutter), writes a generated `apps/mobile/.env.cloudflare.local`, and runs
`flutter build web --release --dart-define-from-file=...` — the same mechanism
`scripts/flutter_with_env.sh` uses locally, so local and deployed builds are
configured identically.

The clone adds roughly 1-2 minutes per build, putting a full build in the 5-8
minute range against Pages' 20-minute timeout and 500 builds/month free limit.

The script is safe to run on a dev machine (`pnpm web:build:cloudflare`): it
reuses a `flutter` already on `PATH` rather than cloning a second SDK, and
writes to a scratch env file rather than overwriting your `apps/mobile/.env`.

## Routing and caching

`apps/mobile/web/_headers` and `apps/mobile/web/_redirects` are copied verbatim
into `build/web/` by `flutter build web`, which is where Pages looks for them.

- **Routing.** go_router runs on the default hash strategy (`/#/route`), so
  every request already lands on `index.html` and no rewrite is strictly
  needed. `_redirects` carries an SPA fallback anyway so deep links keep
  working if the app later adopts `usePathUrlStrategy`.
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

## Rollback

Pages keeps every deployment. Roll back from the dashboard
(Deployments → the last good build → _Rollback to this deployment_); no rebuild
is needed.

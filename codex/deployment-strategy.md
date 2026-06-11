# SwarnaLekh Deployment Strategy

## Source Of Truth

Deployment exists to serve the PDF-defined Jewellery ERP:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

## Active Deployable Parts

- Flutter web/mobile app
- NestJS API
- PostgreSQL database through Prisma
- Provider-neutral bearer JWT auth

## Backend Decision

Keep NestJS.

Reason:

- Current API is NestJS.
- The PDF requires structured modules: inventory, mortgage, billing, reports, auth.
- NestJS modules, guards, DTOs, and services fit this ERP shape.
- Vercel deployment can still be supported with the current NestJS build path.

## Vercel API

The API has:

- `apps/api/vercel.json`
- root `vercel:build:api` script
- root `vercel:dev:api` script

Expected API base:

`https://<deployment-host>/api/v1`

Flutter should receive this through:

`API_BASE_URL`

## Required Environment

API:

- `DATABASE_URL`
- `DIRECT_URL`
- `AUTH_JWT_SECRET`
- `NODE_ENV`

Flutter build:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL`

## Deploy Smoke Test

After deploy, test only the PDF flow:

1. Login.
2. Dashboard loads.
3. Add inventory stock.
4. Search inventory.
5. Create mortgage loan.
6. Collect mortgage interest.
7. Create bill.
8. Confirm inventory is marked sold/reduced.
9. Open invoice history.
10. Check PDF-defined reports.

## Not Part Of Deployment Scope

- Subscription checkout
- Scheme workflows
- Ledger workflows
- Super-admin panel
- Offline sync services
- External rate services

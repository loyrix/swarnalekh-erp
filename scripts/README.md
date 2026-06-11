# Scripts

## Scope

Scripts should support only the PDF-aligned SwarnaLekh product:

`/Users/satyamjaiswal/Downloads/Jewellery ERP System Flow (1).pdf`

Allowed script categories:

- API build and deployment
- Database migration and seed
- Formatting
- Tests
- Flutter analyzer/test/build
- PDF-defined operational smoke tests

Do not add scripts for subscriptions, schemes, ledger, external rate automation, offline sync, or super-admin workflows unless the product scope changes.

## Pre-Commit Hook

The tracked hook lives at:

`.githooks/pre-commit`

It runs:

- staged Prettier check
- Dart format check
- workspace tests
- workspace build
- Flutter analyzer
- Flutter tests
- Flutter web build

# Repository Guidelines

## Project Structure & Module Organization
The Next.js application lives in `src/app` with route handlers, server components, and metadata definitions. Shared UI and business logic sit in `src/components`, `src/hooks`, and `src/lib`, while Genkit agent flows land in `src/ai`. Tests live in `src/__tests__` and `e2e/`, documentation in `docs/`, and PocketBase assets in `pocketbase/`, `pb_data/`, and `pb_migrations/`.

## Build, Test, and Development Commands
Use `npm run dev` to boot the Next.js dev server on port 9002; pair it with `npm run pocketbase` or `./start-servers.sh` when you need the backend. Run `npm run setup:pocketbase` after pulling new migrations. Production builds rely on `npm run build` followed by `npm run start`. The Genkit agent shell runs through `npm run genkit:dev`, with `npm run genkit:watch` for hot reload.

## Coding Style & Naming Conventions
TypeScript is the default; prefer `.tsx` for component surfaces and `.ts` for utilities. Prettier and ESLint enforce formatting via `npm run format` and `npm run lint`; fix warnings locally before pushing. Follow PascalCase for React components (`BookingFormCard.tsx`), camelCase for hooks (`usePocketBase.ts`), and kebab-case directory names under `src/lib`.

## Testing Guidelines
Jest + Testing Library power unit and integration specs stored under `src/__tests__`, using the `*.test.ts` or `*.test.tsx` pattern. Run the suite with `npm run test`, watch changes with `npm run test:watch`, and collect coverage via `npm run test:coverage`; CI expects `npm run test:ci` to pass. Playwright end-to-end specs in `e2e/` execute through `npm run test:e2e`, while `--ui` mode helps debug flaky flows.

## Commit & Pull Request Guidelines
Adopt a Conventional Commit-style prefix (`feat:`, `fix:`, `chore:`, `docs:`) so reviewers can filter by type; keep subject lines under 72 characters and add body context when frontend and PocketBase changes ship together. Group related changes into cohesive commits and avoid mixing formatting-only updates with behaviour edits. Pull requests should outline the problem, the solution, manual verification steps, and link the relevant ticket; attach screenshots or recordings for UI shifts. Flag migrations and schema changes in the PR description and tag backend reviewers.

## Security & Configuration Tips
Store secrets in `.env.local` and load them via `dotenv`; never commit generated `.env` files. PocketBase defaults to `http://localhost:8090`—update `NEXT_PUBLIC_POCKETBASE_URL` if tunneling or exposing via Tailscale. Rotate the PocketBase admin credentials and configure SMTP before enabling outbound email. For deployment, follow `DEPLOYMENT.md` and run `security-setup.sh` to apply hardening defaults.

# Backend / Supabase

This folder contains SQL to create the database schema and RLS policies for the RutgersToGo hackathon.

Files (paste/run in Supabase SQL Editor)
- `backend/schema.sql` — table definitions: `profiles`, `menu_items`, `orders`.
- `backend/rls.sql` — row-level security policies.
- `backend/seed.sql` — optional sample data (menu_items) to help development.

How to apply (recommended order)
1. Open your Supabase project.
2. In the left menu, open "SQL" -> "SQL Editor".
3. Open `backend/schema.sql`, copy the SQL, paste it into the SQL Editor, and run it.
4. Open `backend/rls.sql`, copy the SQL, paste it into the SQL Editor, and run it.
5. (Optional) Open `backend/seed.sql`, copy the SQL, paste it into the SQL Editor, and run it to add sample `menu_items`.

Secrets and scraper
- The scraper and any server-side upserts MUST use the Supabase Service Role key (it bypasses RLS). The GitHub Actions workflow expects the following repository secrets to be set:
	- `SUPABASE_URL` (e.g. https://xyz.supabase.co)
	- `SUPABASE_SERVICE_ROLE_KEY`

How the team should use this
- Backend Lead: paste `backend/schema.sql` and `backend/rls.sql` in the SQL Editor to create schema and policies.
- Scraper Lead: add the two required GitHub secrets above, then run the scraper workflow (or run the scraper locally with the service role key) to populate `menu_items`.
- iOS team: after `seed.sql` is applied you can build the app against the real schema and sample rows.

Notes
- `menu_items` is intentionally public read-only. Clients can SELECT rows; only server/service_role may INSERT/UPDATE/DELETE.
- `profiles` and `orders` are user-scoped and use RLS so authenticated users can read/write their own rows only.


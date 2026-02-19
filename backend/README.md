# Backend / Supabase

This folder contains SQL to create the database schema and RLS policies for the RutgersToGo hackathon.

Files
- `schema.sql` — table definitions: `profiles`, `menu_items`, `orders`.
- `rls.sql` — row-level security policies. Important notes below.

How to apply
1. Open your Supabase project.
2. In the left menu, open "SQL" -> "SQL Editor".
3. Copy and paste the contents of `schema.sql` and run it.
4. Then copy and paste `rls.sql` and run it.

Notes
- `menu_items` is intentionally public read-only. The RLS policy grants SELECT to everyone so clients can fetch menus without requiring auth. Insert/update/delete to `menu_items` should be done server-side using the Supabase Service Role key (scraper / admin).
- The scraper should use the Supabase Service Role key (kept in GitHub Secrets or server env) to upsert `menu_items` because the service role bypasses RLS and is required for writes.
- `profiles` and `orders` are user-scoped and use RLS so authenticated users can read/write their own rows only.

If you need to adjust permissions during development, you can temporarily disable RLS on a table, but remember to re-enable before production.

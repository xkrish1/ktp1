-- Sample seed data for menu_items (safe to paste into Supabase SQL Editor)
-- NOTE: This inserts a few example menu items; adjust dates/fields as needed.

insert into public.menu_items (hall, date, meal, station, name, ingredients, source_url, source_key)
values
  ('Atrium', current_date, 'Lunch', 'Grill', 'Cheesy Burger', 'Beef patty, cheese (milk), bun (wheat), mayo', 'https://example.com/source/1', 'example-1'),
  ('Atrium', current_date, 'Breakfast', 'Station A', 'Oatmeal', 'Oats, water, milk (milk)', 'https://example.com/source/2', 'example-2'),
  ('Busch', current_date, 'Dinner', 'Station B', 'Shrimp Pasta', 'Pasta (wheat), shrimp (shellfish), cream (milk)', 'https://example.com/source/3', 'example-3');

-- You can add more rows or adapt this to realistic sample data.

#!/usr/bin/env python3
"""Scraper for FoodPro/menus.
Writes/upserts menu_items into Supabase via REST using service role key.
"""
import os
import time
import uuid
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

SUPABASE_URL = os.environ.get('SUPABASE_URL')
SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SERVICE_KEY:
    raise SystemExit("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")

HEADERS = {
    'apikey': SERVICE_KEY,
    'Authorization': f'Bearer {SERVICE_KEY}',
    'Content-Type': 'application/json'
}

HALLS = [('Atrium','13'), ('Busch','04')]
MEALS = ['Breakfast','Lunch','Dinner']

def upsert_menu_item(row):
    url = f"{SUPABASE_URL}/rest/v1/menu_items"
    # Use merge on conflict via Prefer header
    headers = dict(HEADERS)
    headers['Prefer'] = 'resolution=merge-duplicates'
    r = requests.post(url, json=[row], headers=headers)
    r.raise_for_status()
    return r.json()

def fetch_label(url):
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, 'html.parser')
        # Best-effort: find ingredients block
        text = soup.get_text(separator='\n')
        return text.strip()
    except Exception:
        return None

def scrape():
    inserted = 0
    updated = 0
    for hall_name, hall_code in HALLS:
        for meal in MEALS:
            # For each of today and tomorrow
            for d in range(0,2):
                from datetime import date, timedelta
                dt = (date.today() + timedelta(days=d)).isoformat()

                # TODO: Implement real scraping logic here for the university pickmenu / FoodPro pages.
                # This script previously inserted placeholder items for demo; that behavior has been removed
                # so the Scraper Lead can implement real parsing without accidental sample data being pushed.

                # Hint / recommended approach for Scraper Lead:
                # 1) Determine the real pickmenu URL pattern for each hall/meal/date.
                # 2) Fetch the pickmenu page and parse menu item blocks with BeautifulSoup.
                # 3) For each menu item, attempt to find a label/nutrition link and fetch it to extract ingredients.
                # 4) Build a row dict matching the `menu_items` schema and call upsert_menu_item(row).
                # 5) Rate-limit requests and handle missing data gracefully.

                # Example row structure (for when parsing is implemented):
                # row = {
                #   'hall': hall_name,
                #   'meal': meal,
                #   'date': dt,
                #   'station': station_name,
                #   'name': item_name,
                #   'ingredients': ingredients_text,
                #   'source_url': page_url,
                #   'source_key': stable_key
                # }

                # For now, only log what's expected.
                print(f"[INFO] TODO: scrape hall={hall_name} meal={meal} date={dt} — implement parsing and call upsert_menu_item(row)")
    print(f"Inserted/updated: {inserted}")

if __name__ == '__main__':
    scrape()

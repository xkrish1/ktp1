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
            # For demo, pretend there's a pickmenu URL pattern
            for d in range(0,2):
                # date as ISO
                from datetime import date, timedelta
                dt = (date.today() + timedelta(days=d)).isoformat()
                # Stub: pretend we fetch items from a source page
                # In real implementation, fetch the pickmenu page and parse items
                source_url = f"https://example.com/menus/{hall_code}/{meal}/{dt}"
                # For demonstration generate a couple of fake items
                items = [
                    { 'name': f"Sample {meal} Item A", 'station': 'Station A', 'ingredients_url': urljoin(source_url, '/label/a') },
                    { 'name': f"Sample {meal} Item B", 'station': 'Station B', 'ingredients_url': urljoin(source_url, '/label/b') }
                ]
                for it in items:
                    ingredients = fetch_label(it.get('ingredients_url'))
                    row = {
                        'hall': hall_name,
                        'meal': meal,
                        'date': dt,
                        'station': it.get('station'),
                        'name': it.get('name'),
                        'ingredients': ingredients,
                        'source_url': source_url,
                        'source_key': str(uuid.uuid5(uuid.NAMESPACE_URL, it.get('ingredients_url') or it.get('name')))
                    }
                    upsert_menu_item(row)
                    inserted += 1
                    time.sleep(0.5)
    print(f"Inserted/updated: {inserted}")

if __name__ == '__main__':
    scrape()

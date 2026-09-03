from __future__ import annotations

import html
import json
import re
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path

OUT = Path('reports/newswire-latest.json')
UA = 'Kevin-HQ-Newswire/1.0 (+https://github.com/hessmodee/KEVIN-WORK)'
PRESTON_LAT = 42.0963
PRESTON_LON = -111.8766


def fetch_bytes(url: str, timeout: int = 20) -> bytes:
    req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept': '*/*'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def clean_text(value: str | None) -> str:
    s = html.unescape(value or '')
    s = re.sub(r'<[^>]+>', ' ', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def strip_duplicate_source(title: str, source: str) -> tuple[str, str]:
    """Keep the publisher exactly once.

    Google News can provide a real <source> element while also leaving the same
    publisher appended to the title. Normalize that here so every consumer gets
    clean data instead of relying on display-layer workarounds.
    """
    title = clean_text(title)
    source = clean_text(source)
    if source:
        low_title = title.lower()
        low_source = source.lower()
        for sep in (' - ', ' — ', ' | ', ' · '):
            suffix = (sep + low_source)
            if low_title.endswith(suffix):
                title = title[:len(title) - len(sep + source)].strip()
                break
        return title, source

    if ' - ' in title:
        candidate_title, candidate_source = title.rsplit(' - ', 1)
        if len(candidate_source) <= 80:
            return candidate_title.strip(), candidate_source.strip()
    return title, source


def rss(url: str, category: str, limit: int) -> list[dict]:
    root = ET.fromstring(fetch_bytes(url))
    rows = []
    for item in root.findall('.//item'):
        title = clean_text(item.findtext('title'))
        link = clean_text(item.findtext('link'))
        pub = clean_text(item.findtext('pubDate'))
        source = clean_text(item.findtext('source'))
        title, source = strip_duplicate_source(title, source)
        if not title:
            continue
        published_at = ''
        if pub:
            try:
                published_at = parsedate_to_datetime(pub).astimezone(timezone.utc).isoformat()
            except Exception:
                published_at = pub
        rows.append({
            'category': category,
            'title': title,
            'source': source or 'News',
            'url': link,
            'published_at': published_at,
        })
        if len(rows) >= limit:
            break
    return rows


WEATHER_CODES = {
    0: 'Clear', 1: 'Mostly clear', 2: 'Partly cloudy', 3: 'Overcast',
    45: 'Fog', 48: 'Rime fog', 51: 'Light drizzle', 53: 'Drizzle', 55: 'Heavy drizzle',
    56: 'Freezing drizzle', 57: 'Heavy freezing drizzle', 61: 'Light rain', 63: 'Rain', 65: 'Heavy rain',
    66: 'Freezing rain', 67: 'Heavy freezing rain', 71: 'Light snow', 73: 'Snow', 75: 'Heavy snow',
    77: 'Snow grains', 80: 'Light showers', 81: 'Showers', 82: 'Heavy showers',
    85: 'Snow showers', 86: 'Heavy snow showers', 95: 'Thunderstorms',
    96: 'Thunderstorms with hail', 99: 'Severe thunderstorms with hail',
}


def weather() -> dict:
    params = urllib.parse.urlencode({
        'latitude': PRESTON_LAT,
        'longitude': PRESTON_LON,
        'current': 'temperature_2m,apparent_temperature,weather_code,wind_speed_10m',
        'temperature_unit': 'fahrenheit',
        'wind_speed_unit': 'mph',
        'timezone': 'America/Boise',
        'forecast_days': 1,
    })
    data = json.loads(fetch_bytes('https://api.open-meteo.com/v1/forecast?' + params).decode('utf-8'))
    cur = data.get('current') or {}
    code = int(cur.get('weather_code', -1)) if cur.get('weather_code') is not None else -1
    temp = cur.get('temperature_2m')
    feels = cur.get('apparent_temperature')
    wind = cur.get('wind_speed_10m')
    parts = ['Preston']
    if temp is not None:
        parts.append(f'{round(float(temp))}°F')
    parts.append(WEATHER_CODES.get(code, 'Current conditions'))
    if feels is not None:
        parts.append(f'feels {round(float(feels))}°F')
    if wind is not None:
        parts.append(f'wind {round(float(wind))} mph')
    return {
        'summary': ' | '.join(parts),
        'source': 'Open-Meteo',
        'observed_at': cur.get('time') or '',
    }


def google_news_search(query: str) -> str:
    return 'https://news.google.com/rss/search?' + urllib.parse.urlencode({
        'q': query,
        'hl': 'en-US',
        'gl': 'US',
        'ceid': 'US:en',
    })


def append_unique(headlines: list[dict], seen: set[str], rows: list[dict]) -> None:
    for item in rows:
        key = re.sub(r'\W+', '', item['title'].lower())[:180]
        if not key or key in seen:
            continue
        seen.add(key)
        headlines.append(item)


def main() -> None:
    generated = datetime.now(timezone.utc).isoformat()
    errors: list[str] = []
    wx = {}
    try:
        wx = weather()
    except Exception as exc:
        errors.append('weather: ' + str(exc)[:180])

    local_terms = '("Preston Idaho" OR "Franklin County Idaho" OR "Cache Valley" OR "Logan Utah")'
    feeds = [
        ('local', google_news_search(local_terms + ' when:2d'), 4),
        ('national', 'https://news.google.com/rss/headlines/section/topic/NATION?hl=en-US&gl=US&ceid=US:en', 4),
        ('world', 'https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-US&gl=US&ceid=US:en', 4),
        ('top', 'https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en', 4),
    ]
    headlines: list[dict] = []
    seen: set[str] = set()
    for category, url, limit in feeds:
        try:
            append_unique(headlines, seen, rss(url, category, limit))
        except Exception as exc:
            errors.append(f'{category}: {str(exc)[:180]}')

    # Local news can legitimately be quiet for a 48-hour window. HQ still
    # requires a local lane, so widen only that lane to one week before failing
    # the publication contract. This preserves local relevance rather than
    # weakening validation or relabeling unrelated national stories as local.
    if not any(item.get('category') == 'local' for item in headlines):
        try:
            append_unique(
                headlines,
                seen,
                rss(google_news_search(local_terms + ' when:7d'), 'local', 4),
            )
        except Exception as exc:
            errors.append('local_fallback: ' + str(exc)[:180])

    payload = {
        'schema': 1,
        'kind': 'kevin-hq-public-newswire',
        'generated_at': generated,
        'location_label': 'Preston / Cache Valley',
        'weather': wx,
        'headlines': headlines[:16],
        'errors': errors,
        'safe_for_public_repo': True,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"NEWSWIRE_OK weather={bool(wx)} headlines={len(payload['headlines'])} errors={len(errors)}")


if __name__ == '__main__':
    main()

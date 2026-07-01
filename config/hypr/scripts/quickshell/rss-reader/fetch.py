#!/usr/bin/env python3
import os
import json
import subprocess
import xml.etree.ElementTree as ET
from html import unescape
import re
import time

CACHE_DIR = os.path.expanduser('~/.cache/quickshell/rss-reader')
FEEDS_FILE = os.path.expanduser('~/.config/hypr/scripts/quickshell/rss-reader/feeds.txt')
os.makedirs(CACHE_DIR, exist_ok=True)

def clean_html(text):
    text = re.sub(r'<[^>]+>', '', text)
    text = unescape(text)
    return text.strip()

def parse_date(date_str):
    if not date_str:
        return 0
    try:
        from email.utils import parsedate_to_datetime
        dt = parsedate_to_datetime(date_str)
        return int(dt.timestamp())
    except:
        pass
    try:
        import dateutil.parser
        dt = dateutil.parser.parse(date_str)
        return int(dt.timestamp())
    except:
        pass
    return int(time.time())

def fetch_feed(url):
    try:
        result = subprocess.run(
            ['curl', '-s', '--max-time', '10', '-L', url],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            return []
        return parse_feed_xml(result.stdout, url)
    except:
        return []

def parse_feed_xml(xml_data, feed_url):
    entries = []
    try:
        root = ET.fromstring(xml_data)
    except ET.ParseError:
        return entries

    ns = {}
    for m in re.finditer(r'xmlns:?(\w*)=["\']([^"\']+)["\']', xml_data[:2000]):
        prefix, uri = m.groups()
        if prefix:
            ns[prefix] = uri

    # RSS 2.0
    channel = root.find('channel')
    feed_title = ''
    if channel is not None:
        ft = channel.find('title')
        if ft is not None:
            feed_title = ft.text or ''
        for item in channel.findall('item'):
            title = ''
            link = ''
            desc = ''
            pub_date = ''
            for child in item:
                tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                if tag == 'title' and not title:
                    title = child.text or ''
                elif tag == 'link' and not link:
                    link = child.text or ''
                elif tag == 'description' and not desc:
                    desc = clean_html(child.text or '')
                elif tag == 'pubDate' and not pub_date:
                    pub_date = child.text or ''
            if title:
                entries.append({
                    'feed': feed_title or feed_url,
                    'title': title, 'link': link,
                    'desc': desc[:200],
                    'time': parse_date(pub_date),
                })

    # Atom
    if not entries:
        ft = root.find('title')
        if ft is not None:
            feed_title = ft.text or ''
        for entry in root.findall('entry'):
            title = ''
            link = ''
            desc = ''
            updated = ''
            for child in entry:
                tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                if tag == 'title' and not title:
                    title = child.text or ''
                elif tag == 'link' and not link:
                    link = child.attrib.get('href', '')
                elif tag == 'summary' and not desc:
                    desc = clean_html(child.text or '')
                elif tag == 'content' and not desc:
                    desc = clean_html(child.text or '')
                elif tag == 'updated' and not updated:
                    updated = child.text or ''
            if title:
                entries.append({
                    'feed': feed_title or feed_url,
                    'title': title, 'link': link,
                    'desc': desc[:200],
                    'time': parse_date(updated),
                })

    entries.sort(key=lambda x: -x['time'])
    return entries[:15]

def main():
    if not os.path.exists(FEEDS_FILE):
        with open(FEEDS_FILE, 'w') as f:
            f.write('# One RSS/Atom feed URL per line\n')
            f.write('# Example:\n')
            f.write('https://news.ycombinator.com/rss\n')
            f.write('https://lobste.rs/rss\n')

    feeds = []
    with open(FEEDS_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                feeds.append(line)

    all_entries = []
    for url in feeds:
        all_entries.extend(fetch_feed(url))
        time.sleep(0.3)

    all_entries.sort(key=lambda x: -x['time'])
    print(json.dumps(all_entries[:50]))

if __name__ == '__main__':
    main()

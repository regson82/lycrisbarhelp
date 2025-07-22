#!/usr/bin/env python3
# get_lyrics.py
# This script scrapes Genius.com for song lyrics.

import sys
import requests
from bs4 import BeautifulSoup
import urllib.parse

def create_search_url(query):
    base_url = "https://genius.com/search"
    encoded_query = urllib.parse.quote(query)
    return f"{base_url}?q={encoded_query}"

def find_first_song_url(html):
    soup = BeautifulSoup(html, 'html.parser')
    # Find all potential links in the search results
    links = soup.select("a[class^='CardSongdesktop__Link']")
    if links:
        return links[0]['href']
    return None

def parse_lyrics(html):
    soup = BeautifulSoup(html, 'html.parser')
    # Use a more specific selector to find all lyric containers
    lyrics_containers = soup.select("div[data-lyrics-container='true']")
    
    if not lyrics_containers:
        return None
    
    all_lyrics = []
    for container in lyrics_containers:
        # Replace <br> tags with newlines
        for br in container.find_all('br'):
            br.replace_with('\n')
        all_lyrics.append(container.get_text())

    lyrics_text = "\n".join(all_lyrics)
    
    # Clean up the text
    lines = lyrics_text.split('\n')
    cleaned_lines = []
    for line in lines:
        stripped_line = line.strip()
        # Remove section headers like [Intro], [Verse], etc.
        if stripped_line.startswith('[') and stripped_line.endswith(']'):
            continue
        # Remove the junk "Contributors" and other metadata lines
        if "ContributorsTranslations" in stripped_line or "Lyrics" in stripped_line and len(stripped_line) < 30:
            continue
        if stripped_line: # Avoid adding empty lines
            cleaned_lines.append(stripped_line)
        
    return "\n".join(cleaned_lines).strip()

def main():
    if len(sys.argv) < 2:
        return

    query = " ".join(sys.argv[1:])
    
    try:
        search_url = create_search_url(query)
        # Add headers to mimic a real browser
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'}
        search_response = requests.get(search_url, headers=headers, timeout=5)
        search_response.raise_for_status()

        song_url = find_first_song_url(search_response.text)
        if not song_url:
            return

        song_response = requests.get(song_url, headers=headers, timeout=5)
        song_response.raise_for_status()

        lyrics = parse_lyrics(song_response.text)
        if lyrics:
            print(lyrics)

    except requests.exceptions.RequestException as e:
        print(f"Error: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()

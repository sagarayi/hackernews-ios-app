# Hacker News iOS

A native iOS client for [Hacker News](https://news.ycombinator.com), styled after the website — orange chrome, beige surfaces, and the classic rank/title/meta rows.

## Tabs

Mirrors the site navigation: **New · Past · Comments · Ask · Show · Jobs**. Story order is scraped from the site's own pages, so rows match news.ycombinator.com exactly; item details come from the Firebase API. (Submit is omitted — posting requires a logged-in account.)

## Features

- Ranked story lists with infinite scroll, pull-to-refresh, and skeleton loading
- Comments tab with parent-story context; tap any row to open the thread
- In-app reader with article/comments toggle, share, and open-in-Safari
- Full-screen and inline error states with retry, API backoff on rate limits
- Dynamic Type and Reduce Motion support, pinned to the site's light style

## Requirements

- Xcode 16+, iOS 18.5+
- No dependencies — UIKit, WebKit, and Foundation only

## Run

Open `HackerNews/HackerNews.xcodeproj`, pick an iPhone simulator, and hit Run.

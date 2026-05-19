# Flamecomics Manga Scraper API

Flamecomics API is a small Ruby/Roda scraper API for FlameComics series, chapters, home-page sections, and reader images.

The default local port is `9292`.

## Installation

```bash
git clone https://github.com/vmxt/flamecomics-api.git
cd flamecomics-api
bundle install
```

## Development

Run the server:

```bash
bundle exec puma config.ru
```

If port `9292` is already in use:

```bash
bundle exec puma config.ru -p 9293
```

Run tests and lint:

```bash
bundle exec rspec
bundle exec rubocop
```

## Features

- Scrapes FlameComics home, browse, series, and reader pages.
- Reads latest update dates from embedded Next.js `__NEXT_DATA__`.
- Adds short TTL response caching for expensive scraper endpoints.
- Sends `Cache-Control` headers on cached responses.
- Provides scraper and cache health endpoints.
- Applies simple per-IP rate limiting.
- Uses explicit outbound request timeouts with one retry.
- Uses structured errors: `{ "error": "...", "code": "...", "source": "..." }`.
- Supports versioned `/v1` aliases.
- Exposes a static OpenAPI document at `/openapi.json`.

## Versioning

Current endpoints are available at both the root path and `/v1`.

Examples:

```http
GET /home
GET /v1/home
GET /series/:id
GET /v1/series/:id
```

## Caching

These endpoints are cached in memory for `180` seconds:

- `GET /home`
- `GET /browse`
- `GET /series/:id`

Cached responses include:

```http
Cache-Control: public, max-age=180
```

Inspect cache state:

```http
GET /health/cache
```

Example:

```json
{
  "cache": {
    "count": 1,
    "default_ttl_seconds": 180,
    "keys": [
      {
        "key": "home",
        "expires_in_seconds": 151
      }
    ]
  },
  "checked_at": "2026-05-19T00:00:00Z"
}
```

## Rate Limiting

The API allows `120` requests per IP per `60` seconds.

Responses include:

```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 119
X-RateLimit-Reset: 1779160000
```

When the limit is exceeded:

```json
{
  "error": "Rate limit exceeded",
  "code": "rate_limit_exceeded",
  "source": "rate_limiter"
}
```

## Endpoints

### `GET /`

Returns the API index, feature list, cache metadata, and endpoint list.

### `GET /openapi.json`

Returns the static OpenAPI 3.0 document.

### `GET /health/scrapers`

Checks FlameComics reachability and whether the embedded Next.js latest update data is available.

Example response:

```json
{
  "origin": "https://flamecomics.xyz/",
  "reachable": true,
  "status_code": 200,
  "next_data_present": true,
  "latest_entries_present": true,
  "latest_updates_count": 18,
  "latest_chapters_count": 54,
  "sample_release_date_present": true,
  "checked_at": "2026-05-19T00:00:00Z"
}
```

### `GET /health/cache`

Returns in-memory cache statistics.

### `GET /home`

Returns spotlight, popular, staff picks, latest updates, and novels.

Latest updates are returned as flat chapter update rows:

```json
{
  "id": "133",
  "title": "The Regressed Youngest Son of the Duke is an Assassin",
  "img_url": "https://cdn.flamecomics.xyz/uploads/images/series/133/thumbnail.png?1744391924",
  "language": "KR",
  "chapter_id": "6cfcfbd466cb823f",
  "chapter_title": "Chapter 127 - The Princess’ Tour (1)",
  "chapter_date": "3 hours ago"
}
```

### `GET /series/:id`

Returns details about a series and its chapters.

Chapter objects include normalized fields and legacy compatibility keys:

```json
{
  "chapter_id": "chapter-token",
  "chapter_number": "12",
  "chapter_title": "The Test Title",
  "chapter_label": "Chapter 12 - The Test Title",
  "chapter_date": "3 hours ago",
  "img_url": "https://example.com/chapter.jpg",
  "label": "Chapter 12 - The Test Title",
  "date": "3 hours ago"
}
```

### `GET /series/:id/:chapter_id`

Returns reader image URLs and navigation data for a chapter.

Parameters:

| Name | Required | Description |
| --- | --- | --- |
| `id` | Yes | Series id from `/home`, `/browse`, or `/series/:id`. |
| `chapter_id` | Yes | Chapter token/id from a series chapter list or latest update. |

Example:

```http
GET /series/133/6cfcfbd466cb823f
```

Response:

```json
{
  "series_id": "133",
  "chapter_id": "6cfcfbd466cb823f",
  "next_chapter_id": "next-chapter-token",
  "prev_chapter_id": "previous-chapter-token",
  "title": "Series Title - Chapter 127",
  "count": 12,
  "img_srcs": [
    "https://cdn.flamecomics.xyz/uploads/images/chapters/page-1.webp",
    "https://cdn.flamecomics.xyz/uploads/images/chapters/page-2.webp"
  ]
}
```

Notes:

- `next_chapter_id` and `prev_chapter_id` may be `null` at the newest or oldest chapter.
- `count` is the number of image URLs returned in `img_srcs`.
- Watermark/commission images are filtered out when detected.

### `GET /browse`

Returns a list of series using FlameComics browse query parameters.

Example:

```http
GET /browse
GET /browse?page=2
GET /browse?status=Ongoing&type=Manhwa
```

Response:

```json
{
  "count": 1,
  "comics": [
    {
      "id": "133",
      "title": "The Regressed Youngest Son of the Duke is an Assassin",
      "img_url": "https://cdn.flamecomics.xyz/uploads/images/series/133/thumbnail.png",
      "rating": 489,
      "status": "Ongoing",
      "genres": ["Action", "Adventure", "Fantasy"],
      "synopsis": "Series description text."
    }
  ]
}
```

Notes:

- Query parameters are passed through to FlameComics' browse page.
- `rating` defaults to `0` when a rating cannot be found.
- `synopsis` defaults to `"No Description"` when the card has no description.
- This endpoint is cached for `180` seconds and returns `Cache-Control`.

### `GET /search?title=<search_term>`

Searches browse results by title.

Parameters:

| Name | Required | Description |
| --- | --- | --- |
| `title` | Yes | Case-insensitive title text to search for. |

Example:

```http
GET /search?title=frozen
```

Response:

```json
{
  "count": 1,
  "results": [
    {
      "id": "153",
      "title": "Return of The Frozen Player",
      "img_url": "https://cdn.flamecomics.xyz/uploads/images/series/153/thumbnail.jpeg",
      "rating": 332,
      "status": "Ongoing",
      "genres": ["Action", "Adventure", "Fantasy"],
      "synopsis": "Series description text."
    }
  ]
}
```

Missing title response:

```json
{
  "error": "Missing title parameter",
  "code": "missing_title",
  "source": "search"
}
```

Notes:

- Search normalizes punctuation, symbols, whitespace, and case.
- Search currently uses browse results as its source.

### `GET /random`

Redirects to a random valid `/series/:id` route.

Example:

```http
GET /random
```

Success response:

```http
302 Found
Location: /series/133
```

Failure response:

```json
{
  "error": "No valid series found",
  "code": "random_series_not_found",
  "source": "random"
}
```

Notes:

- The endpoint samples series ids from the FlameComics browse page.
- Clients should follow the redirect to receive the series details response.

## Error Responses

Errors use a structured shape:

```json
{
  "error": "Missing title parameter",
  "code": "missing_title",
  "source": "search"
}
```

Common status codes:

- `200 OK` - Successful JSON response.
- `302 Found` - Random series redirect.
- `404 Not Found` - Invalid route.
- `429 Too Many Requests` - Rate limit exceeded.
- `500 Internal Server Error` - Unexpected server error.

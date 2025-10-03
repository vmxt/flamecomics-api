# Flamecomics Manga Scraper API Documentation

## Introduction

Welcome to the Flamecomics manga scraper API. This API allows you to retrieve information about manga series, chapters, and images from the website.

The base URL for this API is `http://localhost:4567`.

## Installation

1. First clone this repository

```
git clone https://github.com/vmxt/flamecomics-api.git
cd flamecomics-api
```

2. Install dependencies

```
bundle install
```

3. Run server

```
ruby app.rb
```

## Endpoints

### `/`

Returns a JSON object containing a welcome message, API status, GitHub repository link, and creation date.

#### Request

```http
GET /
```

#### Response

```json
{
  "message": "Flamecomics Manga scraper",
  "apiStatus": true,
  "serverStatus": "ONLINE"
}
```

### `/home`

Returns JSON data with spotlight, popular, and latest updates manga series.

#### Request 

```
GET /home
```

#### Response

```json
{
  "spotlight": [
    {
      "title": "string",
      "id": "string",
      "img": "string",
      "genre": ["string", "..."]
    },
    ...
  ],
  "popular": [
    {
      "title": "string",
      "id": "string",
      "img": "string",
      "status": "string",
      "likes": number
    },
    ...
  ],
  "latest_updates": [
    {
      "title": "string",
      "img": "string",
      "status": "string",
      "id": "string",
      "chapter": [
        {
          "title": "string",
          "id": "string",
          "date": "string"
        },
        ...
      ]
    },
    ...
  ]
}
```

### `/series/:id`

Returns details about a specific manga series by its ID.

#### Request

```http
GET /series/:id
```

#### Parameters

| Parameter | Required | Description                                                                                         |
| --------- | -------- | --------------------------------------------------------------------------------------------------- |
| id        | Yes      | The ID of the manga series                                                                          |


#### Response

```json
{
  "title": "string",
  "alternativeTitles": "string",
  "posterSrc": "string",
  "genres": ["string", "..."],
  "type": "string",
  "status": "string",
  "author": "string",
  "artist": "string",
  "serialization": "string",
  "releaseYear": "string",
  "language": "string",
  "officialUrl": "string",
  "synopsis": "string",
  "chaptersCount": number,
  "chapters": [
    {
      "id": "string",
      "img": "string",
      "label": "string",
      "date": "string"
    },
    ...
  ]
}
```

### `/series/:series_id/:chapter_id`

Returns image URLs and information for a specific manga chapter.

#### Request

```http
GET /series/:series_id/:chapter_id
```

#### Parameters

| Parameter  | Required | Description                                        |
| ---------  | -------- | -------------------------------------------------- |
| series_id  | Yes      | The ID of the manga series                         |
| chapter_id | Yes      | The ID of the manga series                         |

#### Response

```json
{
  "seriesId": "string",
  "id": "string",
  "title": "string",
  "count": number,
  "imgSrcs": ["string", "..."]
}
```

### `/browse`

Returns a list of manga series filtered by query parameters.

#### Request

```http
GET /browse
```

#### Response

```json
{
  "currentPage": number,
  "count": number,
  "comics": [
    {
      "id": "string",
      "title": "string",
      "series_url": "string",
      "thumbnail": "string",
      "rating": number|null,
      "status": "string",
      "genres": ["string", "..."],
      "description": "string"
    },
    ...
  ]
}
```

## Error Responses

The API may return error responses with the following structure:

```json
{
  "error": "Error message"
}
```

The `error` field contains the error message. The HTTP status code of the response will indicate the type of error.

The API may return the following status codes:

- `400 Bad Request` - Invalid or missing parameters
- `404 Not Found` - Invalid endpoint or resource not found
- `500 Internal Server Error` - Server error or unexpected exception occurred.

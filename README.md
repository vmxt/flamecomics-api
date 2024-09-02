# Flamecomics Manga Scraper API Documentation

## Introduction

Welcome to the Flamecomics manga scraper API. This API allows you to retrieve information about manga series, chapters, and images from the website.

The base URL for this API is `http://localhost:8000`.

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
      "message": string,
      "apiStatus": boolean,
      "serverStatus": string
}
```

### `/home`

Returns a JSON array of objects containing information about `Popular` and etc.

#### Request 

```
GET /home
```

#### Response

```json
{
  "spotlight": [
    {
      "title": string,
      "id": string,
      "img": string,
      "genre": []
    },
    {...}
  ],
  "trending": [
    {
      "title": string,
      "list": [
        {
          "title": string,
          "id": string,
          "rating": number,
          "image": string,
          "status": string
        },
      ]
    },
    {...}
    {
      "title": string,
      "list": [
        {
          "title": string,
          "id": string,
          "rating": null,
          "image": string,
          "status": null
        },
      ]
    },
    {...}
  ],
  "latest_updates": [
    {
      "title": string,
      "img": string,
      "rating": number,
      "status": string,
      "id": string,
      "chapter": [
        {
          "title": string,
          "id": string,
          "date": string
        },
        {...}
      ]
    },
    {...}
  ]
}
```

### `/search/<search parameter>?page=1`

Returns a JSON array of objects containing result about searched items.

#### Request

```
GET /search/<searchParam>?page=<pageNumber>
```

#### Parameter

| Parameter | Required | Description                                                                                         |
| --------- | -------- | --------------------------------------------------------------------------------------------------- |
| searchParam    | Yes       | Search Paramter )    |
| pageNumber    | No       | Defaults to 1 )    |


### `/series`

Returns a JSON object containing information about manga series from the Flamecomics website.

#### Request

```http
GET /series?page=<pageNumber>&type=<type>&status=<status>
```

#### Parameters

| Parameter | Required | Description                                                                                         |
| --------- | -------- | --------------------------------------------------------------------------------------------------- |
| page      | Yes      | The page number of the series list to retrieve                                                      |
| type      | No       | The type of manga series to retrieve (e.g. `Manhwa`, `Manga`, `Manhua`, or leave empty for default) |
| status    | No       | The status of manga series to retrieve (e.g. `Ongoing`, `Completed`, or leave empty for default)    |

#### Response

```json
{
  "currentPage": string,
  "nextPage": string,
  "type": string,
  "status": string,
  "count": number.length,
  "comics": string
}
```

### `/details/:id`

Returns a JSON object containing details about a specific manga series.

#### Request

```http
GET /details/:id
```

#### Parameters

| Parameter | Required | Description                                        |
| --------- | -------- | -------------------------------------------------- |
| id        | Yes      | The ID of the manga series to retrieve details for |

#### Response

```json
{
  "title": string,
  "alternativeTitles": string,
  "posterSrc": string,
  "genres": string,
  "type": string,
  "status": string,
  "author": string,
  "artist": string,
  "serialization": string,
  "score": number,
  "synopsis": string,
  "chaptersCount": number.length,
  "chapters": number
}
```

### `/read/:id`

Returns a JSON object containing the image URLs for a specific manga chapter.

#### Request

```http
GET /read/:id
```

#### Parameters

| Parameter | Required | Description                                        |
| --------- | -------- | -------------------------------------------------- |
| id        | Yes      | The ID of the manga chapter to retrieve images for |

#### Response

```json
{
  "id": string,
  "title": string,
  "count": string.length,
  "imgSrcs": string
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

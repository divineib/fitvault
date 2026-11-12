# spike: usda fooddata central api

what: a time-boxed look at the usda fooddata central api, to check the 5-point estimate for us05 (food search) before building it.
when: november 12, 2026 (sprint 1 spike, no points, 2 days max; this took well under a day).
how: called the api with curl using the public `DEMO_KEY`. no real api key was used or saved anywhere.
result: **the estimate stays at 5 points.** the api works and is fast enough, but serving sizes and nutrient ids differ by food type, which is where most of the work is.

---

## the call

```
GET https://api.nal.usda.gov/fdc/v1/foods/search?query=chicken%20breast&pageSize=10&api_key=DEMO_KEY
```

| request | http | time | size |
|---|---|---|---|
| search, default page size (50 results) | 200 | 1.19 s | 990 kb |
| search, `pageSize=10` | 200 | 0.72 s | 72 kb |
| search, `pageSize=10`, only foundation and sr legacy | 200 | 2.20 s | 314 kb |
| details for one food (`/food/171515`) | 200 | 0.84 s | 39 kb |
| details, `format=abridged` | 200 | 0.66 s | 15 kb |
| search with an invalid api key | 403 | | json error |
| search with a badly formatted `dataType` value | 400 | 0.39 s | html error page |

"chicken breast" matched 21,658 foods.

takeaways:
- always send `pageSize` (10 to 25). the default 50 results is almost 1 mb, too much for a phone on a slow connection.
- foundation and sr legacy foods are heavy (about 100 nutrients each), so they make responses bigger and slower.
- the 3-second goal in us05 looks reachable with a small page size on a normal connection.

---

## json shape (trimmed)

```
{
  "totalHits": 21658,
  "currentPage": 1,
  "totalPages": 2166,
  "foods": [
    {
      "fdcId": 2187885,
      "description": "CHICKEN BREAST",
      "dataType": "Branded",
      "brandOwner": "Giant Eagle, Inc.",
      "servingSize": 284.0,
      "servingSizeUnit": "g",
      "householdServingFullText": "1 CHICKEN BREAST",
      "foodMeasures": [],
      "foodNutrients": [
        { "nutrientId": 1008, "nutrientNumber": "208", "nutrientName": "Energy",  "unitName": "KCAL", "value": 165 },
        { "nutrientId": 1003, "nutrientNumber": "203", "nutrientName": "Protein", "unitName": "G",    "value": 20.4 },
        { "nutrientId": 1004, "nutrientNumber": "204", "nutrientName": "Total lipid (fat)", "unitName": "G", "value": 8.1 },
        { "nutrientId": 1005, "nutrientNumber": "205", "nutrientName": "Carbohydrate, by difference", "unitName": "G", "value": 1.06 }
      ]
    }
  ]
}
```

---

## where calories and protein are

all nutrient values in search results are **per 100 grams**, for every food type.

| nutrient | id to look for | notes |
|---|---|---|
| protein | `nutrientId` 1003 (number "203") | present in every food type checked |
| calories | `nutrientId` 1008 (number "208"), unit `KCAL` | branded, survey (fndds), and sr legacy foods have this |
| calories (fallback) | `nutrientId` 2047 "Energy (Atwater General Factors)", or 2048 (specific factors) | **foundation foods had no 1008 at all**, only these |
| carbs, fat (optional in us04) | 1005 and 1004 | |

watch out: sr legacy also lists energy in kilojoules (`nutrientId` 1062, unit `kJ`), so the code must pick by id or unit, never just the name "Energy".

---

## how serving sizes work

this is the hardest part. each food type gives serving info differently:

| data type | serving info in search results | what to do |
|---|---|---|
| branded (store products) | `servingSize` + `servingSizeUnit` (for example 284 g) and `householdServingFullText` ("1 chicken breast") | per-serving value = per-100 g value × serving grams ÷ 100 |
| survey (fndds) | `foodMeasures` list, for example "1 oz, cooked" = 28.35 g, "1 medium slice" = 60 g | show the list and let the user pick |
| sr legacy | nothing in search results | call `/food/{fdcId}` (full format, not abridged) to get `foodPortions`, for example "3 oz" = 85 g |
| foundation | nothing in search results | same as sr legacy, or fall back to grams |

plan for us05: always offer "100 g" and "custom grams". add the food's own servings when they're available. this needs one extra call (the details endpoint) only when the user picks an sr legacy or foundation food.

---

## rate limits

- `DEMO_KEY` (what the spike used): the response headers said `x-ratelimit-limit: 10`, and `x-ratelimit-remaining` went down from 9 to 5 over the spike's calls. that's only enough for testing, not for real use.
- a free personal key from api.data.gov: the standard limit is 1,000 requests per hour. this wasn't tested because no real key was used.
- running out of requests should return http 429. the app should show "search is busy, try again soon" and keep manual entry available.

---

## errors the app has to handle

- **invalid key:** http 403 with a json body: `{"error": {"code": "API_KEY_INVALID", ...}}`.
- **bad request:** http 400 with an **html** page, not json. the code must check the status code before trying to decode json.
- **rate limit:** http 429 (expected, not triggered).
- **offline or timeout:** no response at all. use a short timeout (about 5 seconds) so the user isn't left waiting.

in every case, us05 says the app must show a message and still allow manual entry.

---

## privacy and the api key

- **only the search term leaves the phone.** the request holds the search words and the api key, nothing from the user's logs. (like any web request, the usda server can see the phone's ip address.)
- **keeping the key out of the public repo:** put it in `Config/secrets.xcconfig`, which `.gitignore` already blocks, and read it into the app through the build settings. commit a `secrets.example.xcconfig` with a placeholder so the project still builds for others.
- **honest limit:** a key shipped inside an app can be pulled out by someone who digs into the app file. for a free, rate-limited usda key that's acceptable for this project, but it's why the key should never be one with billing attached.

---

## estimate for us05

**confirmed: 5 points (no change).**

what makes it 5 and not 3:
- network code with a timeout, status-code checks, and json decoding
- picking the right nutrient ids, with the foundation-food fallback for calories
- serving sizes that differ by food type, plus a second call for some foods
- error and offline handling that always falls back to manual entry
- keeping the key out of the repo with a git-ignored config file
- a search screen with results and a serving picker
- unit tests using saved sample json, so tests don't call the real api

if it turns out bigger than expected in sprint 2, split it: first search and fill per 100 g or custom grams, then a later story for the food's own serving sizes.

# Prowlarr Indexer Templates

Place JSON templates here to auto-create indexers in Prowlarr during bootstrap.

How it works:
- Files are read by `bash scripts/bootstrap.sh` and POSTed to Prowlarr `/api/v1/indexer`.
- Templates are processed through `envsubst`, so you can use environment variables in JSON, like `${MY_TRACKER_API_KEY}`.

Example minimal Torznab template (`mytorznab.json`):
```json
{
  "name": "MyTorznab",
  "implementation": "Torznab",
  "configContract": "TorznabSettings",
  "protocol": "torrent",
  "fields": [
    { "name": "baseUrl", "value": "https://indexer.example.com" },
    { "name": "apiKey",  "value": "${MY_TORZNAB_API_KEY}" },
    { "name": "categories", "value": "5000,5030" }
  ],
  "enableRss": true,
  "enableSearch": true
}
```

Note:
- Each tracker has specific field names; check Prowlarr Swagger at `/swagger` or export an existing indexer from Prowlarr to learn the schema.
- Do not commit real secrets. Use placeholders and set them in `docker/.env` instead.


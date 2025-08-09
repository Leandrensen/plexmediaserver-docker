# Prowlarr Indexer Templates

Place JSON templates here to auto-create indexers in Prowlarr during bootstrap.

How it works:
- Files are read by `bash scripts/bootstrap.sh` and POSTed to Prowlarr `/api/v1/indexer`.
- Templates are processed through `envsubst`, so you can use environment variables in JSON, like `${MY_TRACKER_API_KEY}`.

Included templates:
- `1337x.json` (public; auto-linked to FlareSolverr by bootstrap and tagged `flaresolverr`)
- `bitsearch.json` (public)
- `eztv.json` (public; base URL set, TV category)
- `rutracker.json` (semi-private; uses `${RUTRACKER_USERNAME}`/`${RUTRACKER_PASSWORD}`)
- `torrentz2nz.json` (public)
- `example.json` (skeleton for Torznab)

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

---

## Español (Argentina)

Colocá acá plantillas JSON para crear indexadores en Prowlarr de forma automática durante el bootstrap.

Cómo funciona:
- `bash scripts/bootstrap.sh` lee los templates y los envía a `/api/v1/indexer` de Prowlarr.
- Los archivos pasan por `envsubst`, así que podés usar variables de entorno en el JSON, por ejemplo `${MI_TRACKER_API_KEY}`.

Plantillas incluidas:
- `1337x.json` (público; el bootstrap lo enlaza a FlareSolverr y aplica el tag `flaresolverr`).
- `bitsearch.json` (público).
- `eztv.json` (público; URL base seteada, categoría TV).
- `rutracker.json` (semi-privado; usa `${RUTRACKER_USERNAME}`/`${RUTRACKER_PASSWORD}`).
- `torrentz2nz.json` (público).
- `example.json` (esqueleto para Torznab).

Notas:
- Cada tracker tiene campos distintos; mirá `/swagger` en Prowlarr o exportá un indexador para ver el esquema exacto.
- No subas secretos reales. Usá placeholders y definilos en `docker/.env`.


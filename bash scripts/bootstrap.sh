#!/bin/sh
set -eu

info() { echo "[bootstrap] $*"; }

wait_http() {
  url="$1"; name="$2"; attempts="${3:-60}"
  i=0
  until curl -fsS "$url" >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge "$attempts" ]; then
      info "Timeout waiting for $name at $url"; return 1
    fi
    sleep 2
  done
}

# Wait for core services
wait_http "${PROWLARR_URL:-http://prowlarr:9696}" prowlarr || true
wait_http "${SONARR_URL:-http://sonarr:8989}" sonarr || true
wait_http "${RADARR_URL:-http://radarr:7878}" radarr || true
wait_http "${LIDARR_URL:-http://lidarr:8686}" lidarr || true
wait_http "${BAZARR_URL:-http://bazarr:6767}" bazarr || true

json() { jq -c .; }

# Helper to call APIs
apicall() {
  method="$1"; url="$2"; key="$3"; data="${4:-}"
  if [ -n "$data" ]; then
    curl -fsS -X "$method" "$url" -H "X-Api-Key: $key" -H 'Content-Type: application/json' -d "$data"
  else
    curl -fsS -X "$method" "$url" -H "X-Api-Key: $key"
  fi
}

if [ -n "${PROWLARR_API_KEY:-}" ]; then
  info "Configuring Prowlarr apps (Sonarr/Radarr/Lidarr)"
  # Add Sonarr app
  if [ -n "${SONARR_API_KEY:-}" ]; then
    apicall POST "$PROWLARR_URL/api/v1/applications" "$PROWLARR_API_KEY" "$(cat <<'JSON' | sed -e "s|__SONARR_URL__|${SONARR_URL}|g" -e "s|__SONARR_KEY__|${SONARR_API_KEY}|g" | json)
{ "name":"sonarr","implementation":"Sonarr","configContract":"SonarrSettings","syncLevel":"FullSync","fields":[{"name":"apiKey","value":"__SONARR_KEY__"},{"name":"baseUrl","value":"__SONARR_URL__"}]}
JSON
)"
  fi
  # Add Radarr app
  if [ -n "${RADARR_API_KEY:-}" ]; then
    apicall POST "$PROWLARR_URL/api/v1/applications" "$PROWLARR_API_KEY" "$(cat <<'JSON' | sed -e "s|__RADARR_URL__|${RADARR_URL}|g" -e "s|__RADARR_KEY__|${RADARR_API_KEY}|g" | json)
{ "name":"radarr","implementation":"Radarr","configContract":"RadarrSettings","syncLevel":"FullSync","fields":[{"name":"apiKey","value":"__RADARR_KEY__"},{"name":"baseUrl","value":"__RADARR_URL__"}]}
JSON
)"
  fi
  # Add Lidarr app
  if [ -n "${LIDARR_API_KEY:-}" ]; then
    apicall POST "$PROWLARR_URL/api/v1/applications" "$PROWLARR_API_KEY" "$(cat <<'JSON' | sed -e "s|__LIDARR_URL__|${LIDARR_URL}|g" -e "s|__LIDARR_KEY__|${LIDARR_API_KEY}|g" | json)
{ "name":"lidarr","implementation":"Lidarr","configContract":"LidarrSettings","syncLevel":"FullSync","fields":[{"name":"apiKey","value":"__LIDARR_KEY__"},{"name":"baseUrl","value":"__LIDARR_URL__"}]}
JSON
)"
  fi

  # Optionally set FlareSolverr URL (best-effort; may require settings endpoint)
  if [ -n "${FLARESOLVERR_URL:-}" ]; then
    info "Note: set FlareSolverr URL to $FLARESOLVERR_URL in Prowlarr UI if not applied automatically."
  fi

  # Seed Torznab/Newznab indexers from templates in /seed (optional)
  if [ -d /seed/indexers ]; then
    info "Seeding Prowlarr indexers from /seed/indexers"
    for tpl in /seed/indexers/*.json; do
      [ -f "$tpl" ] || continue
      # envsubst allows placeholder substitution like ${TRACKER_API_KEY}
      payload=$(envsubst < "$tpl")
      apicall POST "$PROWLARR_URL/api/v1/indexer" "$PROWLARR_API_KEY" "$payload" || true
    done
  fi

  # Seed indexer proxies (e.g., FlareSolverr) from /seed/proxies
  if [ -d /seed/proxies ]; then
    info "Seeding Prowlarr indexer proxies from /seed/proxies"
    for tpl in /seed/proxies/*.json; do
      [ -f "$tpl" ] || continue
      payload=$(envsubst < "$tpl")
      apicall POST "$PROWLARR_URL/api/v1/indexerproxy" "$PROWLARR_API_KEY" "$payload" || true
    done
  fi

  # If FlareSolverr proxy exists, attach it to 1337x indexers
  # Best-effort: schema may vary across versions
  proxy_id=""
  proxy_id=$(apicall GET "$PROWLARR_URL/api/v1/indexerproxy" "$PROWLARR_API_KEY" | jq -r '.[] | select(.name=="FlareSolverr") | .id' || true)
  if [ -n "$proxy_id" ]; then
    # Ensure a tag named "flaresolverr" exists and get its id
    tag_id=$(apicall GET "$PROWLARR_URL/api/v1/tag" "$PROWLARR_API_KEY" | jq -r '.[] | select(.label=="flaresolverr") | .id' || true)
    if [ -z "$tag_id" ] || [ "$tag_id" = "null" ]; then
      created=$(apicall POST "$PROWLARR_URL/api/v1/tag" "$PROWLARR_API_KEY" '{"label":"flaresolverr"}' || echo '')
      tag_id=$(echo "$created" | jq -r '.id' 2>/dev/null || echo '')
    fi
    info "Assigning FlareSolverr proxy (id=$proxy_id) to 1337x indexers"
    # list indexers and pick those named like 1337x
    idx_ids=$(apicall GET "$PROWLARR_URL/api/v1/indexer" "$PROWLARR_API_KEY" | jq -r '.[] | select((.name|ascii_downcase) | test("1337x")) | .id' || true)
    for id in $idx_ids; do
      # fetch existing config
      cfg=$(apicall GET "$PROWLARR_URL/api/v1/indexer/$id" "$PROWLARR_API_KEY" || true)
      [ -n "$cfg" ] || continue
      # set indexerProxyIds if the field is supported
      newcfg=$(echo "$cfg" | jq --argjson pid "$proxy_id" ' .indexerProxyIds = [$pid] ' || echo "")
      # also add the "flaresolverr" tag if we have a tag id
      if [ -n "$tag_id" ]; then
        newcfg=$(echo "$newcfg" | jq --argjson tid "$tag_id" ' .tags = ((.tags // []) + [tid]) | .tags |= unique ' || echo "$newcfg")
      fi
      [ -n "$newcfg" ] && apicall PUT "$PROWLARR_URL/api/v1/indexer/$id" "$PROWLARR_API_KEY" "$newcfg" || true
    done
  fi

  # Apply indexer priorities
  # RuTracker => 1, 1337x => 2, everything else => 25
  info "Setting indexer priorities (RuTracker=1, 1337x=2, others=25)"
  all_ids=$(apicall GET "$PROWLARR_URL/api/v1/indexer" "$PROWLARR_API_KEY" | jq -r '.[].id' || true)
  for id in $all_ids; do
    cfg=$(apicall GET "$PROWLARR_URL/api/v1/indexer/$id" "$PROWLARR_API_KEY" || true)
    [ -n "$cfg" ] || continue
    name=$(echo "$cfg" | jq -r '.name' | tr '[:upper:]' '[:lower:]')
    prio=25
    echo "$name" | grep -qi "rutracker" && prio=1
    echo "$name" | grep -qi "1337x" && prio=2
    newcfg=$(echo "$cfg" | jq --argjson p "$prio" '.priority = $p' || echo "")
    [ -n "$newcfg" ] && apicall PUT "$PROWLARR_URL/api/v1/indexer/$id" "$PROWLARR_API_KEY" "$newcfg" || true
  done
fi

# Wire Deluge as download client in Sonarr/Radarr/Lidarr (web client)
add_deluge_client() {
  app="$1"; url="$2"; key="$3"
  [ -z "$key" ] && return 0
  data=$(cat <<JSON
{
  "name":"Deluge","implementation":"Deluge","configContract":"DelugeSettings",
  "fields":[{"name":"host","value":"deluge"},{"name":"port","value":8112},{"name":"password","value":"${DELUGE_PASSWORD:-deluge}"}],
  "enable":true
}
JSON
)
  apicall POST "$url/api/v3/downloadclient" "$key" "$data" || true
}

add_deluge_client sonarr "${SONARR_URL:-http://sonarr:8989}" "${SONARR_API_KEY:-}"
add_deluge_client radarr "${RADARR_URL:-http://radarr:7878}" "${RADARR_API_KEY:-}"
add_deluge_client lidarr "${LIDARR_URL:-http://lidarr:8686}" "${LIDARR_API_KEY:-}"

# Add root folders if missing
add_root_folder() {
  url="$1"; key="$2"; path="$3"
  [ -z "$key" ] && return 0
  data=$(printf '{"path":"%s"}' "$path")
  apicall POST "$url/api/v3/rootfolder" "$key" "$data" || true
}

add_root_folder "${SONARR_URL:-http://sonarr:8989}" "${SONARR_API_KEY:-}" "/series"
add_root_folder "${SONARR_URL:-http://sonarr:8989}" "${SONARR_API_KEY:-}" "/anime"
add_root_folder "${RADARR_URL:-http://radarr:7878}" "${RADARR_API_KEY:-}" "/peliculas"
add_root_folder "${RADARR_URL:-http://radarr:7878}" "${RADARR_API_KEY:-}" "/documentales"
add_root_folder "${LIDARR_URL:-http://lidarr:8686}" "${LIDARR_API_KEY:-}" "/musica"

info "Bootstrap completed (best-effort). Review app UIs to confirm."


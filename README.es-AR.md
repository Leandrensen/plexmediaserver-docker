# 🎬 Stack de Servidor Multimedia con Docker

Configuración completa con Docker Compose para un servidor multimedia, optimizada para contenido en español (Argentina) con fallback en inglés.

## 📋 Servicios Incluidos

### 🎥 Servidores Multimedia
- **Plex** (principal)
- **Emby** (alternativo, deshabilitado por defecto)

### 🔍 Gestión de Contenido (*arr)
- **Sonarr** (series)
- **Radarr** (películas)
- **Lidarr** (música)
- **Bazarr** (subtítulos: es, es-MX, es-AR, en)

### 🌐 Indexadores
- **Prowlarr** (gestor principal de indexadores)
- **FlareSolverr** (anti-bot para indexadores detrás de Cloudflare)

### 📊 Monitoreo y Solicitudes
- **Tautulli** (estadísticas de Plex)
- **Ombi** (solicitudes de contenido)

### ⬇️ Descargas
- **Deluge** (cliente BitTorrent)
- **autobrr** (monitoreo de announces por IRC y filtros)

### 🛠️ Utilidades
- **Filebot** (renombrado/organización automática)

---

## 🚀 Inicio Rápido

### Requisitos
- Docker Desktop instalado (Windows/macOS) o Docker en Linux
- Espacio de almacenamiento suficiente

### 1) Clonar y preparar
```bash
git clone <tu-repo>
cd plexmediaserver-docker
cp env-template.txt docker/.env
```

### 2) Configurar entorno (`docker/.env`)
```bash
USER_ID=1000
GROUP_ID=1000
TIME_ZONE=America/Argentina/Buenos_Aires
DIR_MEDIASERVER=C:/Users/TU_USUARIO/mediaserver   # En Windows usar rutas tipo C:/...
DIR_DOWNLOADS=C:/Users/TU_USUARIO/Downloads/torrents
PLEX_CLAIM_TOKEN=
```

### 3) Crear carpetas
```bash
mkdir -p ${DIR_MEDIASERVER}/{plex,sonarr,radarr,lidarr,bazarr,prowlarr,tautulli,ombi,deluge,filebot}/config
mkdir -p ${DIR_MEDIASERVER}/media/{peliculas,series,documentales,anime,musica}
mkdir -p ${DIR_DOWNLOADS}/{incomplete,complete}
```

### 4) Override para Windows/macOS (Docker Desktop)
- Copiar `docker/docker-compose.override.example.yml` a `docker/docker-compose.override.yml` (habilita puertos de Plex sin host networking).

### 5) Levantar el stack
```bash
cd docker
docker compose up -d
```

### 6) Claves API y auto-configuración
1. Obtener claves API desde Prowlarr/Sonarr/Radarr/Lidarr (UI) y colocarlas en `docker/.env`.
2. Ejecutar bootstrap (auto cableado entre servicios):
```bash
docker compose run --rm bootstrap
```
3. (Opcional) Sincronizar perfiles con Recyclarr:
```bash
docker compose run --rm recyclarr recyclarr sync --config /config/recyclarr.yml
```

### 7) Accesos
- Plex: http://localhost:32400/web
- Sonarr: http://localhost:8989
- Radarr: http://localhost:7878
- Lidarr: http://localhost:8686
- Bazarr: http://localhost:6767
- Prowlarr: http://localhost:9696
- FlareSolverr: http://localhost:8191
- Deluge: http://localhost:8112
- Tautulli: http://localhost:8181
- Ombi: http://localhost:3579
- autobrr: http://localhost:7477

---

## 📁 Estructura de Medios
```
${DIR_MEDIASERVER}/media/
├── peliculas/
├── series/
├── documentales/
├── anime/
└── musica/
```

## 🔧 Notas
- En Windows/macOS no hay host networking; usar el override provisto.
- En Linux no usar el override (Plex en host networking rinde mejor).
- Prioridades en Prowlarr por bootstrap: RuTracker=1, 1337x=2, resto=25.
- 1337x se etiqueta/tunea con FlareSolverr automáticamente.

## 🛠️ Comandos útiles
```bash
docker compose up -d
docker compose down
docker compose ps
docker compose logs -f prowlarr
docker compose pull && docker compose up -d
```

## 🆘 Problemas comunes
- Compartir unidades en Docker Desktop (Settings → Resources → File Sharing).
- Firewalls/puertos en Windows.
- Si healthchecks dicen "unhealthy" pero la app abre, es por curl/tiempos; el servicio sigue activo.


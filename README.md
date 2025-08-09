# 🎬 Complete Media Server Docker Stack

A comprehensive Docker Compose configuration for a complete media server stack optimized for Spanish content with English fallbacks.

## 📋 **Services Included**

### 🎥 **Media Servers**
- **[Plex](https://www.plex.tv/)** - Primary media server with transcoding capabilities
- **[Emby](https://emby.media/)** - Alternative media server (disabled by default)

### 🔍 **Content Management (*arr Stack)**
- **[Sonarr](https://sonarr.tv/)** - TV series management and automation
- **[Radarr](https://radarr.video/)** - Movie management and automation  
- **[Lidarr](https://lidarr.audio/)** - Music management and automation
- **[Bazarr](https://www.bazarr.media/)** - Subtitle management (Spanish/English)

### 🌐 **Indexers**
- **[Prowlarr](https://prowlarr.com/)** - Modern indexer manager (primary)
- **[FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)** - Anti-bot solver service for Cloudflare-protected indexers

### 📊 **Monitoring & Management**
- **[Tautulli](https://tautulli.com/)** - Plex usage statistics and monitoring
- **[Ombi](https://ombi.io/)** - Media request management system

### ⬇️ **Download Clients**
- **[Deluge](https://deluge-torrent.org/)** - BitTorrent client with web interface
 - **[autobrr](https://autobrr.com/)** - IRC announce monitor and filtering to auto-grab torrents

### 🛠️ **Utilities**
- **[Filebot](https://www.filebot.net/)** - Automated file organization and renaming

---

## 🚀 **Quick Start**

### **Prerequisites**
- Docker and Docker Compose installed
- Sufficient storage space for media content
- Basic understanding of Docker concepts

### **1. Clone and Setup**
```bash
# Clone the repository
git clone <your-repo-url>
cd plexmediaserver-docker

# Create environment file
cp env-template.txt docker/.env
```

### **2. Configure Environment**
Edit `docker/.env` with your specific values:

```bash
# User Configuration (get with: id $USER)
USER_ID=1000
GROUP_ID=1000

# Timezone (Spanish examples)
TIME_ZONE=America/Argentina/Buenos_Aires # Argentina  
# TIME_ZONE=Europe/Madrid                # Spain
# TIME_ZONE=America/Mexico_City          # Mexico

# Directory Paths (CUSTOMIZE THESE!)
DIR_MEDIASERVER=/path/to/your/mediaserver
DIR_DOWNLOADS=/path/to/your/downloads

# Plex Claim Token (get from https://plex.tv/claim)
PLEX_CLAIM_TOKEN=your-claim-token-here
```

### **3. Create Directory Structure**
```bash
# Create required directories
mkdir -p ${DIR_MEDIASERVER}/{plex,sonarr,radarr,lidarr,bazarr,prowlarr,tautulli,ombi,deluge,filebot}/config
mkdir -p ${DIR_MEDIASERVER}/media/{peliculas,series,documentales,anime,musica}
mkdir -p ${DIR_DOWNLOADS}/{incomplete,complete}

# Set proper permissions
chown -R ${USER_ID}:${GROUP_ID} ${DIR_MEDIASERVER} ${DIR_DOWNLOADS}
```

### **4. Launch the Stack**
```bash
cd docker
docker compose up -d
```

If you are on Windows or macOS (Docker Desktop):
- Plex host networking is not supported. Use the provided override to map Plex ports:
  1) Copy `docker/docker-compose.override.example.yml` to `docker/docker-compose.override.yml`
  2) Windows: use Windows paths in `docker/.env` (e.g., `C:/Users/you/...`)
     macOS: ensure your paths are shared in Docker Desktop (Settings → Resources → File Sharing)
  3) Run `docker compose up -d` again

---

## 🌐 **Service Access**

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **Plex** | 32400 | http://your-ip:32400/web | Primary Media Server |
| **Sonarr** | 8989 | http://your-ip:8989 | TV Show Management |
| **Radarr** | 7878 | http://your-ip:7878 | Movie Management |
| **Lidarr** | 8686 | http://your-ip:8686 | Music Management |
| **Bazarr** | 6767 | http://your-ip:6767 | Subtitle Management |
| **Prowlarr** | 9696 | http://your-ip:9696 | Indexer Management |
| **FlareSolverr** | 8191 | http://your-ip:8191 | Anti-bot Solver |
| **Tautulli** | 8181 | http://your-ip:8181 | Plex Statistics |
| **Ombi** | 3579 | http://your-ip:3579 | Request System |
| **Deluge** | 8112 | http://your-ip:8112 | Download Client |
| **autobrr** | 7477 | http://your-ip:7477 | IRC Announce Automation |

---

## ♻️ Declarative and Automated Setup

This stack supports repeatable, zero-click setup using two approaches:

### 1) Recyclarr (Sonarr/Radarr config as code)
- Container `recyclarr` reads `docker/recyclarr/recyclarr.yml` and syncs quality profiles, custom formats, naming, and root folders into Sonarr/Radarr.
- Commit your preferences to Git and rerun anytime.

### 2) Bootstrap (API wiring of services)
- Container `bootstrap` waits until services are healthy and calls their APIs to wire them together:
  - Prowlarr → adds Sonarr/Radarr/Lidarr as Apps and pushes indexers
  - Sonarr/Radarr/Lidarr → adds Deluge as download client and sets categories
  - Bazarr → connects to Sonarr/Radarr
  - Ombi → can be connected as needed
- Configure API keys and passwords in `docker/.env` (or Docker secrets). Do not commit real secrets.

To run a full sync on demand:
```bash
docker compose run --rm recyclarr recyclarr sync --config /config/recyclarr.yml
```

### 3) Indexer & Proxy Seeding (Prowlarr)
- Place indexer JSON templates in `docker/prowlarr/indexers/*.json`
- Place proxy JSON templates (e.g., FlareSolverr) in `docker/prowlarr/proxies/*.json`
- Templates support `${ENV_VARS}` via envsubst. Define them in `docker/.env`.
- Provided examples in this repo:
  - Indexers: 1337x, BitSearch, EZTV, RuTracker, Torrentz2nz, `example.json`
  - Proxy: FlareSolverr
- The bootstrap will:
  - Create proxies from `docker/prowlarr/proxies`
  - Create indexers from `docker/prowlarr/indexers`
  - Link a proxy named "FlareSolverr" to any indexer whose name contains "1337x"
  - Ensure/assign a `flaresolverr` tag on those indexers
  - Apply priorities: RuTracker=1, 1337x=2, others=25

Run bootstrap any time after first boot (and after adding API keys to `docker/.env`):
```bash
cd docker
docker compose run --rm bootstrap
```

**Disabled Services:**
- **Emby**: Port 8096 (uncomment in docker-compose.yml to enable)
- **Jackett**: Port 9117 (uncomment if needed for specific indexers)

---

## ⚙️ **Configuration Guide**

### **Setup Order (Important!)**
1. **Prowlarr** → Configure indexers and download clients
   - Option A: Let bootstrap seed indexers/proxies from templates and wire everything
   - Option B: Configure manually in UI
   - Note: FlareSolverr is available at `http://flaresolverr:8191` and will be auto-linked to 1337x by bootstrap
2. **Sonarr/Radarr/Lidarr** → Connect to Prowlarr as indexer
3. **Bazarr** → Connect to Sonarr/Radarr for subtitle automation
4. **Plex** → Add media libraries
5. **Ombi** → Connect to Plex and *arr services for requests

### **Media Library Structure**
```
${DIR_MEDIASERVER}/media/
├── peliculas/          # Movies (Radarr)
├── series/             # TV Shows (Sonarr)
├── documentales/       # Documentaries (Radarr)
├── anime/              # Anime (Sonarr)
└── musica/             # Music (Lidarr)
```

### **Subtitle Configuration (Bazarr)**
Pre-configured languages:
- **Spanish** (es)
- **Spanish Latin America** (es-MX)
- **Spanish Argentina** (es-AR)
- **English** (en)

---

## 🔧 **Advanced Configuration**

### **Network Architecture**
- **Plex**: Host networking for optimal streaming performance (Linux server)
- **All other services**: Custom bridge network `mediaserver` for isolation and service discovery
- **Deterministic network name**: Network is explicitly named `mediaserver`
- **Service dependencies**: Proper startup order with dependency management

### **Volume Optimization**
- **Config directories**: Persistent storage for service configurations
- **Media directories**: Optimized paths for cross-service compatibility
- **Downloads**: Shared directory for automated processing

### **Performance Tips**
1. **Storage**: Use SSD for `DIR_MEDIASERVER`, HDD acceptable for `DIR_DOWNLOADS`
2. **Network**: Plex host networking provides best streaming performance
3. **Resources**: Ensure adequate RAM for transcoding (8GB+ recommended)
4. **Download workflow**: Deluge uses `/downloads/incomplete` and `/downloads/complete` for better automation
5. **Backup**: Regular backups of config directories recommended (never commit secrets)
6. **Announce automation**: Configure autobrr filters and connect it to your indexers and Deluge for hands-off snatches

---

## 🛠️ **Management Commands**

### **Basic Operations**
```bash
# Start all services
docker compose up -d

# Stop all services  
docker compose down

# View logs
docker compose logs -f [service-name]

# Update services
docker compose pull
docker compose up -d
```

### **Service Management**
```bash
# Restart specific service
docker compose restart sonarr

# View service status
docker compose ps

# Access service shell
docker compose exec sonarr bash
```

---

## 🔍 **Troubleshooting**

### **Common Issues**
1. **Permission Errors**: Ensure USER_ID/GROUP_ID match your system user
2. **Network Issues**: Check firewall settings for required ports
3. **Plex Claim**: Token expires in ~4 minutes, regenerate if needed
4. **Storage Space**: Monitor disk usage, especially for downloads

### **Logs and Debugging**
```bash
# Check all service logs
docker compose logs

# Monitor specific service
docker compose logs -f plex

# Check Docker network
docker network ls
docker network inspect mediaserver
```

---

## 📁 **File Structure**
```
plexmediaserver-docker/
├── docker/
│   ├── docker-compose.yml    # Main configuration
│   └── .env                  # Environment variables
├── bash scripts/
│   └── movie2folder.sh       # File organization script
└── README.md                 # This file
```

---

## 🔄 **Migration from Old Setup**

If upgrading from a previous configuration:

1. **Backup existing configs**: `tar -czf configs-backup.tar.gz ${DIR_MEDIASERVER}/*/config`
2. **Update compose file**: Follow this new structure
3. **Migrate Jackett → Prowlarr**: Export/import indexer configurations
4. **Test services**: Verify all integrations work correctly

---

## 🆘 **Support & Resources**

### **Official Documentation**
- [Plex Documentation](https://support.plex.tv/)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Bazarr Documentation](https://wiki.bazarr.media/)

### **Community Support**
- [LinuxServer.io Discord](https://discord.gg/YWrKVTn)
- [r/Plex Subreddit](https://reddit.com/r/Plex)
- [Servarr Discord](https://discord.gg/3uqHB4r)

---

## 📄 **License**

This configuration is provided as-is for educational and personal use. Ensure compliance with local laws regarding media downloading and sharing.

---

## 🔖 **Version History**

- **v2.0** - Complete rewrite with Prowlarr, Bazarr, network optimization
- **v1.0** - Initial release with basic Plex + *arr stack
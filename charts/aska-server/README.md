# Aska Server Helm Chart

This Helm chart deploys an [Aska](https://store.steampowered.com/app/1898300/ASKA/) dedicated game server using the [luxusburg/aska-server](https://hub.docker.com/r/luxusburg/aska-server) Docker image.

## Features

- ✅ Fully configurable via `values.yaml`
- ✅ Persistent storage support for game saves
- ✅ LoadBalancer service for easy access via UDP
- ✅ Resource limits and requests
- ✅ Flexible environment variable configuration

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume provisioner support in the underlying infrastructure (if using persistent storage)

### Quick Start

1. Enable the server in your values file:

```yaml
enabled: true
```

2. Configure persistent storage:

```yaml
persistence:
  enabled: true
  storageClass: "your-storage-class"
  size: "20Gi"
```

3. Set up service networking:

```yaml
service:
  type: LoadBalancer
  annotations:
    io.cilium/lb-ipam-ips: 192.168.2.XXX  # Your desired IP
```

4. Configure server settings:

```yaml
serverConfig:
  timezone: "Europe/Paris"
  serverName: "My Aska Server"
  password: "yourpassword"
  serverPort: 27015
  serverQueryPort: 27016
  keepWorldAlive: false
  autoSaveStyle: "every morning"
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable or disable the deployment | `false` |
| `image.repository` | Docker image repository | `luxusburg/aska-server` |
| `image.tag` | Docker image tag | `latest` |
| `serverConfig.timezone` | Server timezone | `UTC` |
| `serverConfig.serverName` | Server display name | `Aska Dedicated Server` |
| `serverConfig.password` | Server password | `""` (no password) |
| `serverConfig.serverPort` | Game port | `27015` |
| `serverConfig.serverQueryPort` | Query port | `27016` |
| `serverConfig.keepWorldAlive` | Keep world alive without players | `false` |
| `serverConfig.autoSaveStyle` | Autosave frequency | `every morning` |
| `serverConfig.customConfig` | Use custom config file | `false` |
| `serverConfig.puid` | User ID for file permissions | `1000` |
| `serverConfig.pgid` | Group ID for file permissions | `1000` |
| `persistence.enabled` | Enable persistent storage | `false` |
| `persistence.size` | Storage size | `20Gi` |
| `service.type` | Service type | `LoadBalancer` |
| `service.ports` | Service port configurations | See values.yaml |
| `resources` | CPU/Memory resource requests/limits | `{}` |
| `extraEnv` | Additional environment variables | `[]` |
| `extraManifests` | Additional Kubernetes manifests | `[]` |

### Network Ports

The default port configuration:
- **27016/UDP**: Game query port
- **27015/UDP**: Game port
- **8080/TCP**: HTTP health check endpoint (responds on `/health`)

You can customize these in the `service.ports` section of your values file.

### Persistent Storage

The server stores all game data and server files in `/home/ubuntu/server_files` within the container. An additional ephemeral volume is mounted using `emptyDir`:
- `/tmp` - Temporary directory for writable temp files

This ensures the temp directory is writable when running with restricted permissions.

For production use, create a PersistentVolume using the `extraManifests` field:

**Example PV via extraManifests** (in `values.yaml`):
```yaml
extraManifests:
  - apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: aska-server-pv
      labels:
        app: aska-server
        type: game-data
    spec:
      capacity:
        storage: 20Gi
      accessModes:
        - ReadWriteOnce
      persistentVolumeReclaimPolicy: Retain
      storageClassName: csi-driver-nfs-skynetsrv-fast
      csi:
        driver: nfs.csi.k8s.io
        volumeHandle: aska-server-pv
        volumeAttributes:
          server: 192.168.20.2
          share: /mnt/fast/k8s/game-servers/aska
```

The StatefulSet's volumeClaimTemplate will automatically create a PVC that binds to this pre-created PV.

The `extraManifests` field allows you to deploy additional Kubernetes resources (PVs, ConfigMaps, Secrets, etc.) alongside the main chart.

### Server Configuration

The chart provides a structured `serverConfig` section for all server settings:

#### Available Settings

| Setting | Description | Options |
|---------|-------------|---------|
| `timezone` | Server timezone | e.g., `Europe/Paris`, `America/New_York` |
| `serverName` | Display name in session list | Any string |
| `password` | Server password | Empty for no password |
| `serverPort` | Port for client connections | Default: `27015` |
| `serverQueryPort` | Port for server browser queries | Default: `27016` |
| `authenticationToken` | Token for non-Steam auth | Optional |
| `region` | Server region | Leave empty for auto |
| `keepWorldAlive` | Update world without players | `true` or `false` |
| `autoSaveStyle` | Save frequency | `every morning`, `disabled`, `every 5 minutes`, `every 10 minutes`, `every 15 minutes`, `every 20 minutes` |
| `customConfig` | Use manual config file | `true` or `false` |
| `puid` | User ID for file permissions | Default: `1000` |
| `pgid` | Group ID for file permissions | Default: `1000` |

**Note**: When `customConfig` is set to `true`, you must manually provide a `server_properties.txt` file, and the environment variable configuration will be ignored.

## Examples

### Minimal Configuration

```yaml
enabled: true

persistence:
  enabled: true
  storageClass: "csi-driver-nfs-skynetsrv-fast"
  size: "20Gi"
```

### Production Configuration

```yaml
enabled: true

serverConfig:
  timezone: "Europe/Paris"
  serverName: "Prod Aska Server"
  password: "secure-password"
  serverPort: 27015
  serverQueryPort: 27016
  keepWorldAlive: true
  autoSaveStyle: "every 10 minutes"
  puid: 1000
  pgid: 1000

persistence:
  enabled: true
  storageClass: "fast-storage"
  size: "50Gi"

service:
  type: LoadBalancer
  annotations:
    io.cilium/lb-ipam-ips: 192.168.2.100

resources:
  requests:
    cpu: 1000m
    memory: 4Gi
  limits:
    cpu: 2000m
    memory: 8Gi

nodeSelector:
  kubernetes.io/hostname: gaming-node-1
```

## Troubleshooting

### Server not starting

1. Check pod logs:
```bash
kubectl logs -n game-servers <pod-name>
```

2. Verify the persistent volume is bound:
```bash
kubectl get pvc -n game-servers
```

### Connection issues

1. Verify service is created and has an external IP:
```bash
kubectl get svc -n game-servers
```

2. Check if ports are accessible:
```bash
# Test UDP connectivity
nc -u <server-ip> 27016
```

## Upgrading

```bash
helm upgrade aska-server ./charts/aska-server -n game-servers
```

## Uninstalling

```bash
helm uninstall aska-server -n game-servers
```

**Note**: Persistent volumes and claims are not automatically deleted. Delete them manually if needed:
```bash
kubectl delete pvc -n game-servers <pvc-name>
```


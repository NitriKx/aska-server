# Docker for a Aska dedicated server
[![GitHub Container Registry](https://img.shields.io/badge/GitHub_Container_Registry-aska--server-blue?logo=github)](https://github.com/users/luxusburg/packages/container/package/aska-server)

## Table of contents
- [Docker Run command](#docker-run)
- [Docker Compose command](#docker-compose-deployment)
- [Health Check](#health-check)
- [Environment variables server settings](#environment-variables-game-settings)
- [Environment variables for the User PUID/GUID](#environment-variables-for-the-user-puidguid)
- [Environemnt variables for the beta branch](#environemnt-variables-for-the-beta-branch)

This is a Docker container to help you get started with hosting your own [Aska](https://playaska.com/) dedicated server.

This Docker container has been tested and will work on the following OS:

- Linux (Ubuntu/Debian)

> [!TIP]
> Add environment variables so that you can for example change the password of the server
> On the bottom you will find a list of all environment variables to change, if you want to use your own server_properties.txt file
> set the CUSTOM_CONFIG to true

> [!IMPORTANT]
> The first server start can take a few minutes! If you are stuck in the logs on this part just be a bit more patient:

```bash
wine: created the configuration directory '/home/aska/.wine'
002c:fixme:actctx:parse_depend_manifests Could not find dependent assembly L"Microsoft.Windows.Common-Controls" (6.0.0.0)
004c:fixme:actctx:parse_depend_manifests Could not find dependent assembly L"Microsoft.Windows.Common-Controls" (6.0.0.0)
0054:fixme:actctx:parse_depend_manifests Could not find dependent assembly L"Microsoft.Windows.Common-Controls" (6.0.0.0)
0054:err:ole:StdMarshalImpl_MarshalInterface Failed to create ifstub, hr 0x80004002
0054:err:ole:CoMarshalInterface Failed to marshal the interface {6d5140c1-7436-11ce-8034-00aa006009fa}, hr 0x80004002
0054:err:ole:apartment_get_local_server_stream Failed: 0x80004002
0054:err:ole:start_rpcss Failed to open RpcSs service
004c:err:ole:StdMarshalImpl_MarshalInterface Failed to create ifstub, hr 0x80004002
004c:err:ole:CoMarshalInterface Failed to marshal the interface {6d5140c1-7436-11ce-8034-00aa006009fa}, hr 0x80004002
004c:err:ole:apartment_get_local_server_stream Failed: 0x80004002
0090:err:winediag:gnutls_process_attach failed to load libgnutls, no support for encryption
0090:err:winediag:process_attach failed to load libgnutls, no support for pfx import/export
0098:err:winediag:gnutls_process_attach failed to load libgnutls, no support for encryption
```

## Docker Run

**This will create the folders './server' and './data' in your current folder where you execute the code**

**Recommendation:**
Create a folder before executing this docker command

To deploy this docker project run:

```bash
docker run -d \
    --name aska \
    -p 27016:27016/udp \    
    -p 27015:27015/udp \
    -p 8080:8080 \
    -v ./server:/home/aska/server_files \
    -e TZ=Europe/Paris \
    -e PASSWORD=change_me \
    -e SERVER_NAME='Aska docker by Luxusburg' \
    -e KEEP_WORLD_ALIVE=false \
    ghcr.io/luxusburg/aska-server:latest
```

## Docker compose Deployment

**This will create the folders './server' and './data' in your current folder where you execute combose file**

**Recommendation:**
Create a folder before executing the docker compose file

> [!IMPORTANT]
> Older docker compose version needs this line before the **services:** line
>
> version: '3'

```yml
services:
  aska:
    container_name: aska
    image: ghcr.io/nitrikx/aska-server:latest
    network_mode: bridge
    environment:
      - TZ=Europe/Paris
      - PASSWORD=change_me
      - SERVER_NAME='Aska docker by Luxusburg'
      - KEEP_WORLD_ALIVE=false
    volumes:
      - './server:/home/aska/server_files:rw'
    ports:
      - '27016:27016/udp'
      - '27015:27015/udp'
      - '8080:8080'
    restart: unless-stopped
```

## Health Check

The container includes a built-in health check mechanism that works with both Docker and Kubernetes:

### Docker Health Check
The Docker health check is automatically configured and will:
- Check every 30 seconds if the server is running
- Wait 120 seconds after container start before checking (to allow server initialization)
- Mark the container as unhealthy after 3 consecutive failures

You can check the health status with:
```bash
docker ps  # Shows health status in STATUS column
docker inspect --format='{{.State.Health.Status}}' aska
```

### Kubernetes Health Check
For Kubernetes deployments, you can use HTTP probes on port 8080:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: aska-server
spec:
  containers:
  - name: aska
    image: ghcr.io/luxusburg/aska-server:latest
    ports:
    - containerPort: 27015
      protocol: UDP
    - containerPort: 27016
      protocol: UDP
    - containerPort: 8080
      protocol: TCP
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 120
      periodSeconds: 30
      timeoutSeconds: 10
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 60
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
```

### Manual Health Check
You can manually check the health endpoint:
```bash
curl http://localhost:8080/health
```

Response when healthy:
```json
{"status":"healthy","server":"running"}
```

Response when unhealthy:
```json
{"status":"unhealthy","server":"not running"}
```

> [!NOTE]
> The health check verifies that the AskaServer.exe process is running. It runs on port 8080 and does not interfere with the game server's UDP ports.

## Environment variables server settings

You can use these environment variables for your server settings:

| Variable | Key | Description |
| -------------------- | ---------------------------- | ------------------------------------------------------------------------------- |
| TZ | Europe/Paris | timezone |
| SERVER_NAME | optional Server Name | Override for the host name that is displayed in the session list |
| PASSWORD | optional password | Sets the server password. |
| SERVER_PORT | default: 27015  | The port that clients will connect to for gameplay |
| SERVER_QUERY_PORT | default: 27016 | The port that will manage server browser related duties and info  |
| AUTHENTICATION_TOKEN | optional | The token needed for an authentication without a Steam client |
| REGION | optional see config file for options | Leave default to ping the best region |
| KEEP_WORLD_ALIVE | default: false | If set to true when the session is open, the world is also updating, even without players, if set to false, the world loads when the first player joins and the world unloads when the last player leaves |
| AUTOSAVE_STYLE | default: every morning | The style in which the server should save, possible options: every morning, disabled, every 5 minutes, every 10 minutes, every 15 minutes, every 20 minutes  |
| SAVE_ID | optional | The save ID to load an existing save file (what comes after "savegame_" in the save file name). When creating a new save, the server will fill this in automatically. |
| SEED | optional | The seed for generating a new world. This is ignored if loading an existing save. |
| CUSTOM_CONFIG | optional: true of false | Set this to true if the server should only accept you manual adapted server_properties.txt file |

**More options exists in the server properties files please modify it in there!**

## Environment variables for the User PUID/GUID

| Variable | Key | Description |
| -------------------- | ---------------------------- | ------------------------------------------------------------------------------- |
| PUID | default: 1000 | User ID |
| PGUID | default: 1000| Group ID |

## Environemnt variables for the beta branch

| Variable | Key | Description |
| -------------------- | ---------------------------- | ------------------------------------------------------------------------------- |
| BETANAME |  no default value| Set the beta branch name. Don't use `""` or `''`!|
| BETAPASSWORD | no default value | Set the beta branch password. Don't use `""` or `''`! |

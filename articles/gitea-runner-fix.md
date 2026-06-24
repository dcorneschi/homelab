[![Gitea](https://img.shields.io/badge/Gitea-609926?logo=gitea&logoColor=white)](https://gitea.io/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

### Problem

Gitea runners hitting Docker Hub rate limits when pulling images:


> Error response from daemon: toomanyrequests: You have reached your unauthenticated pull rate limit


### Solution: Mount Docker Config File

Mount the Docker config file directly into the runner container:

```yaml
volumes:
  - ./docker-config.json:/root/.docker/config.json:ro
```

### How It Works

**File Structure:**

```
Your Project Directory:
├── docker-compose.yml
├── docker-config.json  ← Authentication file
└── .env
```

**Mount Explanation:**

- `./docker-config.json` - File on your host machine
- `/root/.docker/config.json` - Where Docker expects auth config in container
- `:ro` - Read-only mount (container can't modify the file)

### Step-by-Step Setup

#### 1. Create Docker Hub Personal Access Token
- Go to [https://hub.docker.com](https://hub.docker.com)
- Account Settings → Security → Personal Access Tokens
- Create token with "Public Repo Read-only" permissions

<img width="647" height="386" alt="Docker_access_token" src="https://gist.github.com/user-attachments/assets/163b02b9-8a7e-4c65-8c7e-2e3361821ad8" />

#### 2. Generate Base64 Auth String

```bash
echo -n "your-docker-username:your-docker-token" | base64
```

#### 3. Create docker-config.json

```json
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "your-base64-string-here"
    }
  }
}
```

#### 4. Update docker-compose.yml

```yaml
version: '3.8'
services:
  gitea-runner:
    image: gitea/act_runner:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - gitea-runner-data:/data
      - ./docker-config.json:/root/.docker/config.json:ro  # ← This line
```

#### 5. Restart Runner

```bash
docker-compose down
docker-compose up -d
```

### Verification

Check logs for successful authentication:

```bash
docker-compose logs -f gitea-runner
```

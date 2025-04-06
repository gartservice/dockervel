# 📦 Steps to Create a New Tunnel for Websites

## 1. ⚙️ Authenticate (if needed)
Run the following command to authenticate. This will open your browser and authenticate once:
```bash
cloudflared tunnel login
```

## 2. 🚀 Create the New Tunnel
Run the following command to create a new tunnel. You’ll get a Tunnel ID and a `web-tunnel.json` credentials file (saved in `~/.cloudflared`):
```bash
cloudflared tunnel create web-tunnel
```

## 3. 📄 Create a `config.yml`
Save the following configuration as `~/.cloudflared/config.yml` or in a project directory:
```yaml
tunnel: web-tunnel-id-goes-here
credentials-file: /home/youruser/.cloudflared/web-tunnel.json

ingress:
  - hostname: site1.example.com
    service: http://localhost:8081
  - hostname: site2.example.com
    service: http://localhost:8082
  - service: http_status:404
```
You can generate this file dynamically based on your `config.json`.

## 4. 🌍 Register Each Domain (CNAME or Route DNS)
Use the following commands to register each domain:
```bash
cloudflared tunnel route dns web-tunnel site1.example.com
cloudflared tunnel route dns web-tunnel site2.example.com
```
Alternatively, you can do this via the Cloudflare API.

## 5. 🌀 Run the Tunnel (Manually or via systemd)
Run the tunnel manually:
```bash
cloudflared tunnel run web-tunnel
```
Or install it as a service:
```bash
cloudflared service install --config /home/youruser/.cloudflared/config.yml
# Runbook: Killing a hung staging deploy

Use this when a Hatchbox deploy to staging appears to hang — the site is unreachable, EC2 CPU is running hot, and the deploy never completes.

## Background

Hatchbox manages Puma (the web server) and Sidekiq (background jobs) as **systemd services** — think of systemd as a process supervisor that automatically restarts crashed processes. This is why you can't just `kill -9` a PID: systemd sees it die and immediately spawns a new one with a fresh PID.

The fix is to stop the service at the systemd level, so it doesn't respawn.

## Step 1 — SSH into the server and confirm what's eating CPU

```bash
ps aux --sort=-%cpu | head -20
```

You're looking for `puma` and `sidekiq` processes under the `deploy` user with high CPU. There will be two sets: production (port 9000, low CPU, started days ago) and staging (port 9010, high CPU, started recently). Don't touch the production ones.

## Step 2 — List the running services

```bash
systemctl --user list-units --type=service
```

`--user` scopes this to services running as the `deploy` user (as opposed to system-wide services). You should see four entries:

```
lester-server.service           ← production Puma   (leave alone)
lester-sidekiq.service          ← production Sidekiq (leave alone)
lester-staging-server.service   ← staging Puma      (stop this)
lester-staging-sidekiq.service  ← staging Sidekiq   (stop this)
```

## Step 3 — Stop the staging services

```bash
systemctl --user stop lester-staging-server.socket lester-staging-server.service lester-staging-sidekiq.service
```

Why include `lester-staging-server.socket`? Hatchbox uses a socket to hand HTTP connections to Puma. If you only stop the `.service`, systemd warns that the socket is still active and may respawn the service when a new connection arrives. Stopping the socket first closes that loophole.

## Step 4 — Confirm it worked

```bash
systemctl --user list-units --type=service
```

You should now only see the two production services. Run `ps aux --sort=-%cpu | head -10` to confirm CPU is back to normal.

## Step 5 — Redeploy from Hatchbox

Go to the Hatchbox dashboard and trigger a fresh deploy for the staging app. The services will be recreated automatically by the deploy process.

## Quick reference (copy-paste)

```bash
# 1. See what's using CPU
ps aux --sort=-%cpu | head -20

# 2. List services
systemctl --user list-units --type=service

# 3. Stop staging (socket first, then server + sidekiq)
systemctl --user stop lester-staging-server.socket lester-staging-server.service lester-staging-sidekiq.service

# 4. Confirm
systemctl --user list-units --type=service
```

# n8n Self-Hosted on Google Cloud

Deploy [n8n](https://n8n.io/) on Google Cloud Compute Engine using Docker, persistent storage, and private editor access through an SSH tunnel.

> **Project status:** starter configuration and deployment notes based on a personal setup. Validate the steps in a test environment before relying on them for production. In the original setup, browser-based Google Cloud SSH worked, but direct SSH authentication from macOS still needed troubleshooting.

## Goals

- Run n8n on a Compute Engine VM.
- Persist n8n settings, workflows, and credentials in a Docker named volume.
- Access the editor from a Mac browser through an encrypted SSH tunnel.
- Keep port 5678 bound to VM loopback instead of exposing the editor directly to the internet.
- Keep project identifiers, IP addresses, usernames, and secrets out of this public repository.

## Architecture

```text
Mac browser: http://127.0.0.1:5678
          |
          v
Encrypted SSH local port forwarding (TCP/22)
          |
          v
Google Cloud VM: 127.0.0.1:5678
          |
          v
Docker -> n8n container:5678
          |
          v
Persistent Docker volume: n8n_data
```

## Prerequisites

- A Google Cloud project and Compute Engine VM running Debian.
- Docker Engine and the Docker Compose plugin installed on the VM.
- SSH access to the VM, using a configured SSH key or Google Cloud's browser-based SSH.
- A Mac with its built-in SSH client and a browser.
- Google Cloud firewall rules that do not allow public inbound access to TCP/5678.

The original environment used Debian 13, an e2-small VM in `us-central1-b`, and n8n `2.43.6`. These are historical reference values, not requirements or a statement of the latest available release. Review current n8n release notes and cloud pricing before deployment.

## Get the repository files onto the VM using Google Cloud Shell

Google Cloud Shell is a terminal opened from the Google Cloud Console. It is not the VM itself: commands run in Cloud Shell initially affect the Cloud Shell environment. To run Docker commands on the server, first connect to the VM. The steps below clone the public repository **directly onto the VM**, so the Compose file is available where Docker runs.

1. Open the Google Cloud Console and start **Cloud Shell**.
2. Connect to your Compute Engine VM from Cloud Shell:

   ```sh
   gcloud compute ssh n8n-server --zone=us-central1-b
   ```

   Replace the VM name and zone if yours are different. If the command succeeds, your terminal session is now the Debian shell on the VM. Commands entered after this point run on the VM until you disconnect.

3. Check whether Git is installed:

   ```sh
   git --version
   ```

   If the command is not found, install Git on Debian only if you are comfortable making that change:

   ```sh
   sudo apt-get update
   sudo apt-get install -y git
   ```

4. Clone the repository onto the VM and enter its directory:

   ```sh
   git clone https://github.com/masgioia/n8n-google-cloud-self-hosted.git
   cd n8n-google-cloud-self-hosted
   ls
   ```

   The `ls` output should include `docker-compose.yml` and `.env.example`. If the directory already exists, do not run `git clone` again; inspect that directory and update it deliberately instead.

5. At this point, the YAML file is present on the VM. Docker Compose can read it when a command is run from this directory. The file is **not** automatically connected to Cloud Shell or to Docker just because it exists on GitHub.

**Important for an existing n8n installation:** these steps only download the configuration files; they do not change the running container. Do not run `docker compose up -d` yet if n8n is already running. First compare the repository's Compose file with the live container's image, port binding, mounts, environment settings, and persistent volume. Do not create a second `.env` encryption key for an existing installation: n8n's encryption key must match the one used for its stored credentials. Keep the existing volume and key safe.

## 1. Configure environment variables (new deployment only)

For a new deployment, copy `.env.example` to a private `.env` file in the directory where you will run Compose. Generate a strong encryption key:

```sh
openssl rand -hex 32
```

Put the generated value in `N8N_ENCRYPTION_KEY` in `.env`. Keep the key stable: changing it can make previously stored credentials unreadable. Back it up securely alongside your n8n data. **Never commit `.env` or the real key.**

For an existing installation, do not replace its encryption key with a newly generated one. Establish the current configuration and key-management arrangement before changing how the container is deployed.

## 2. Start n8n (new deployment or verified migration only)

Place `docker-compose.yml` and `.env` in the same private directory on the VM, then run:

```sh
docker compose up -d
docker compose ps
docker compose logs --tail=100 n8n
```

The configuration publishes the container port only on the VM's loopback address (`127.0.0.1:5678`). The named volume `n8n_data` keeps data when the container is recreated.

**Do not run these commands against an existing installation until you have verified that the Compose file matches the current container.** A Compose file describes the desired configuration; `docker compose up -d` applies it and may create or change containers.

## 3. Open the SSH tunnel from macOS

Run this command in the Mac Terminal after SSH key authentication is configured. Replace the placeholders with your VM's public IP address, Linux username, and private-key path:

```sh
ssh -i ~/.ssh/YOUR_SSH_KEY -N -L 127.0.0.1:5678:127.0.0.1:5678 YOUR_LINUX_USERNAME@YOUR_VM_EXTERNAL_IP
```

For example, if your private key is stored at `~/.ssh/n8n_gcp`, use that path in place of `~/.ssh/YOUR_SSH_KEY`. Do not put a real IP address, username, or private key in this public repository.

Keep the Terminal window open while you use n8n. Visit [http://127.0.0.1:5678](http://127.0.0.1:5678) in your browser. Stop the tunnel with `Ctrl+C`; this does not stop n8n.

If direct SSH from macOS is not working, use Google Cloud browser-based SSH to administer the VM and troubleshoot authentication. A tunnel started inside Cloud Shell binds to Cloud Shell, not to the Mac; its port preview is a separate access path.

## 4. Verify the binding

On the VM, run:

```sh
docker compose ps
docker port n8n 5678
```

Verify that the host-side binding is `127.0.0.1:5678`, not `0.0.0.0:5678` or the VM's public IP. Review VPC firewall rules as well. Do not expose port 5678 publicly.

## Persistence, backups, and upgrades

- Never remove the `n8n_data` volume as a troubleshooting shortcut.
- Back up both n8n's persistent data and the matching encryption key.
- Test restoring a backup before relying on it.
- Before upgrading, read the release notes, back up the data, and deliberately change the pinned image tag.
- Avoid using `latest` for a deployment that should be reproducible.

## Security notes

- Never commit `.env`, SSH private keys, workflow exports containing sensitive information, databases, or volume backups.
- Use a strong n8n owner account password and keep the VM and Docker updated.
- Keep port 5678 private. SSH tunnelling does not replace n8n's own authentication.
- External webhook integrations need a separately designed secure endpoint; do not open the editor port publicly to make webhooks work.
- See [docs/SECURITY.md](docs/SECURITY.md) for a checklist.

## Repository contents

- `docker-compose.yml` — pinned container configuration.
- `.env.example` — placeholder environment variables.
- `.gitignore` — excludes local secrets and data.
- `docs/SECURITY.md` — security checklist.
- `LICENSE` — MIT license for the repository's original files.

## License and trademarks

Original files in this repository are provided under the MIT License. n8n and Google are separate products; this independent project is not affiliated with or endorsed by either company.

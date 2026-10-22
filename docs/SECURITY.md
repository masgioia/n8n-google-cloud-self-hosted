# Security checklist

## Before deployment

- [ ] Keep this repository free of cloud project IDs, public/internal IP addresses, personal usernames, private keys, access tokens, and credentials.
- [ ] Restrict SSH access using Google Cloud firewall rules, OS Login, and/or managed SSH keys as appropriate.
- [ ] Do not allow public inbound TCP/5678 in VPC firewall rules.
- [ ] Keep the Docker host port bound to `127.0.0.1:5678`.
- [ ] Set a strong n8n owner account password.
- [ ] Generate a unique `N8N_ENCRYPTION_KEY` and store it outside Git.
- [ ] Protect the VM with least-privilege IAM permissions and routine security updates.

## Data protection

- [ ] Back up the persistent `n8n_data` volume.
- [ ] Back up the matching encryption key separately and securely.
- [ ] Test restoration in a controlled environment.
- [ ] Review workflow exports before sharing; they can disclose internal URLs and operational details.

## Maintenance

- [ ] Review n8n release notes before upgrades.
- [ ] Back up before changing the pinned image version.
- [ ] Check container logs and verify the actual host port binding after changes.
- [ ] Do not delete the named volume to troubleshoot a container startup problem.

## Webhooks

Private editor access and public webhook reception are separate requirements. If workflows need inbound webhooks from external services, design a dedicated authenticated/TLS endpoint and expose only the minimum required surface. Do not expose the n8n editor port as a shortcut.

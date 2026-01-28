# systemd-age-creds

Load [age](https://github.com/FiloSottile/age) encrypted credentials in [systemd units](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html).

> **Note:** This is a fork of [josh/systemd-age-creds](https://github.com/josh/systemd-age-creds) with Nix-based deployment replaced by containerized deployment using Podman Quadlet.

At the moment, [systemd-creds](https://www.freedesktop.org/software/systemd/man/latest/systemd-creds.html) only support symmetric encryption requiring secrets to be encrypted on the machine with the TPM itself. Though, it's on the [systemd TODO](https://github.com/systemd/systemd/blob/e8fb0643c1bea626d5f5e880c3338f32705fd46d/TODO#L990-L1000) to add one day.

Solutions like [SOPS](https://github.com/getsops/sops) allow secrets to be encrypted elsewhere, checked into git and then only decrypted on the deployment host. It would be nice if a similar pattern could be applied to [systemd credentials](https://systemd.io/CREDENTIALS/).

`systemd-age-creds` provides a service credential server over `AF_UNIX` socket to provide [age](https://github.com/FiloSottile/age) encrypted credentials to [systemd units](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) using `LoadCredential`.

## Installation

This project uses systemd Quadlet units to run systemd-age-creds as a container with socket activation.

### Prerequisites

- Podman 4.4+ with Quadlet support
- systemd
- An age identity file and encrypted credentials

### Files

The installation uses two systemd units:
- `quadlet/systemd-age-creds.socket` - Socket unit (installs to `/etc/systemd/system/`)
- `quadlet/systemd-age-creds.container` - Quadlet container unit (installs to `/etc/containers/systemd/`)

### 1. Build the container image (optional)

If you want to build locally instead of using the pre-built image:

```bash
podman build -t ghcr.io/abyrne55/systemd-age-creds:main -f Containerfile .
```

### 2. Set up credentials

```bash
# Create directories
sudo mkdir -p /etc/age/credentials

# Generate an age identity (or copy your existing one)
sudo age-keygen -o /etc/age/identity.txt
sudo chmod 600 /etc/age/identity.txt

# Encrypt a credential
echo "my-secret-value" | age -r $(sudo age-keygen -y /etc/age/identity.txt) \
  | sudo tee /etc/age/credentials/my-credential.age > /dev/null
```

### 3. Install the socket unit

```bash
sudo cp quadlet/systemd-age-creds.socket /etc/systemd/system/
```

### 4. Install the container unit

```bash
sudo cp quadlet/systemd-age-creds.container /etc/containers/systemd/
sudo systemctl daemon-reload
```

### 5. Enable and start the socket

```bash
sudo systemctl enable --now systemd-age-creds.socket
```

## Usage

Other systemd services can load decrypted credentials using `LoadCredential`:

```ini
[Service]
LoadCredential=my-credential:%t/systemd-age-creds.sock
ExecStart=/usr/bin/myapp
```

The decrypted credential will be available at `/run/credentials/<unit-name>/my-credential`.

### Example Service

**foo.service**

```ini
[Service]
ExecStart=/usr/bin/myservice.sh
# Instead of loading a symmetrically encrypted systemd cred from a file,
# LoadCredentialEncrypted=foobar:/etc/credstore/myfoobarcredential.txt
#
# You can reference the credential id loading from the systemd-age-creds socket.
LoadCredential=foobar:%t/systemd-age-creds.sock
```

## Custom Paths

If your identity file or credentials are in different locations, create a drop-in override:

```bash
sudo mkdir -p /etc/containers/systemd/systemd-age-creds.container.d
sudo tee /etc/containers/systemd/systemd-age-creds.container.d/paths.conf << 'EOF'
[Container]
Volume=/path/to/your/identity.txt:/identity/key.txt:ro,Z
Volume=/path/to/your/credentials:/credentials:ro,Z
EOF
sudo systemctl daemon-reload
```

## Verification

Test that credentials are being served correctly:

```bash
sudo systemd-run -p LoadCredential=my-credential:/run/systemd-age-creds.sock \
  cat /run/credentials/run-*/my-credential
```

## Troubleshooting

Check the container status:

```bash
sudo systemctl status systemd-age-creds
sudo podman logs systemd-systemd-age-creds
```

Check the socket status:

```bash
sudo systemctl status systemd-age-creds.socket
```

## See Also

[systemd Credentials](https://systemd.io/CREDENTIALS/), [systemd-creds](https://www.freedesktop.org/software/systemd/man/latest/systemd-creds.html), [age](https://github.com/FiloSottile/age), [age-plugin-tpm](https://github.com/Foxboron/age-plugin-tpm)

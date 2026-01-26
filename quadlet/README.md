# Quadlet Installation

This directory contains the systemd Quadlet units for running systemd-age-creds as a container with socket activation.

## Prerequisites

- Podman 4.4+ with Quadlet support
- systemd
- An age identity file and encrypted credentials

## Files

- `systemd-age-creds.socket` - Socket unit (installs to `/etc/systemd/system/`)
- `systemd-age-creds.container` - Quadlet container unit (installs to `/etc/containers/systemd/`)

## Installation

### 1. Build the container image (optional)

If you want to build locally instead of using the pre-built image:

```bash
podman build -t ghcr.io/abyrne55/systemd-age-creds:latest -f Containerfile .
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
sudo cp systemd-age-creds.socket /etc/systemd/system/
```

### 4. Install the container unit

```bash
sudo cp systemd-age-creds.container /etc/containers/systemd/
sudo systemctl daemon-reload
```

### 5. Enable and start the socket

```bash
sudo systemctl enable --now systemd-age-creds.socket
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

## Usage

Other systemd services can load decrypted credentials using `LoadCredential`:

```ini
[Service]
LoadCredential=my-credential:%t/systemd-age-creds.sock
ExecStart=/usr/bin/myapp
```

The decrypted credential will be available at `/run/credentials/<unit-name>/my-credential`.

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

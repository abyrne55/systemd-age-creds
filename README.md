# systemd-age-creds

Load [age](https://github.com/FiloSottile/age) encrypted credentials in [systemd units](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html).

> **Note:** This is a fork of [josh/systemd-age-creds](https://github.com/josh/systemd-age-creds), which is now archived. This version provides simple binary distribution instead of the original Nix-based deployment.

At the moment, [systemd-creds](https://www.freedesktop.org/software/systemd/man/latest/systemd-creds.html) only support symmetric encryption requiring secrets to be encrypted on the machine with the TPM itself. Though, it's on the [systemd TODO](https://github.com/systemd/systemd/blob/e8fb0643c1bea626d5f5e880c3338f32705fd46d/TODO#L990-L1000) to add one day.

Solutions like [SOPS](https://github.com/getsops/sops) allow secrets to be encrypted elsewhere, checked into git and then only decrypted on the deployment host. It would be nice if a similar pattern could be applied to [systemd credentials](https://systemd.io/CREDENTIALS/).

`systemd-age-creds` provides a service credential server over `AF_UNIX` socket to provide [age](https://github.com/FiloSottile/age) encrypted credentials to [systemd units](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) using `LoadCredential`.

## Installation

### Option 1: RPM Package (Fedora/RHEL/CentOS)

Download and install the RPM package from the [latest release](https://github.com/abyrne55/systemd-age-creds/releases/latest):

```bash
# Download the RPM
VERSION=v1.4.0  # Replace with latest version
curl -LO https://github.com/abyrne55/systemd-age-creds/releases/download/${VERSION}/systemd-age-creds-1.4.0-1.fc42.aarch64.rpm

# Verify checksum
curl -LO https://github.com/abyrne55/systemd-age-creds/releases/download/${VERSION}/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing

# Install (will automatically install age if available in repos)
sudo dnf install ./systemd-age-creds-*.rpm

# Enable and start the socket
sudo systemctl enable --now systemd-age-creds.socket
```

### Option 2: Binary Tarball

Download and install the binary from the [latest release](https://github.com/abyrne55/systemd-age-creds/releases/latest):

```bash
# Download the tarball
VERSION=v1.4.0  # Replace with latest version
curl -LO https://github.com/abyrne55/systemd-age-creds/releases/download/${VERSION}/systemd-age-creds-${VERSION}-linux-arm64.tar.gz

# Verify checksum
curl -LO https://github.com/abyrne55/systemd-age-creds/releases/download/${VERSION}/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing

# Extract and install
tar -xzf systemd-age-creds-${VERSION}-linux-arm64.tar.gz
sudo install -m 755 systemd-age-creds /usr/local/bin/systemd-age-creds
sudo cp systemd/systemd-age-creds.socket /etc/systemd/system/
sudo cp systemd/systemd-age-creds.service /etc/systemd/system/
sudo systemctl daemon-reload

# Enable and start the socket
sudo systemctl enable --now systemd-age-creds.socket
```

### Option 3: Build from Source

```bash
# Clone the repository
git clone https://github.com/abyrne55/systemd-age-creds.git
cd systemd-age-creds

# Build and install
make install

# Enable and start the socket
sudo systemctl enable --now systemd-age-creds.socket
```

### Installing age

`systemd-age-creds` requires [age](https://github.com/FiloSottile/age) to be installed. Install it using your package manager:

**Fedora/RHEL:**
```bash
sudo dnf install age
```

**Debian/Ubuntu:**
```bash
sudo apt install age
```

**Arch Linux:**
```bash
sudo pacman -S age
```

**macOS (for local development):**
```bash
brew install age
```

Or download binaries from the [age releases page](https://github.com/FiloSottile/age/releases).

### Setting up credentials

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

The default configuration looks for:
- Age identity: `/etc/age/identity.txt`
- Encrypted credentials: `/etc/age/credentials/*.age`

If your files are in different locations, create a systemd drop-in override:

```bash
sudo systemctl edit systemd-age-creds.service
```

Then add:

```ini
[Service]
Environment=AGE_IDENTITY=/path/to/your/identity.txt
Environment=AGE_DIR=/path/to/your/credentials
```

Save and reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-age-creds.socket
```

## Verification

Test that credentials are being served correctly:

```bash
sudo systemd-run -p LoadCredential=my-credential:/run/systemd-age-creds.sock \
  cat /run/credentials/run-*/my-credential
```

## Troubleshooting

Check the service status:

```bash
sudo systemctl status systemd-age-creds.service
sudo journalctl -u systemd-age-creds.service
```

Check the socket status:

```bash
sudo systemctl status systemd-age-creds.socket
```

Common issues:

1. **Permission denied errors**: Ensure `/etc/age/identity.txt` has mode 600 and is owned by root
2. **Credential not found**: Verify the `.age` file exists in `/etc/age/credentials/` (or your custom `AGE_DIR`)
3. **age binary not found**: Install age using your package manager (see "Installing age" section)

## See Also

[systemd Credentials](https://systemd.io/CREDENTIALS/), [systemd-creds](https://www.freedesktop.org/software/systemd/man/latest/systemd-creds.html), [age](https://github.com/FiloSottile/age), [age-plugin-tpm](https://github.com/Foxboron/age-plugin-tpm)

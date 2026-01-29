# Agents Guide

This project is written in Go and has no go mod dependencies. The repository assumes Go 1.24 or newer.

## Environment Setup

1. Run on X86 or ARM Linux with systemd
2. Install Go 1.24 or later.

## Testing

Run tests with:

```sh
go test ./...
```

## Formatting

Format code with:

```sh
go fmt main.go main_test.go
```

## Code Quality

Run vet and static analysis tools before committing:

```sh
go vet main.go main_test.go
```

Optionally run `golangci-lint` for additional checks:

```sh
golangci-lint run main.go main_test.go
```

## Building

Build the project with:

```sh
make build
```

Or directly with Go:

```sh
go build
```

To build with version information:

```sh
make VERSION=v1.4.0 build
```

## Local Installation

On Linux, you can install the binary and systemd units with:

```sh
make install
```

This will:
- Install the binary to `/usr/local/bin/systemd-age-creds`
- Copy systemd units to `/etc/systemd/system/`
- Reload systemd daemon

## Release Process

Releases are automated via GitHub Actions. To create a new release:

1. Update the version in `main.go`
2. Commit all changes
3. Create and push a semver tag:

```sh
git tag -a v1.4.0 -m "Binary distribution release"
git push origin v1.4.0
```

The GitHub Actions workflow will:
- Build native linux/arm64 binaries
- Create tarball with binaries and systemd units
- Build RPM package for Fedora/RHEL
- Generate SHA256 checksums
- Create a GitHub release with all artifacts

## Comments

Keep comments concise. Only add them when they clarify non-obvious logic.

# Stage 1: Build the Go binary
FROM quay.io/hummingbird/go:1-builder AS builder

WORKDIR /build

# Install age via dnf
RUN dnf install -y age && dnf clean all

# Copy source files
COPY go.mod go.sum ./
COPY main.go ./

# Build systemd-age-creds
RUN CGO_ENABLED=0 go build -o systemd-age-creds main.go

# Stage 2: Minimal runtime image
FROM quay.io/hummingbird/core-runtime:2

# Copy binaries from builder
COPY --from=builder /build/systemd-age-creds /usr/bin/systemd-age-creds
COPY --from=builder /usr/bin/age /usr/bin/age

# Environment variables
ENV AGE_BIN=/usr/bin/age
ENV AGE_IDENTITY=/identity/key.txt
ENV AGE_DIR=/credentials

ENTRYPOINT ["/usr/bin/systemd-age-creds"]

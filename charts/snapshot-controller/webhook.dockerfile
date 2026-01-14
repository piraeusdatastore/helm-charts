FROM --platform=$BUILDPLATFORM golang:1 AS builder

WORKDIR /app
ARG VERSION=master
ADD "https://github.com/kubernetes-csi/external-snapshotter.git#${VERSION}" .

ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -ldflags "-X main.version=${VERSION} -extldflags '-static'" -o snapshot-conversion-webhook ./cmd/snapshot-conversion-webhook

FROM gcr.io/distroless/static:latest
LABEL maintainers="Kubernetes Authors"
LABEL description="Snapshot Webhook"

COPY --from=builder /app/snapshot-conversion-webhook snapshot-conversion-webhook
ENTRYPOINT ["/snapshot-conversion-webhook"]

FROM eclipse-temurin:25-jre-jammy

# Create non-root user
RUN useradd -m -u 10001 hytale

# Minimal utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/hytale

COPY docker/server/entrypoint.sh /usr/local/bin/hytale-entrypoint.sh
RUN chmod +x /usr/local/bin/hytale-entrypoint.sh

USER hytale

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/hytale-entrypoint.sh"]

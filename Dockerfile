# syntax = docker/dockerfile:1
FROM ruby:3.4.4-alpine3.21 AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    tzdata \
    postgresql-dev \
    vips-dev \
    pkgconfig

# Install gems
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Final stage for app image
FROM ruby:3.4.4-alpine3.21

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache \
    tzdata \
    postgresql-client \
    vips \
    bash \
    curl

# Copy built artifacts: gems, application
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    RAILS_LOG_TO_STDOUT="true" \
    RAILS_SERVE_STATIC_FILES="true"

# Create a non-root user
RUN adduser -D rails && \
    chown -R rails:rails /app/db /app/log /app/storage /app/tmp
USER rails:rails

# Entrypoint prepares the database.
# Ensure this file exists and is executable in your repo, or remove if not needed.
# For now, we point to the standard Rails one if it exists, or just run the server.
# ENTRYPOINT ["/app/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

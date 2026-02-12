# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=4.0.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
# Replace libpq-dev with sqlite3 if using SQLite, or libmysqlclient-dev if using MySQL
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git vim libjemalloc2 libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configure jemalloc, memory settings, and enable YJIT
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true,stats_print:false" \
    RUBY_YJIT_ENABLE=1

# Set the bundle path
ENV BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git pkg-config libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile* Gemfile.lock* ./
RUN bundle install

# Copy application code
COPY . .

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

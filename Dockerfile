FROM ruby:3.3.5-alpine AS base

ENV GROUP=edm \
    USER=edm \
    DIR=/project

WORKDIR $DIR

RUN apk add -U --no-cache git \
    build-base \
    curl \
    postgresql-client \
    postgresql-dev \
    tzdata \
    yarn && apk -U upgrade

# Ruby dependencies
COPY Gemfile Gemfile.lock $DIR/
RUN gem install bundler:"$(tail -1 < Gemfile.lock | tr -d " ")"
RUN BUNDLE_FORCE_RUBY_PLATFORM=1 BUNDLE_WITHOUT="development test beta" bundle install --jobs "$(getconf _NPROCESSORS_ONLN)" --retry 3

# JS dependencies using yarn
COPY yarn.lock $DIR/
RUN yarn install --check-files

COPY . $DIR/

RUN RAILS_ENV=production SECRET_KEY_BASE=1 bundle exec rails --trace assets:precompile assets:clean

FROM ruby:3.3.5-alpine

ENV GROUP=edm \
    USER=edm \
    DIR=/project

RUN mkdir -p "$DIR" && \
    addgroup -S "$GROUP" && \
    adduser -S -s /sbin/nologin -G "$GROUP" "$USER" && \
    chown "$USER":"$GROUP" "$DIR"

RUN apk add -U --no-cache \
    postgresql-libs \
    libxml2 \
    libxslt \
    xz-libs \
    gcompat \
    tzdata \
    nodejs \
    curl \
    && apk -U upgrade

USER $USER

COPY --from=base --chown=$USER:$GROUP /usr/local/bundle /usr/local/bundle
COPY --from=base --chown=$USER:$GROUP $DIR/ $DIR/

WORKDIR $DIR

# Include instructions to start the Rails server...
EXPOSE 3000
CMD ["rails", "server", "-b",  "0.0.0.0"]

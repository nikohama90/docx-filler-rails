FROM ruby:3.3

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV RAILS_ENV=development
EXPOSE 3000

CMD ["bash", "-lc", "rm -f /app/tmp/pids/server.pid && bin/rails db:prepare && bin/rails server -b 0.0.0.0 -p 3000"]
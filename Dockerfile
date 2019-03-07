FROM ruby:2.6.1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ["shotgun", "app.rb"]
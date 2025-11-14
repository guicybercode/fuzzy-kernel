FROM elixir:1.15-alpine AS builder

RUN apk add --no-cache build-base git postgresql-client

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN mix compile
RUN mix assets.deploy
RUN mix release

FROM alpine:latest

RUN apk add --no-cache openssl libstdc++

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/microkernel ./

ENV MIX_ENV=prod
ENV PORT=4000

EXPOSE 4000

CMD ["./bin/microkernel", "start"]


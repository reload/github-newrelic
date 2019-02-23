FROM alpine:3.9

RUN apk add --no-cache \
        make jq curl
RUN mkdir /app
COPY Makefile /app/
COPY query-payload.json /app/

ENV GITHUB_TOKEN ""
ENV NEWRELIC_TOKEN ""

WORKDIR /app

ENTRYPOINT ["make"]
CMD ["send-data"]

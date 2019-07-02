FROM alpine:3.10

# Add Maintainer Info
LABEL maintainer="Lasse Nielsen <65roed@gmail.com>"

RUN apk add --update --no-cache bash curl jq

WORKDIR /

COPY ./create_hydra_clients.sh .

RUN chmod +x ./create_hydra_clients.sh

FROM alpine

# System packages
RUN apk update
RUN apk add --no-cache build-base rakudo zef mariadb-connector-c-dev postgresql-dev

# Raku packages
RUN zef install --/test DBIish
COPY . /UpRooted
RUN zef install /UpRooted
RUN rm -r /UpRooted

# User 
ARG USER=uprooted
RUN adduser --disabled-password ${USER}
USER ${USER}
WORKDIR /home/${USER}
ENV PS1='🐳 \e[36mUpRooted\e[0m: \w # '

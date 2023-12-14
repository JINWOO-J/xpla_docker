FROM golang:1.19
ARG VERSION
ENV VERSION=${VERSION}
#ENV HOME="/data"
ENV STDOUT="true"
#ENV DATA_DIR="/data"
ENV PATH=${PATH}:/src:/app

WORKDIR /xpla_src
COPY xpla /xpla_src
COPY src /app
RUN apt update && apt -y install pip && pip3 install --break-system-packages pawnlib toml python-dotenv
RUN make install

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
COPY s6 /etc/

RUN echo "source /app/environments.sh" >> /etc/bash.bashrc

EXPOSE 26657/tcp
EXPOSE 26656/tcp
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]

#FROM python:3.9.13-slim-buster
#WORKDIR /app/
#COPY --from=0 /go/bin/ /app
#CMD ["./xpla"]

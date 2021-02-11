FROM python:alpine3.13

LABEL maintainer="Team Stingar <team-stingar@duke.edu>"
LABEL name="elasticpot"
LABEL version="1.9.1"
LABEL release="1"
LABEL summary="Elasticpot HoneyPot container"
LABEL description="Honeypot emulating ElasticSearch"
LABEL authoritative-source-url="https://github.com/CommunityHoneyNetwork/communityhoneynetwork"
LABEL changelog-url="https://github.com/CommunityHoneyNetwork/communityhoneynetwork/commits/master"

# Set Docker var - used by Elasticpot init to determine logging
ENV DOCKER "yes"
ENV ELASTICPOT_VERS "v1.0.3"
ENV ELASTICPOT_USER "elasticpot"
ENV ELASTICPOT_GROUP "elasticpot"
ENV ELASTICPOT_DIR "/opt/elasticpot"
ENV ELASTICPOT_JSON "/etc/elasticpot/elasticpot.json"
ENV DEBIAN_FRONTEND "noninteractive"
# hadolint ignore=DL3008,DL3005

RUN mkdir /code
ADD requirements.txt entrypoint.sh elasticpot.cfg.template /code/

# hadolint ignore=DL3008,DL3005
RUN apk --update add --no-cache python3-dev libffi-dev build-base wget jq rust gcc musl-dev python3-dev openssl-dev cargo \
    && python3 -m pip install --upgrade pip setuptools wheel \
    && python3 -m pip install -r /code/requirements.txt

RUN adduser -S elasticsearch && \
    addgroup -g 1001 ${ELASTICPOT_GROUP} && \
    adduser -S -u 1001 -G ${ELASTICPOT_GROUP} ${ELASTICPOT_USER} && \
    chmod +x /code/entrypoint.sh

RUN cd /opt && \
    git clone --branch "${ELASTICPOT_VERS}" https://gitlab.com/bontchev/elasticpot.git && \
    chown -R ${ELASTICPOT_USER}:${ELASTICPOT_USER} elasticpot

RUN python3 -m pip install -r /opt/elasticpot/requirements.txt \
    && apk del rust build-essential cargo python3-dev \
    && rm -rf /var/cache/apk/*

VOLUME /data
RUN mkdir $(dirname ${ELASTICPOT_JSON}) \
    && chown ${ELASTICPOT_USER} $(dirname ${ELASTICPOT_JSON})

RUN rm -rf /opt/elasticpot/output_plugins/hpfeed.py
COPY output/hpfeed.py /opt/elasticpot/output_plugins/hpfeed.py

USER elasticpot
ENTRYPOINT ["/code/entrypoint.sh"]

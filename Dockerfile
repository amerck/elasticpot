FROM python:3.7

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

RUN useradd elasticsearch

# hadolint ignore=DL3008,DL3005
RUN apt-get update \
    && apt-get install --no-install-recommends -y python3-dev libffi-dev build-essential wget jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m pip install --upgrade pip setuptools wheel \
    && python3 -m pip install -r /code/requirements.txt

RUN groupadd -r -g 1001 ${ELASTICPOT_GROUP} && \
    useradd -r -u 1001 -m -g ${ELASTICPOT_GROUP} ${ELASTICPOT_USER} && \
    chmod +x /code/entrypoint.sh

RUN cd /opt && \
    git clone --branch "${ELASTICPOT_VERS}" https://gitlab.com/bontchev/elasticpot.git && \
    chown -R ${ELASTICPOT_USER}:${ELASTICPOT_USER} elasticpot

RUN python3 -m pip install -r /opt/elasticpot/requirements.txt

VOLUME /data
RUN mkdir $(dirname ${ELASTICPOT_JSON}) \
    && chown ${ELASTICPOT_USER} $(dirname ${ELASTICPOT_JSON})

RUN rm -rf /opt/elasticpot/output_plugins/hpfeed.py
COPY output/hpfeed.py /opt/elasticpot/output_plugins/hpfeed.py

USER elasticpot
ENTRYPOINT ["/code/entrypoint.sh"]

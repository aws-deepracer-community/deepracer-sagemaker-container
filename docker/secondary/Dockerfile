ARG arch
ARG version
ARG prefix
FROM ${prefix}/sagemaker-tensorflow-container:${version}-${arch}

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    jq \
    ffmpeg \
    libjpeg-dev \
    libxrender1 \
    python3-opengl \
    pkg-config \
    xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Redis.
RUN cd /tmp && \
    wget https://download.redis.io/releases/redis-6.2.7.tar.gz && \
    tar xvzf redis-6.2.7.tar.gz && \
    cd redis-6.2.7 && \
    make && \
    make install && \
    rm -rf /tmp/redis*

RUN pip install -U --no-cache-dir --upgrade-strategy only-if-needed \
    pyglet \
    gym \
    "redis>=4.4.4" \
    "rl-coach-slim==1.0.0"  \
    "protobuf<3.20" \
    awscli
RUN wget https://raw.githubusercontent.com/protocolbuffers/protobuf/main/python/google/protobuf/internal/builder.py -O /usr/local/lib/python3.8/dist-packages/google/protobuf/internal/builder.py

COPY ./files/redis.conf /etc/redis/redis.conf
COPY ./files/rl_coach.patch /opt/amazon/rl_coach.patch
RUN patch -p1 -N --directory=/usr/local/lib/python3.8/dist-packages/ < /opt/amazon/rl_coach.patch

ENV COACH_BACKEND=tensorflow

# Copy workaround script for incorrect hostname
COPY files/changehostname.c /
COPY files/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENV PYTHONPATH /opt/amazon/:$PYTHONPATH
ENV PATH /opt/ml/code/:$PATH
WORKDIR /opt/ml/code

# Tell sagemaker-containers where the launch point is for training job.
ENV NODE_TYPE SAGEMAKER_TRAINING_WORKER

ENV PYTHONUNBUFFERED 1

# Versioning
ARG IMG_VERSION
LABEL maintainer "AWS DeepRacer Community - deepracing.io"
LABEL version $IMG_VERSION

# Starts framework
ENTRYPOINT ["bash", "-m", "start.sh", "train"]

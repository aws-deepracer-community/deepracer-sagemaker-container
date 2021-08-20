ARG arch
ARG version
ARG prefix
FROM ${prefix}/sagemaker-tensorflow-container:${version}-${arch}
#FROM awsdeepracercommunity/sagemaker-tensorflow-container:4.0.2-gpu-nv

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        jq \
        ffmpeg \
        libjpeg-dev \
        libxrender1 \
        python3-opengl \
        xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Redis.
RUN cd /tmp && \
    wget http://download.redis.io/redis-stable.tar.gz && \
    tar xvzf redis-stable.tar.gz && \
    cd redis-stable && \
    make && \
    make install && \
    rm -rf /tmp/redis*

RUN pip install -U --no-cache-dir --upgrade-strategy only-if-needed \
    "PyOpenGL==3.1.0" \
    "pyglet==1.3.2" \
    "gym==0.12.5" \
    "redis>=3.3" \
    "rl-coach-slim==1.0.0"  \
    "minio==4.0.5" \
    eventlet \
    "sagemaker-containers>=2.7.1" \
    awscli

COPY ./lib/redis.conf /etc/redis/redis.conf
#COPY ./staging/markov /opt/amazon/markov
COPY ./lib/rl_coach.patch /opt/amazon/rl_coach.patch
#RUN patch -p1 -N --directory=/usr/local/lib/python3.6/dist-packages/ < /opt/amazon/rl_coach.patch
RUN patch -p1 -N --directory=/usr/local/lib/python3.8/dist-packages/ < /opt/amazon/rl_coach.patch

ENV COACH_BACKEND=tensorflow

# Copy workaround script for incorrect hostname
COPY lib/changehostname.c /
COPY lib/start.sh /usr/local/bin/start.sh
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

#RUN tf_upgrade_v2 --intree /usr/local/lib/python3.8/dist-packages/rl_coach --inplace
#RUN chown -R root:staff /usr/local/lib/python3.8/dist-packages/rl_coach/
#RUN chmod -R 755 /usr/local/lib/python3.8/dist-packages/rl_coach/

# Starts framework
ENTRYPOINT ["bash", "-m", "start.sh", "train"]
#CMD ["bin/bash"]


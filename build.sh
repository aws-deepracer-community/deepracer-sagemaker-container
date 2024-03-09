#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
    echo "Requested to stop."
    exit 1
}

set -e

PREFIX="awsdeepracercommunity"
ARCH="cpu gpu cpu-intel"

while getopts ":2fa:p:" opt; do
    case $opt in
    2)
        OPT_SECOND_STAGE_ONLY="OPT_SECOND_STAGE_ONLY"
        ;;
    p)
        PREFIX="$OPTARG"
        ;;
    a)
        ARCH="$OPTARG"
        ;;
    f)
        OPT_NOCACHE="--no-cache"
        ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    esac
done

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd $DIR
VERSION=$(cat VERSION)

echo "Preparing docker images for [$ARCH]"

TF_VER="tensorflow==2.13.1\ntensorflow-probability==0.21.0"

## First stage
if [[ -z "$OPT_SECOND_STAGE_ONLY" ]]; then

    for arch in $ARCH; do

        if [[ "$arch" == "gpu" ]]; then
            docker buildx build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f docker/primary/Dockerfile.gpu \
                --build-arg TF_VER=$TF_VER
        elif [[ "$arch" == "cpu" ]]; then
            docker buildx build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f docker/primary/Dockerfile.cpu \
                --build-arg TF_VER=$TF_VER
        elif [[ "$arch" == "cpu-intel" ]]; then
            TF_VER='intel-tensorflow==2.13.0\ntensorflow-probability==0.21.0'
            docker buildx build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f docker/primary/Dockerfile.cpu \
                --build-arg TF_VER="$TF_VER"
        fi

    done

fi
cd $DIR

## Second stage
for arch in $ARCH; do
    docker buildx build $OPT_NOCACHE -f docker/secondary/Dockerfile -t $PREFIX/deepracer-sagemaker:$VERSION-$arch . --build-arg version=$VERSION --build-arg arch=$arch --build-arg prefix=$PREFIX --build-arg IMG_VERSION=$VERSION
done

set +e

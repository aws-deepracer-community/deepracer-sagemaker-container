#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
        echo "Requested to stop."
        exit 1
}

set -e

PREFIX="local"

while getopts ":2cfognp:t:" opt; do
case $opt in
2) OPT_SECOND_STAGE_ONLY="OPT_SECOND_STAGE_ONLY"
;;
p) PREFIX="$OPTARG"
;;
t) TF_PATH="$OPTARG"
;;
c) OPT_CPU="cpu"
;;
g) OPT_GPU="gpu"
;;
n) OPT_GPUNV="gpu-nv"
;;
o) OPT_OPTCPU="cpu-avx-mkl"
;;
f) OPT_NOCACHE="--no-cache"
;;
\?) echo "Invalid option -$OPTARG" >&2
exit 1
;;
esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
VERSION=$(cat VERSION)

ARCH=$(echo "$OPT_CPU $OPT_GPU $OPT_OPTCPU $OPT_GPUNV")
echo "Preparing docker images for [$ARCH]"

## First stage
if [[ -z "$OPT_SECOND_STAGE_ONLY" ]]; then

    for arch in $ARCH; do

	if [[  "$arch" == "gpu-nv" || "$arch" == "gpu" ]]; then
            TF_PATH="https://larsll-build-artifact-share.s3.eu-north-1.amazonaws.com/tensorflow/gpu-nv/tensorflow-1.15.4%2Bnv-cp36-cp36m-linux_x86_64.whl"
	        docker build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f docker/primary/Dockerfile.gpu  \
                --build-arg TF_URL=$TF_PATH 
	elif [[  "$arch" == "cpu" ||  "$arch" == "cpu-avx-mkl" ]]; then
            TF_PATH="intel-tensorflow==1.15.2"
	        docker build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f docker/primary/Dockerfile.cpu  \
			    --build-arg TF_URL=$TF_PATH
    fi

    done

fi
cd $DIR

## Second stage
for arch in $ARCH;
do
    docker build $OPT_NOCACHE -f docker/secondary/Dockerfile -t $PREFIX/deepracer-sagemaker:$VERSION-$arch . --build-arg version=$VERSION --build-arg arch=$arch --build-arg prefix=$PREFIX --build-arg IMG_VERSION=$VERSION
done

set +e
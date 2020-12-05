#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
        echo "Requested to stop."
        exit 1
}

PREFIX="local"
TF_PATH="https://storage.googleapis.com/intel-optimized-tensorflow/intel_tensorflow-1.13.1-cp36-cp36m-manylinux1_x86_64.whl"

while getopts ":2cfogp:t:" opt; do
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
rm -rf $DIR/sagemaker-tensorflow-container/dist/*
cd $DIR
VERSION=$(cat VERSION)

ARCH=$(echo "$OPT_CPU $OPT_GPU $OPT_OPTCPU")
echo "Preparing docker images for [$ARCH]"

## Second stage
if [[ -z "$OPT_SECOND_STAGE_ONLY" ]]; then

    cd $DIR/sagemaker-tensorflow-container/
    python setup.py sdist
    cp dist/*.tar.gz docker/build_artifacts/
    git apply $DIR/lib/dockerfile-1.11.patch
    git apply $DIR/lib/dockerfile-1.13.1.patch
    git apply $DIR/lib/dockerfile-1.15.2.patch
    cd docker/build_artifacts

    for arch in $ARCH; do

	if [[  "$arch" != "cpu-avx-mkl" ]]; then
	        docker build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f ../1.15.2/py3/Dockerfile.$arch  \
			--build-arg py_version=3 --build-arg framework_support_installable='sagemaker_tensorflow_*.tar.gz' 
	else
		docker build $OPT_NOCACHE . -t $PREFIX/sagemaker-tensorflow-container:$VERSION-$arch -f ../1.13.1/Dockerfile.cpu  \
        	        --build-arg py_version=3 --build-arg framework_support_installable='sagemaker_tensorflow_*.tar.gz' \
                	--build-arg TF_URL=$TF_PATH
    	fi
    done
    rm *.tar.gz

    cd $DIR/sagemaker-tensorflow-container/
    git apply --reverse ../lib/dockerfile-1.11.patch
    git apply --reverse ../lib/dockerfile-1.13.1.patch
    git apply --reverse ../lib/dockerfile-1.15.2.patch

fi
cd $DIR

## Second stage
for arch in $ARCH;
do
    docker build $OPT_NOCACHE -t $PREFIX/deepracer-sagemaker:$VERSION-$arch . --build-arg version=$VERSION --build-arg arch=$arch --build-arg prefix=$PREFIX --build-arg IMG_VERSION=$VERSION
done

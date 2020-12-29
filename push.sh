#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
        echo "Requested to stop."
        exit 1
}

PREFIX="local"
VERSION=$(cat VERSION)

while getopts ":2cfognp:t:" opt; do
case $opt in
p) PREFIX="$OPTARG"
;;
c) OPT_CPU="cpu"
;;
g) OPT_GPU="gpu"
;;
n) OPT_GPUNV="gpu-nv"
;;
o) OPT_OPTCPU="cpu-avx-mkl"
;;
\?) echo "Invalid option -$OPTARG" >&2
exit 1
;;
esac
done

ARCH=$(echo $OPT_CPU $OPT_GPU $OPT_OPTCPU $OPT_GPUNV)
echo "Pushing docker images for [$ARCH]"

for A in $ARCH; do
  echo "Pushing $PREFIX/deepracer-sagemaker:$VERSION-$A"
  docker push $PREFIX/deepracer-sagemaker:$VERSION-$A
done

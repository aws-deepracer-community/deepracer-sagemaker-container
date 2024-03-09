#!/bin/bash
trap ctrl_c INT

function ctrl_c() {
        echo "Requested to stop."
        exit 1
}

PREFIX="local"
VERSION=$(cat VERSION)

ARCH="cpu gpu cpu-intel"

while getopts "p:a:" opt; do
case $opt in
p) PREFIX="$OPTARG"
;;
a) ARCH="$OPTARG"
;;
\?) echo "Invalid option -$OPTARG" >&2
exit 1
;;
esac
done

echo "Pushing docker images for [$ARCH]"

for A in $ARCH; do
  echo "Pushing $PREFIX/deepracer-sagemaker:$VERSION-$A"
  docker push $PREFIX/deepracer-sagemaker:$VERSION-$A
done

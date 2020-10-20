#!/bin/sh

BUILDER_NAME=buildkit_repro
LOCAL_CACHE_DIR=/tmp/.buildx-cache
IIDFILE1=/tmp/digest1
IIDFILE2=/tmp/digest2

rm -rf $LOCAL_CACHE_DIR $IIDFILE1 $IIDFILE2
docker buildx rm ${BUILDER_NAME} || true

docker buildx create --name ${BUILDER_NAME} \
  --driver docker-container \
  --driver-opt network=host \
  --driver-opt "image=moby/buildkit:v0.8-beta" \
  --buildkitd-flags "--allow-insecure-entitlement security.insecure --allow-insecure-entitlement network.host"

docker buildx inspect --bootstrap ${BUILDER_NAME}

docker buildx build --progress plain \
  --builder ${BUILDER_NAME} \
  --tag localhost:5000/name/app:latest \
  --cache-from type=local,src=${LOCAL_CACHE_DIR} \
  --cache-to type=local,dest=${LOCAL_CACHE_DIR} \
  --iidfile ${IIDFILE1} \
  --build-arg COMMIT_HASH=1c67aad5 \
  --file ./Dockerfile .

docker buildx prune --builder ${BUILDER_NAME} -a -f

docker buildx build --progress plain \
  --builder ${BUILDER_NAME} \
  --tag localhost:5000/name/app:latest \
  --cache-from type=local,src=${LOCAL_CACHE_DIR} \
  --cache-to type=local,dest=${LOCAL_CACHE_DIR} \
  --iidfile ${IIDFILE2} \
  --build-arg COMMIT_HASH=1c67aad6 \
  --file ./Dockerfile .

cat ${IIDFILE1} && echo ""
cat ${IIDFILE2} && echo ""

if [ "$(cat ${IIDFILE1})" != "$(cat ${IIDFILE2})" ]; then
  >&2 echo "ERROR: Digests should be identical"
  exit 1
fi

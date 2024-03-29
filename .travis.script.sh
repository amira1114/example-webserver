#!/bin/bash -xe

DOCKER_ORG="amirad"
DOCKER_IMAGE="example-webserver"
DOCKER_TAG="latest"

MANIFEST=${DOCKER_ORG}/${DOCKER_IMAGE}:${DOCKER_TAG}

platforms=(arm arm64 amd64)
manifest_args=(${MANIFEST})

#
# remove any previous builds
#

rm -Rf target
mkdir target

#
# generate image for each platform
#

for platform in "${platforms[@]}"; do 
    docker run -it --rm --privileged -v ${PWD}:/tmp/work --entrypoint buildctl-daemonless.sh moby/buildkit:master \
           build \
           --frontend dockerfile.v0 \
           --opt platform=linux/${platform} \
           --opt filename=./Dockerfile \
           --output type=docker,name=${MANIFEST}-${platform},dest=/tmp/work/target/${DOCKER_IMAGE}-${platform}.docker.tar \
           --local context=/tmp/work \
           --local dockerfile=/tmp/work \
           --progress plain

    manifest_args+=("${MANIFEST}-${platform}")
    
done

#
# login to docker hub
#

unset HISTFILE
echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin

#
# push all generated images
#

for platform in "${platforms[@]}"; do
    docker load --input ./target/${DOCKER_IMAGE}-${platform}.docker.tar
    docker push ${MANIFEST}-${platform}
done

#
# create manifest, update, and push
#

export DOCKER_CLI_EXPERIMENTAL=enabled
docker manifest create "${manifest_args[@]}"

for platform in "${platforms[@]}"; do
    docker manifest annotate ${MANIFEST} ${MANIFEST}-${platform} --arch ${platform}
done

docker manifest push --purge ${MANIFEST}

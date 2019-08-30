#!/usr/bin/env bash
set -e
set -x
export BUILD_DIR=$(cd "$(dirname "$0")"; pwd)
export PROJECT_DIR=$(dirname ${BUILD_DIR})

if [ -z "${GOPATH}" ]; then
 echo "missing GOPATH env, can not build"
 exit 1
fi
echo "GOPATH is "${GOPATH}


#To checkout to particular commit or tag
if [ "$VERSION" == "" ]; then
    echo "using latest code"
    VERSION="latest"
fi

release_dir=$PROJECT_DIR/release
mkdir -p $release_dir
cd $PROJECT_DIR
GO111MODULE=on go mod download
GO111MODULE=on go mod vendor
go build -a github.com/apache/servicecomb-mesher/cmd/mesher

cp -r $PROJECT_DIR/licenses $release_dir
cp -r $PROJECT_DIR/conf $release_dir
cp $PROJECT_DIR/start.sh  $release_dir
cp $PROJECT_DIR/mesher  $release_dir
if [ ! "$GIT_COMMIT" ];then
   export GIT_COMMIT=`git rev-parse HEAD`
fi

export GIT_COMMIT=`echo $GIT_COMMIT | cut -b 1-7`
BUILD_TIME=$(date +"%Y-%m-%d %H:%M:%S +%z")

cat << EOF > $release_dir/VERSION
---
version:    $VERSION
commit:     $GIT_COMMIT
built:      $BUILD_TIME
EOF


cd $release_dir

chmod +x start.sh mesher

x86_pkg_name="mesher-$VERSION-linux-amd64.tar.gz"
arm_pkg_name="mesher-$VERSION-linux-arm64.tar.gz"

#x86 release
tar zcvf $x86_pkg_name licenses conf mesher VERSION
tar zcvf mesher.tar.gz licenses conf mesher VERSION start.sh # for docker image


echo "building docker..."
cd ${release_dir}
cp ${PROJECT_DIR}/build/docker/proxy/Dockerfile ./
sudo docker build -t servicecomb/mesher-sidecar:${VERSION} .

# arm release
GOARCH=arm64 go build -a github.com/apache/servicecomb-mesher/cmd/mesher
tar zcvf $arm_pkg_name licenses conf mesher VERSION
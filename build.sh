#!/bin/bash
#
# build static sed because we need exercises in minimalism
# MIT licensed: google it or see robxu9.mit-license.org.
#
# For Linux, also builds musl for truly static linking.

sed_version="4.4"
musl_version="1.1.15"

platform=$(uname -s)

if [ -d build ]; then
  echo "= removing previous build directory"
  rm -rf build
fi

mkdir build # make build directory
pushd build

# download tarballs
echo "= downloading sed"
curl -LO http://ftp.gnu.org/gnu/sed/sed-${sed_version}.tar.xz

echo "= extracting sed"
tar xJf sed-${sed_version}.tar.xz

if [ "$platform" = "Linux" ]; then
  echo "= downloading musl"
  curl -LO http://www.musl-libc.org/releases/musl-${musl_version}.tar.gz

  echo "= extracting musl"
  tar -xf musl-${musl_version}.tar.gz

  echo "= building musl"
  working_dir=$(pwd)

  install_dir=${working_dir}/musl-install

  pushd musl-${musl_version}
  env CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS='-Wl,--gc-sections' ./configure --prefix=${install_dir}
  make install
  popd # musl-${musl-version}

  echo "= setting CC to musl-gcc"
  export CC=${working_dir}/musl-install/bin/musl-gcc
  export CFLAGS="-static"
else
  echo "= WARNING: your platform does not support static binaries."
  echo "= (This is mainly due to non-static libc availability.)"
fi

echo "= building sed"

pushd sed-${sed_version}
env FORCE_UNSAFE_CONFIGURE=1 CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS='-Wl,--gc-sections' ./configure
make
popd # sed-${sed_version}

popd # build

if [ ! -d releases ]; then
  mkdir releases
fi

echo "= striptease"
strip -s -R .comment -R .gnu.version --strip-unneeded build/sed-${sed_version}/sed/sed
echo "= compressing"
upx --ultra-brute build/sed-${sed_version}/sed/sed
echo "= extracting sed binary"
cp build/sed-${sed_version}/sed/sed releases
echo "= done"

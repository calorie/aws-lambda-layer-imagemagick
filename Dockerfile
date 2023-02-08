FROM amazonlinux:2 as libjpeg

ARG LIBJPEG_VERSION=2.1.5

RUN yum install -y curl tar gzip make cmake gcc gcc-c++ nasm

WORKDIR /build

RUN curl https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${LIBJPEG_VERSION}.tar.gz -L -o libjpeg-turbo.tar.gz && \
  tar xf libjpeg-turbo.tar.gz && \
  cd libjpeg* && \
  mkdir -p build && \
  cd build && \
  cmake .. \
    -DCMAKE_INSTALL_PREFIX=/build/cache \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR:PATH=lib \
    -DENABLE_SHARED=false \
    -DENABLE_STATIC=true && \
  make && \
  make install && \
  rm -rf /build/libjpeg*

FROM amazonlinux:2 as libpng

ARG LIBPNG_VERSION=1.6.39

RUN yum install -y curl tar xz make gcc gcc-c++ zlib zlib-devel automake autoconf pkgconfig libtool

WORKDIR /build

env PKG_CONFIG_PATH=/build/cache/lib/pkgconfig

RUN curl http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.xz -L -o libpng.tar.xz && \
  tar xf libpng.tar.xz && \
  cd libpng* && \
  ./configure \
  CPPFLAGS=-I/build/cache/include \
  LDFLAGS=-L/build/cache/lib \
  --disable-dependency-tracking \
  --disable-shared \
  --enable-static \
  --prefix=/build/cache && \
  make && \
  make install && \
  rm -rf /build/libpng*

FROM amazonlinux:2 as libwebp

ARG LIBWEBP_VERSION=v1.3.0

RUN yum install -y curl tar gzip make gcc gcc-c++ automake autoconf pkgconfig libtool

WORKDIR /build

env PKG_CONFIG_PATH=/build/cache/lib/pkgconfig

RUN curl https://github.com/webmproject/libwebp/archive/${LIBWEBP_VERSION}.tar.gz -L -o libwebp.tar.gz && \
  tar xf libwebp.tar.gz && \
  cd libwebp* && \
  ./autogen.sh && \
  ./configure \
    CPPFLAGS=-I/build/cache/include \
    LDFLAGS=-L/build/cache/lib \
    --disable-dependency-tracking \
    --disable-shared \
    --enable-static \
    --prefix=/build/cache && \
  make && \
  make install && \
  rm -rf /build/libwebp*

FROM amazonlinux:2 as openjpeg

ARG OPENJPEG_VERSION=2.5.0

RUN yum install -y curl tar gzip make cmake gcc gcc-c++ pkgconfig

WORKDIR /build

env PKG_CONFIG_PATH=/build/cache/lib/pkgconfig

RUN curl https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}/openjpeg-${OPENJPEG_VERSION}.tar.gz -L -o openjpeg.tar.gz && \
  tar xf openjpeg.tar.gz && \
  cd openjpeg* && \
  mkdir -p build && \
  cd build && \
  cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/build/cache \
    -DBUILD_SHARED_LIBS:bool=off \
    -DBUILD_CODEC:bool=off && \
  make clean && \
  make install && \
  rm -rf /build/openjpeg*

FROM amazonlinux:2

ARG IMAGEMAGICK_VERSION=7.1.0-60

RUN yum install -y curl tar gzip make gcc gcc-c++ zlib zlib-devel automake autoconf pkgconfig libtool

WORKDIR /build

env PKG_CONFIG_PATH=/build/cache/lib/pkgconfig

COPY --from=libjpeg /build/cache /build/cache
COPY --from=libpng /build/cache /build/cache
COPY --from=libwebp /build/cache /build/cache
COPY --from=openjpeg /build/cache /build/cache

RUN curl https://github.com/ImageMagick/ImageMagick/archive/${IMAGEMAGICK_VERSION}.tar.gz -L -o ImageMagick.tar.gz && \
  tar xf ImageMagick.tar.gz && \
  cd ImageMagick* && \
  ./configure \
    CPPFLAGS=-I/build/cache/include \
    LDFLAGS="-L/build/cache/lib -lstdc++" \
    --disable-dependency-tracking \
    --disable-shared \
    --enable-static \
    --prefix=/build/result \
    --enable-delegate-build \
    --disable-installed \
    --without-modules \
    --disable-docs \
    --without-magick-plus-plus \
    --without-perl \
    --without-x \
    --disable-openmp && \
  make clean && \
  make all && \
  make install && \
  rm -rf /build/ImageMagick*

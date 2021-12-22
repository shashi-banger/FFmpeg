FROM ubuntu:20.04 as builder

ENV THREADS 4
ENV TARGET /root/sw/
ENV CMPL /root/compile/

RUN mkdir -p ${TARGET} &&\
    mkdir -p ${CMPL} &&\
    apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y build-essential git cmake zlib1g-dev autoconf wget automake nasm libtool ninja-build meson pkg-config librtmp-dev libunistring-dev


RUN echo "Building libng: Requirement for freetype" &&\
    cd ${CMPL} && \
    git clone https://github.com/glennrp/libpng.git &&\
    cd libpng &&\
    autoreconf -fiv && \
    ./configure --prefix=${TARGET} --disable-dependency-tracking --disable-silent-rules --enable-static --disable-shared && \
    make -j "$THREADS" && make install && rm -rf ${CMPL}/*
 
# Freetype install
RUN LastVersion=$(wget --no-check-certificate 'https://download.savannah.gnu.org/releases/freetype/' -O- -q | grep -Eo 'freetype-[0-9\.]+\.10+\.[0-9\.]+\.tar.gz' | tail -1) &&\
    cd ${CMPL} &&\  
    wget --no-check-certificate 'https://download.savannah.gnu.org/releases/freetype/'"$LastVersion" &&\
    tar xzpf freetype-* &&\
    cd freetype-*/ &&\
    #pip3 install docwriter
    ./configure --prefix=${TARGET} --disable-shared --enable-static &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

# Open SSL installation required by SRT
RUN LastVersion=$(wget --no-check-certificate 'https://www.openssl.org/source/' -O- -q | grep -Eo 'openssl-[0-9\.]+\.[0-9\.]+\.[0-9\.]+[A-Za-z].tar.gz' | tail -1) &&\
    cd ${CMPL} &&\
    wget --no-check-certificate https://www.openssl.org/source/"$LastVersion" &&\
    tar -zxvf openssl* &&\
    cd openssl-*/ &&\
    ./config --prefix=${TARGET} &&\
    make -j "$THREADS" depend && make install_sw &&\
    rm -fr ${CMPL}/*

RUN  cd ${CMPL}  &&\ 
    git clone --depth 1 https://github.com/Haivision/srt.git &&\
    cd srt/ &&\
    mkdir build && cd build &&\
    cmake -G "Ninja" .. -DCMAKE_INSTALL_PREFIX:PATH=${TARGET} -DENABLE_C_DEPS=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON &&\
    ninja && ninja install &&\
    rm -fr ${CMPL}/*

# lame

RUN cd ${CMPL} &&\
    git clone https://github.com/rbrito/lame.git &&\
    cd lam*/ &&\
    ./configure --prefix=${TARGET} --disable-shared --enable-static &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

#_ TwoLame - optimised MPEG Audio Layer 2
RUN LastVersion=$(wget --no-check-certificate 'http://www.twolame.org' -O- -q | grep -Eo 'twolame-[0-9\.]+\.tar.gz' | tail -1) &&\
    cd ${CMPL} &&\
    wget --no-check-certificate 'http://downloads.sourceforge.net/twolame/'"$LastVersion" &&\
    tar -zxvf twolame-* &&\
    cd twolame-*/ &&\
    ./configure --prefix=${TARGET} --enable-static --enable-shared=no &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

RUN cd ${CMPL} &&\
    wget --no-check-certificate "https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-2.0.1.tar.gz" &&\
    tar -zxvf fdk-aac-* &&\
    cd fdk*/ &&\
    ./configure --disable-dependency-tracking --prefix=${TARGET} --enable-static --enable-shared=no &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

# WebM
RUN cd ${CMPL} &&\
    git clone https://chromium.googlesource.com/webm/libwebp &&\
    cd libweb*/ &&\
    ./autogen.sh &&\
    ./configure --prefix=${TARGET} --disable-dependency-tracking --disable-gif --disable-gl --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

#_ openjpeg
RUN cd ${CMPL} &&\
    git clone https://github.com/uclouvain/openjpeg.git &&\
    cd openjpeg &&\
    mkdir build && cd build &&\
    cmake -G "Ninja" .. -DCMAKE_INSTALL_PREFIX:PATH=${TARGET} -DLIBTYPE=STATIC &&\
    ninja && ninja install &&\
    rm -fr ${CMPL}/*

# av1

RUN cd ${CMPL} &&\
    git clone https://aomedia.googlesource.com/aom &&\
    cd aom &&\
    mkdir aom_build && cd aom_build &&\
    cmake -G "Ninja" ${CMPL}/aom -DCMAKE_INSTALL_PREFIX:PATH=${TARGET} -DLIBTYPE=STATIC &&\
    ninja && ninja install &&\
    rm -fr ${CMPL}/*

# david
RUN cd ${CMPL} &&\
    git clone https://code.videolan.org/videolan/dav1d.git &&\
    cd dav1*/ &&\
    meson --prefix=${TARGET} build --buildtype release --default-library static &&\
    ninja install -C build &&\
    rm -fr ${CMPL}/*

# xvid
RUN LastVersion=$(wget --no-check-certificate https://downloads.xvid.com/downloads/ -O- -q | grep -Eo 'xvidcore-[0-9\.]+\.tar.gz' | tail -1) &&\
    cd ${CMPL}  &&\
    wget --no-check-certificate https://downloads.xvid.com/downloads/"$LastVersion" &&\
    tar -zxvf xvidcore* &&\
    cd xvidcore/build/generic/ &&\
    ./bootstrap.sh &&\
    ./configure --prefix=${TARGET} --disable-assembly --enable-macosx_module &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

#_ x264 8-10bit git - Require nasm
RUN cd ${CMPL} &&\
    git clone https://code.videolan.org/videolan/x264.git &&\
    cd x264/ &&\
    ./configure --prefix=${TARGET} --enable-static --bit-depth=all --chroma-format=all --enable-mp4-output &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

#_ x265 8-10-12bit
RUN cd ${CMPL} &&\
    git clone https://bitbucket.org/multicoreware/x265_git.git &&\
    cd x265_git/build/linux &&\
    cmake -G "Unix Makefiles" ../../source -DCMAKE_INSTALL_PREFIX:PATH=${TARGET} &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/*

# librtmp
RUN cp -vr /usr/include/librtmp/* ${TARGET}/include/ &&\
    cp -v /usr/lib/x86_64-linux-gnu/pkgconfig/librtmp.pc ${TARGET}/lib/pkgconfig &&\
    cp -v /usr/lib/x86_64-linux-gnu/librtmp* ${TARGET}/lib

RUN rm ${TARGET}/lib/*.so &&\
    rm ${TARGET}/lib/*.so.*

RUN export LDFLAGS="-L${TARGET}/lib" &&\
    export CPPFLAGS="-I${TARGET}/include -DPTW32_STATIC_LIB " &&\
    export CFLAGS="-I${TARGET}/include -DPTW32_STATIC_LIB"  &&\
    export PKG_CONFIG_PATH=${TARGET}/lib/pkgconfig/ &&\
    cd ${CMPL} &&\
    git clone git://git.ffmpeg.org/ffmpeg.git &&\
    cd ffmpe*/ &&\
    ./configure --disable-shared --enable-static --extra-version=sb-"$(date +"%Y-%m-%d")" --extra-cflags="-fno-stack-check" --arch=x86_64  \
        --extra-libs="-lpthread -lm -lz" --enable-postproc  \
        --pkg_config='pkg-config --static' --enable-nonfree --enable-gpl --prefix=${TARGET} \
        --disable-ffplay --disable-debug --disable-doc --enable-avfilter --enable-filters \
        --enable-libmp3lame --enable-libfdk-aac --enable-encoder=aac \
        --enable-muxer=mp4 --enable-libxvid --enable-libx264 --enable-libx265 \
        --enable-libfreetype --enable-libopenjpeg \
         --enable-zlib  --enable-libwebp  --enable-libsrt \
        --enable-openssl --enable-librtmp &&\
    make -j "$THREADS" && make install &&\
    rm -fr ${CMPL}/* 

FROM ubuntu:20.04

COPY --from=builder /root/sw/bin/ffmpeg /usr/local/bin
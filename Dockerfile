FROM amazonlinux:latest

# https://github.com/dmlc/mxnet/blob/master/setup-utils/install-mxnet-amz-linux.sh

RUN yum groupinstall -y "Development Tools"
RUN yum install -y \
    cmake \
    python27 \
    python27-setuptools \
    python27-tools \
    python-pip \
    graphviz \
    python27-numpy \
    python27-scipy \
    python27-nose \
    python27-matplotlib

# lambda dir
RUN mkdir -p /var/task/lib
RUN cp -p /usr/lib64/libgfortran.so.3 /var/task/lib
RUN cp -p /usr/lib64/libquadmath.so.0 /var/task/lib
RUN cp -p /usr/lib64/libstdc++.so.6 /var/task/lib


ENV LD_LIBRARY_PATH /var/task/lib:${LD_LIBRARY_PATH}
ENV PKG_CONFIG_PATH /var/task/lib/pkgconfig:${PKG_CONFIG_PATH}

# OpenBLAS
RUN git clone --depth 1 https://github.com/xianyi/OpenBLAS ~/OpenBLAS &&\
    cd ~/OpenBLAS &&\
    make FC=gfortran -j $(($(nproc) + 1)) &&\
    make PREFIX=/var/task install

# OpenCV
RUN git clone --depth 1 https://github.com/opencv/opencv ~/opencv &&\
    cd ~/opencv &&\
    mkdir -p build &&\
    cd build &&\
    cmake -D BUILD_opencv_gpu=OFF -D WITH_EIGEN=ON -D WITH_TBB=ON -D WITH_CUDA=OFF -D WITH_1394=OFF -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/var/task .. &&\
    make install
# make PREFIX=/var/task/lib/cv2 install

# MXNet
RUN git clone --depth 1 https://github.com/dmlc/mxnet.git ~/mxnet --recursive &&\
cd ~/mxnet &&\
cp make/config.mk . &&\
sed -i 's/USE_CUDA = 0/USE_CUDA = 0/g' config.mk && \
sed -i 's/USE_CUDNN = 0/USE_CUDNN = 0/g' config.mk && \
sed -i 's/USE_BLAS = atlas/USE_BLAS = openblas/g' config.mk && \
sed -i 's/EXTRA_OPERATORS =$/EXTRA_OPERATORS = example\/ssd\/operator/g' config.mk && \
echo "ADD_CFLAGS += -I/var/task/include" >>config.mk &&\
echo "ADD_LDFLAGS += -lopencv_core -lopencv_imgproc -lopencv_imgcodecs" >>config.mk &&\
make -j$(nproc)

CMD du -hs /var/task/

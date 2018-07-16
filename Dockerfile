FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

ARG CAFFE_VERSION=master

# Install software-properties-common before installing multiverse repository
RUN apt-get update && apt-get install -y \
		software-properties-common \
		python-software-properties
# Enable multiverse
RUN add-apt-repository multiverse
# Install some dependencies
RUN apt-get update && apt-get install -y \
		bc \
		build-essential \
		cmake \
		curl \
		g++ \
		gfortran \
		git \
		libffi-dev \
		libfreetype6-dev \
		libhdf5-dev \
		libjpeg-dev \
		liblcms2-dev \
		libopenblas-dev \
		liblapack-dev \
		# libopenjpeg2 \
		libpng12-dev \
		libssl-dev \
		libtiff5-dev \
		libwebp-dev \
		libzmq3-dev \
		nano \
		pkg-config \
		python-dev \
		# software-properties-common \
		unzip \
		vim \
		wget \
		zlib1g-dev \
		qt5-default \
		libvtk6-dev \
		zlib1g-dev \
		libjpeg-dev \
		libwebp-dev \
		libpng-dev \
		libtiff5-dev \
		libjasper-dev \
		libopenexr-dev \
		libgdal-dev \
		libdc1394-22-dev \
		libavcodec-dev \
		libavformat-dev \
		libswscale-dev \
		libtheora-dev \
		libvorbis-dev \
		libxvidcore-dev \
		libx264-dev \
		yasm \
		libopencore-amrnb-dev \
		libopencore-amrwb-dev \
		libv4l-dev \
		libxine2-dev \
		libtbb-dev \
		libeigen3-dev \
		python-dev \
		python-tk \
		python-numpy \
		python3-dev \
		python3-tk \
		python3-numpy \
		ant \
		default-jdk \
		doxygen \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/* && \
# Link BLAS library to use OpenBLAS using the alternatives mechanism (https://www.scipy.org/scipylib/building/linux.html#debian-ubuntu)
	update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3

# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
	python get-pip.py && \
	rm get-pip.py

# Add SNI support to Python
RUN pip --no-cache-dir install \
		pyopenssl \
		ndg-httpsclient \
		pyasn1

# Install useful Python packages using apt-get to avoid version incompatibilities with Tensorflow binary
# especially numpy, scipy, skimage and sklearn (see https://github.com/tensorflow/tensorflow/issues/2034)
RUN apt-get update && apt-get install -y \
		python-numpy \
		python-scipy \
		python-nose \
		python-h5py \
		python-skimage \
		python-matplotlib \
		python-pandas \
		python-sklearn \
		python-sympy \
		python3-numpy \
		python3-scipy \
		python3-nose \
		python3-h5py \
		python3-skimage \
		python3-matplotlib \
		python3-pandas \
		python3-sklearn \
		python3-sympy \
		python3-pip \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# Install other useful Python packages using pip
# RUN pip --no-cache-dir install --upgrade ipython && \
# 	pip --no-cache-dir install \
# 		Cython \
# 		ipykernel \
# 		jupyter \
# 		path.py \
# 		Pillow \
# 		pygments \
# 		six \
# 		sphinx \
# 		wheel \
# 		zmq \
# 		&& \
# python -m ipykernel.kernelspec

# Install dependencies for Caffe
RUN apt-get update && apt-get install -y \
		libboost-all-dev \
		libgflags-dev \
		libgoogle-glog-dev \
		libhdf5-serial-dev \
		libleveldb-dev \
		liblmdb-dev \
		libopencv-dev \
		libprotobuf-dev \
		libsnappy-dev \
		protobuf-compiler \
		libvlccore-dev \
		libvlccore8 \
		&& \
	apt-get clean && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

# Install Caffe
RUN git clone -b ${CAFFE_VERSION} --depth 1 https://github.com/BVLC/caffe.git /root/caffe && \
	cd /root/caffe && \
	mkdir build && cd build && \
	cmake -DUSE_CUDNN=1 -DBLAS=Open .. && \
	make -j"$(nproc)" all && \
	make install

# Set up Caffe environment variables
ENV CAFFE_ROOT=/root/caffe
ENV PYCAFFE_ROOT=$CAFFE_ROOT/python
ENV PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH \
	PATH=$CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH

RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# Install OpenCV
# RUN git clone --depth 1 https://github.com/opencv/opencv.git /root/opencv && \
COPY opencv-2.4.zip 2.4.13.4.zip
# RUN wget https://github.com/opencv/opencv/archive/2.4.13.4.zip && \ 
RUN unzip 2.4.13.4.zip && \
	rm 2.4.13.4.zip && \
	mv opencv-2.4.13.4 /root/opencv && \
	cd /root/opencv && \
	mkdir build && \
	cd build && \
	cmake -DWITH_QT=ON -DWITH_OPENGL=ON -DFORCE_VTK=ON -DWITH_TBB=ON -DWITH_GDAL=ON -DWITH_XINE=ON -DBUILD_EXAMPLES=ON cmake -DWITH_QT=ON -DWITH_OPENGL=ON -DFORCE_VTK=ON -DWITH_TBB=ON -DWITH_GDAL=ON -DWITH_XINE=ON -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs -DBUILD_EXAMPLES=ON .. .. && \
	make -j"$(nproc)"  && \
	make install && \
	ldconfig && \
	echo 'ln /dev/null /dev/raw1394' >> ~/.bashrc

# Load mysql connectors
COPY mysql-connector-cpp.tar.gz mysql-connector-cpp.tar.gz
RUN tar -vxzf mysql-connector-cpp.tar.gz && \
	rm mysql-connector-cpp.tar.gz && \
	mv mysql-connector /root/mysql-connector && \
	chown -R root:root /root/mysql-connector

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/mysql-connector/lib


#ENV DOCKER_USER=subigya
#ENV UID=1001
#ENV GID=1001

# RUN chown ${uid}:${gid} -R /root

#RUN groupadd --gid ${GID} ${DOCKER_USER}
#RUN export uid=${UID} gid=${GID} && \
#    mkdir -p /home/${DOCKER_USER} && \
#    echo "${DOCKER_USER}:x:${uid}:${gid}:Subigya,,,:/home/${DOCKER_USER}:/bin/bash" >> /etc/passwd && \
#    echo "${DOCKER_USER}:x:${uid}:" >> /etc/group

# RUN echo "${DOCKER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DOCKER_USER} && \
#     chmod 0440 /etc/sudoers.d/${DOCKER_USER}
# RUN chown ${uid}:${gid} -R /home/${DOCKER_USER}

# RUN usermod -aG 1001 root

# USER ${DOCKER_USER}
WORKDIR /workspace

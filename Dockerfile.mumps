# How to build and publish image on Docker Hub

# docker buildx build --platform linux/amd64,linux/arm64 --tag \
#   iset:latest --progress=plain --file Dockerfile.mumps   .

# docker tag iset:latest gfem1st/iset:latest

# docker push gfem1st/iset:latest

# =========================
# STAGE 1: MUMPS BUILDER
# =========================
FROM debian:trixie-slim AS builder-mumps

ARG MUMPS_REPO=https://github.com/giavancini/mumps.git
ARG MUMPS_COMMIT=771cb980d5ae178fb93840f992bf8c9787b7cabf

ENV DEBIAN_FRONTEND=noninteractive

# ---- Build dependencies ----
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        git \
        gfortran \
        ninja-build \
        libopenblas-openmp-dev \
        liblapack-dev \
        libmetis-dev && \
    rm -rf /var/lib/apt/lists/*

# ---- Build MUMPS with OpenBLAS ----
RUN mkdir -p /opt/mumps && \
    git clone --depth=1 "${MUMPS_REPO}" /tmp/mumps-src && \
    git -C /tmp/mumps-src checkout --detach "${MUMPS_COMMIT}" && \
    cmake -S /tmp/mumps-src -B /tmp/mumps-src/build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DMUMPS_ENABLE_RPATH=on \
        -DBUILD_SINGLE=off \
        -DBUILD_DOUBLE=on \
        -DBUILD_COMPLEX=off \
        -DBUILD_COMPLEX16=off \
        -DMUMPS_parallel=false \
        -DMUMPS_openmp=on \
        -DBUILD_SHARED_LIBS=on \
        -DMUMPS_intsize64=on \
        -DMUMPS_metis=on \
        -DMUMPS_find_SCALAPACK=false \
        -DMUMPS_scalapack=false \
        -DLAPACK_VENDOR=OpenBLAS \
        -DCMAKE_INSTALL_PREFIX=/opt/mumps && \
    cmake --build /tmp/mumps-src/build --parallel && \
    cmake --install /tmp/mumps-src/build && \
    rm -rf /tmp/mumps-src

# Strip unneeded symbols from MUMPS shared libraries to reduce image size
RUN strip --strip-unneeded /opt/mumps/lib/*.so*

# =========================
# STAGE 2: ISET BUILDER
# =========================
FROM debian:trixie-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gfortran \
        cmake \
        ninja-build \
        git \
        tcl-dev \
        tcl \
        libopenblas-openmp-dev \
        liblapack-dev \
        libmetis-dev \
        libboost-dev \
        libboost-thread-dev \
        libgmp-dev \
        libmpfr-dev \
        libvtk9-dev \
        wget \
        unzip && \
    rm -rf /var/lib/apt/lists/*

# ---- Import MUMPS artifacts ----
COPY --from=builder-mumps /opt/mumps /opt/mumps

# ---- Download and extract CGAL ----
ARG CGAL_VERSION=5.6.2
ARG CGAL_URL=https://github.com/CGAL/cgal/releases/download/v${CGAL_VERSION}/CGAL-${CGAL_VERSION}.zip

RUN wget -q "${CGAL_URL}" -O /tmp/cgal.zip && \
    unzip -q /tmp/cgal.zip -d /opt && \
    mv /opt/CGAL-${CGAL_VERSION} /opt/cgal && \
    rm /tmp/cgal.zip

ENV CGAL_DIR=/opt/cgal

WORKDIR /app

# IMPORTANT: ISET source must be in ISET/ folder in the repository
COPY ISET/ /app

# ---- Link SciEng into SetSolver (required by CMake) ----
RUN ln -sfn /app/SciEng /app/SetSolver/SciEng

# ---- Build ISET with MUMPS and CGAL ----
RUN mkdir -p build && \
    cd build && \
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-O3" \
      -DISET_OPTIMIZATION_LEVEL=optimize \
      -DISET_OPTM_FLAGS="-fopenmp" \
      -DISET_USE_MUMPS=ON \
      -DISET_USE_CHOLMOD=OFF \
      -DISET_USE_PARDISO_MKL=OFF \
      -DISET_USE_MKL_BLAS=OFF \
      -DISET_USE_METIS=OFF \
      -DISET_USE_CGAL=ON \
      -DCGAL_DIR=${CGAL_DIR} \
      -DISET_MUMPS_ROOT=/opt/mumps \
      -S /app/SetSolver \
      -B /app/build && \
    cmake --build /app/build --parallel

# Strip unneeded symbols from ISET shared libraries to reduce image size
RUN strip --strip-unneeded /app/build/lib/*.so*

# =========================
# STAGE 3: RUNTIME
# =========================
FROM debian:trixie-slim

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    libgfortran5 \
    libgomp1 \
    tcl \
    libopenblas0-openmp \
    libmetis5 \
    libboost-thread1.83.0 \
    libgmp10 \
    libmpfr6 \
    # libvtk9.3 \ # vtk adds ~600 MB to the image size, so we copy only the required shared libraries instead of installing the whole package
    # The following libraries are required by VTK shared libraries
    libdouble-conversion3 \
    libexpat1 \
    libtbb12 \
    libxxhash0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- MUMPS libraries ----
# Copy the shared libraries only to reduce the size of the final image.
COPY --from=builder-mumps /opt/mumps/lib/*.so* /opt/mumps/lib/

# ---- ISET libraries (abaqus user subs) ----
COPY --from=builder /app/build/lib/*.so* /usr/local/lib/

# ---- VTK libraries ----
# using /usr/lib/*-linux-gnu since these libraries are at /usr/lib/aarch64-linux-gnu/
# and at /usr/lib/x86_64-linux-gnu/ in an arm64-linux and in an amd64-linux, respectively.
#
COPY --from=builder /usr/lib/*-linux-gnu/libvtkIOXML-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonDataModel-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonCore-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtksys-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkIOXMLParser-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkIOCore-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonExecutionModel-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonSystem-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonMisc-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonTransforms-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkpugixml-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkCommonMath-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkloguru-9.3.so.1 /usr/local/lib/
COPY --from=builder /usr/lib/*-linux-gnu/libvtkkissfft-9.3.so.1 /usr/local/lib/


# Register shared libraries
RUN echo "/opt/mumps/lib" > /etc/ld.so.conf.d/mumps.conf && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/iset.conf && \
    ldconfig

# ---- Executable ----
COPY --from=builder /app/build/projects/tclmain/tcliset .

# ---- Auxiliary files ----
COPY --from=builder /app/build/projects/tclmain/*.tcl .
COPY --from=builder /app/build/projects/tclmain/*.grf .
COPY --from=builder /app/build/projects/tclmain/*.crf .

CMD ["./tcliset"]

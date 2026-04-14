# docker build --progress=plain -t iset:latest .
# docker tag iset:latest gfem1st/iset:latest
# docker push gfem1st/iset:latest

# =========================
# STAGE 1: MUMPS BUILDER
# =========================
FROM debian:trixie-slim AS builder-mumps

ARG MUMPS_REPO=https://github.com/giavancini/mumps.git

ENV DEBIAN_FRONTEND=noninteractive

# ---- Build dependencies ----
RUN apt-get update -qq && apt-get install -qq -y \
        build-essential cmake git gfortran \
        libopenblas-dev liblapack-dev libmetis-dev \
        && rm -rf /var/lib/apt/lists/*

# ---- Build MUMPS with OpenBLAS ----
RUN mkdir -p /opt/mumps && \
    git clone --depth=1 "${MUMPS_REPO}" /tmp/mumps-src && \
    cmake -S /tmp/mumps-src -B /tmp/mumps-src/build \
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
        -DCMAKE_INSTALL_PREFIX=/tmp/mumps-src/build/install && \
    cmake --build /tmp/mumps-src/build && \
    cmake --install /tmp/mumps-src/build && \
    cp -r /tmp/mumps-src/build/install/. /opt/mumps/ && \
    rm -rf /tmp/mumps-src

# =========================
# STAGE 2: ISET BUILDER
# =========================
FROM debian:trixie-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    ninja-build \
    git \
    tcl-dev \
    tcl \
    libopenblas-dev \
    liblapack-dev \
    libmetis-dev \
    libboost-dev \
    libboost-thread-dev \
    libgmp-dev \
    libmpfr-dev \
    libvtk9-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# ---- Import MUMPS artifacts ----
COPY --from=builder-mumps /opt/mumps /opt/mumps

# ---- Download and extract CGAL ----
ARG CGAL_VERSION=5.6.2
ARG CGAL_URL=https://github.com/CGAL/cgal/releases/download/v${CGAL_VERSION}/CGAL-${CGAL_VERSION}.zip

RUN wget -q ${CGAL_URL} -O /tmp/cgal.zip && \
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
RUN mkdir -p build && cd build && \
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DISET_OPTIMIZATION_LEVEL=optimize \
      -DISET_USE_MUMPS=ON \
      -DISET_USE_CHOLMOD=OFF \
      -DISET_USE_PARDISO_MKL=OFF \
      -DISET_USE_MKL_BLAS=OFF \
      -DISET_USE_METIS=OFF \
      -DISET_USE_CGAL=ON \
      -DCGAL_DIR=${CGAL_DIR} \
      -DISET_MUMPS_ROOT=/opt/mumps \
      -DMETIS_MUMPS_INCLUDE=/opt/mumps/include \
      -DMETIS_MUMPS_LIB=/opt/mumps/lib/libmetis.so  \    
      -S /app/SetSolver \
      -B /app/build && \
    cmake --build /app/build -j$(nproc)

# =========================
# STAGE 3: RUNTIME
# =========================
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libgfortran5 \
    libgomp1 \
    tcl \
    libopenblas0 \
    liblapack3 \
    libmetis5 \
    libboost-thread1.83.0 \
    libgmp10 \
    libmpfr6 \
    libvtk9.3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- MUMPS libraries ----
COPY --from=builder-mumps /opt/mumps /opt/mumps

# ---- CGAL headers (header-only library) ----
COPY --from=builder /opt/cgal /opt/cgal

# ---- ISET libraries (abaqus user subs) ----
COPY --from=builder /app/build/lib/*.so* /usr/local/lib/

# Register shared libraries
RUN echo "/opt/mumps/lib" > /etc/ld.so.conf.d/mumps.conf && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/iset.conf && \
    ldconfig

ENV CGAL_DIR=/opt/cgal

# ---- Executable ----
COPY --from=builder /app/build/projects/tclmain/tcliset .

# ---- Auxiliary files ----
COPY --from=builder /app/build/projects/tclmain/*.tcl .
COPY --from=builder /app/build/projects/tclmain/*.grf .
COPY --from=builder /app/build/projects/tclmain/*.crf .

CMD ["./tcliset"]

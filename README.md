# ISET Docker Image

This repository provides a Docker-based build environment for the **ISET** project, allowing you to generate a runnable container **without exposing the source code**.

---

## 📦 Overview

- The ISET source code is **NOT included** in this repository
- You must provide the source code locally for building
- The Docker image will:
  - compile MUMPS from source (with OpenBLAS)
  - download and extract CGAL 5.6.2 library
  - build ISET with MUMPS solver and CGAL support
  - package the executable
  - generate a minimal runtime environment
  - use **MUMPS** as the default solver (100% open source)

---

## 📁 Requirements

Before building the image, you must have:

- Docker installed
- Access to the **ISET source code**

---

## 🚀 How to Build

### Prerequisites

You **must** have the ISET source code inside the `ISET/` folder in this repository:

```
iset-docker/
├── ISET/              ← Place ISET source here
│   ├── SetSolver/
│   └── SciEng/
├── Dockerfile
└── README.md
```

The `ISET/` folder is gitignored, so the proprietary source code won't be committed.

### Build Locally

```bash
cd iset-docker
docker build --progress=plain -t iset:latest .
```

That's it! The Dockerfile will automatically use the `ISET/` folder.

---

## 📤 Publishing to GitHub Container Registry (GHCR)

After building the image locally, you can publish it to GHCR for distribution:

### 1. Authenticate with GHCR

```bash
# Create a Personal Access Token (PAT) at: https://github.com/settings/tokens
# Required scopes: write:packages, read:packages, delete:packages

echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### 2. Tag the Image

```bash
docker tag iset:latest ghcr.io/YOUR_GITHUB_USERNAME/iset-docker:latest
```

You can also add version tags:

```bash
docker tag iset:latest ghcr.io/YOUR_GITHUB_USERNAME/iset-docker:v1.0.0
```

### 3. Push to GHCR

```bash
docker push ghcr.io/YOUR_GITHUB_USERNAME/iset-docker:latest
docker push ghcr.io/YOUR_GITHUB_USERNAME/iset-docker:v1.0.0
```

### 4. Make the Package Public

1. Go to: `https://github.com/YOUR_GITHUB_USERNAME?tab=packages`
2. Click on your `iset-docker` package
3. Click "Package settings" (right side)
4. Scroll down to "Danger Zone"
5. Click "Change visibility" → Select "Public"

### 5. Students Can Now Pull

```bash
docker pull ghcr.io/YOUR_GITHUB_USERNAME/iset-docker:latest
```

**Note:** Update [STUDENT_GUIDE.md](./STUDENT_GUIDE.md) with your actual GHCR image path.

---
## 📤 Publishing to Docker Hub

After building the image locally, you can publish it to Docker Hub for distribution:

### 1. Tag the image with your username at Docker Hub

```bash
docker tag iset:latest gfem1st/iset:latest
```

### 2. Push image to Docker Hub

```bash
docker push gfem1st/iset:latest
```
---

## 🧠 How It Works

- The `ISET/` folder (containing `SetSolver/` and `SciEng/`) is copied into the build
- **Stage 1**: Compiles MUMPS solver from source with OpenBLAS
- **Stage 2**: Downloads CGAL 5.6.2 and builds ISET with MUMPS + CGAL + VTK support
- **Stage 3**: Creates minimal runtime with only:
    - the compiled executable (`tcliset`)
    - required runtime libraries (MUMPS, OpenBLAS, LAPACK, CGAL, VTK, Boost, GMP, MPFR)
    - TCL runtime

---

## ▶️ Running the Container

### For Students (using published image)

See **[STUDENT_GUIDE.md](./STUDENT_GUIDE.md)** for a simple guide on how to use the published image.

### Local Test

After building locally:

```bash
docker run -it iset:latest
```

With your own files:

```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace iset:latest /app/tcliset your_file.tcl
```

---

## ⚠️ Important Notes

### 1. Source Code is Required for Building

This repository does NOT include ISET source code in git.

**You must place the ISET source in the `ISET/` folder:**

```bash
cd iset-docker
# Copy or symlink your ISET source into ISET/
cp -r /path/to/your/ISET ./ISET
# Or create a symlink
ln -s /path/to/your/ISET ./ISET
```

Then build:
```bash
docker build -t iset:latest .
```

### 2. No Source Code in Final Image

The final Docker image:
- does NOT include the ISET source
- only includes compiled artifacts
- is safe to distribute publicly

### 3. Solver Configuration

The default build uses:
- **MUMPS** (compiled from source)
- **OpenBLAS** for BLAS/LAPACK operations
- **CGAL 5.6.2** (Computational Geometry Algorithms Library)
- 100% open source stack

### 4. Image Size

The image is optimized to include only:
- MUMPS runtime libraries (~50 MB)
- OpenBLAS (~10 MB)
- CGAL headers and dependencies (~100 MB)
- VTK libraries (~150 MB)
- Boost, GMP, MPFR libraries
- TCL runtime
- ISET executable

Expected size: ~500-700 MB (much smaller than with Intel MKL)

---

## 🛠️ Troubleshooting

### Build fails
- Check if the `ISET/` folder exists in the repository
- Ensure required directories exist inside `ISET/`:
    - `ISET/SetSolver/`
    - `ISET/SciEng/`

### Runtime errors (missing libraries)

Run inside the container:

```bash
ldd /app/tcliset
```

This will show if any shared libraries are missing.

---

## 📌 Future Improvements

- Support for multiple solvers via build arguments (CHOLMOD, PARDISO)
- Multi-architecture builds (arm64 support)
- Smaller base image (alpine-based)

---

## 👨‍💻 Maintainer

LabMeC / ISET Dockerization effort

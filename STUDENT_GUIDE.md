# 🎓 Student Quick Guide - ISET Docker

This guide teaches you how to use the public ISET image from GitHub Container Registry.

---

## 📋 Prerequisites

Only **Docker** installed: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

---

## 🚀 How to Use

### 1️⃣ Pull the Image

```bash
docker pull ghcr.io/USERNAME/iset-docker:latest
```

> ⚠️ **Note**: Your instructor will provide the correct image path.

---

### 2️⃣ Create Your Working Directory

```bash
mkdir my-iset-project
cd my-iset-project
```

---

### 3️⃣ Run the Container

**Option A - Interactive Mode (Terminal):**
```bash
docker run -it --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /bin/bash
```

Inside the container, run:
```bash
/app/tcliset your_file.tcl
```

**Option B - Direct Execution:**
```bash
docker run -it --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /app/tcliset your_file.tcl
```

**Option C - ISET Interactive Mode:**
```bash
docker run -it --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /app/tcliset
```

---

## 📝 Command Explanation

- `-it` → Interactive mode (allows typing commands)
- `--rm` → Removes container on exit (no leftover containers)
- `-v "$(pwd):/workspace"` → Mounts your current directory into the container
- `-w /workspace` → Sets working directory inside the container
- `/app/tcliset` → Path to ISET executable

---

## 💡 Practical Example

1. Create a file `test.tcl`:
```tcl
puts "Hello, ISET with MUMPS!"
```

2. Execute:
```bash
docker run -it --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /app/tcliset test.tcl
```

---

## 🎯 Shortcut (Optional)

Create an alias to avoid typing the full command every time:

**Linux/Mac (add to `~/.bashrc` or `~/.zshrc`):**
```bash
alias iset='docker run -it --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /app/tcliset'
```

**Windows PowerShell (add to profile):**
```powershell
function iset { docker run -it --rm -v "${PWD}:/workspace" -w /workspace ghcr.io/USERNAME/iset-docker:latest /app/tcliset $args }
```

Then simply use:
```bash
iset test.tcl
```

---

## 🆘 Troubleshooting

### "Cannot connect to Docker daemon"
→ Make sure Docker Desktop is running

### "Permission denied" (Linux)
→ Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
```
(Log out and log back in after)

### "Unable to find image"
→ Check the image name with your instructor

---

## ✅ Benefits

- ✅ No need to install MUMPS, compilers, etc
- ✅ Works the same on Windows, Mac, and Linux
- ✅ Your files stay on your computer (outside the container)
- ✅ Always the latest ISET version

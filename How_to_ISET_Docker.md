# 🎓 Quick Guide on How to Run ISET Docker

This guide teaches you how to use the public ISET image available on Docker Hub.

---

## 📋 Prerequisites

Install **Docker**: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)

Test your Docker installation:

```docker run hello-world```

> ⚠️ **Note**: You may need to run Docker with sudo:

```sudo docker run hello-world```

I will omit ```sudo``` hereafter.

> ⚠️ **Note for Windows Users** You must install ```WSL``` to use Docker on Windows. See Section [**Enabling WSL**](#enabling-wsl-on-windows) at the end of this document.

---

## 🚀 How to Use

### 1️⃣ Pull the ISET Image

```bash
docker pull gfem1st/iset:yyy_mm_dd
```

```docker image ls```

The last command should list ```gfem1st/iset:yyy_mm_dd``` in the ```IMAGE``` column.
This image should also be listed in your **Docker Desktop app**.

> ⚠️ **Note**: C.A. Duarte will provide the correct image name.
> The latest version, as of 09/11/2026, is ```gfem1st/iset:2026_09_11```. Thus, replace ```gfem1st/iset:yyy_mm_dd``` with ```gfem1st/iset:2026_09_11``` or with the name of a newer image.

---

### 2️⃣ Create Your Working Directory

```bash
mkdir my-iset-project
cd my-iset-project
```
Copy ISET files to this folder. You can run ISET from any folder on your system.

---

### 3️⃣ Run the Container

**Option A - Direct Execution:**
```
docker run -it --rm -v $(pwd):/workspace -w /workspace gfem1st/iset:yyy_mm_dd /app/tcliset your_file.tcl
```

**Option B - Interactive Mode (Terminal):**
```
docker run -it --rm -v $(pwd):/workspace -w /workspace gfem1st/iset:yyy_mm_dd /bin/bash
```

Inside the container, run:
```
/app/tcliset your_file.tcl
```

The following sample ISET files are available in the folder ```/app/ ``` of the container:

```
2d_tria_heat_dirich_pt_analytic_p1.tcl
2d_tria_heat_dirich_analytic.grf
```

```
Double_torsion_1.tcl
Double_torsion_1_Parallel.tcl
Double_torsion.grf
Double_torsion.crf
```

<!--
**Option C - ISET Interactive Mode:**
```bash
docker run -it --rm -v $(pwd):/workspace -w /workspace gfem1st/iset:yyy_mm_dd /app/tcliset
```
-->

---

## 📝 Command Explanation

- `-it` → Interactive mode (allows typing commands)
- `--rm` → Removes container on exit (no leftover containers)
- `-v $(pwd):/workspace` → Mounts your current directory into the container
- `-w /workspace` → Sets working directory inside the container
- `/app/tcliset` → Path to ISET executable in the container

---

## 💡 Practical Example

1. Create a file `test.tcl`:
```tcl
puts "Hello, ISET with MUMPS!"
```

2. Execute:

```
docker run -it --rm -v $(pwd):/workspace -w /workspace gfem1st/iset:yyy_mm_dd /app/tcliset test.tcl
```

---

## 🎯 Shortcut (Optional)

Create an alias to avoid typing the full command every time:

**Linux/Mac (add to `~/.bashrc` or `~/.zshrc`):**
```
alias iset-docker='docker run -it --rm -v $(pwd):/workspace -w /workspace gfem1st/iset:yyy_mm_dd /app/tcliset'
```

**Windows PowerShell (add to profile):**
```powershell
function iset-docker { docker run -it --rm -v ${PWD}:/workspace -w /workspace gfem1st/iset:yyy_mm_dd /app/tcliset $args }
```

Then simply use:
```
iset-docker test.tcl
```

---

## 🆘 Troubleshooting

### "Cannot connect to Docker daemon"
→ Make sure Docker Desktop is running

### "Permission denied" (Linux)
→ Add your user to the docker group:
```
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

---
## Enabling WSL on Windows

1. **Open Windows Command Prompt or PowerShell as administrator**: right-click on the Start button and select Windows Terminal (Admin) or Windows PowerShell (Admin).
2. **Run the following command**:
```
wsl --install
```
This command will enable WSL, install the latest WSL kernel, and set up a default Linux distribution. By default, it will install the most recent Ubuntu LTS version. After downloading and installing a Linux distribution, you should get the following message:
```
Distribution successfully installed. It can be launched via 
'wsl.exe -d Ubuntu'
```
3. **Welcome to WSL**:
Windows will open a "Welcome to Windows Subsystem for Linux" application. It is highly recommended to go through the General, Working Across File Systems and GUI Apps sections.

4. **Reboot your system**: This step is required to complete the installation.

5. After rebooting, open a Windows Terminal as administrator again and check if the WSL installation has also installed a Linux distribution. To do that, type:
```
wsl --list
```
If you see an Ubuntu installation, you can jump to the next section of this tutorial. If WSL says that there is no Linux distribution installed, then go ahead and enter:
```
wsl --install Ubuntu
```
Wait for the process to be completed and close the terminal.

6. Once WSL is enabled, you need to set up your Linux machine:

  1. **Start your Linux system**: Find WSL or your distribution name (Ubuntu by default) in the Start menu. Click on it to start your Linux environment.

  2. **Create your user**: The WSL assistant will prompt you for the username. It can be anything you prefer, as long as it does not contain spaces or special characters.
  ```
  Provisioning the new WSL instance Ubuntu
  This might take a while...
  Create a default Unix user account: yourname
  ```

  Enter your username and press Enter. You will also need to provide and confirm a password.
  You will only need to go over this process once.

  3. **Welcome message**: You should see a welcome message similar to:
  ```
  Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 5.15.167.4-microsoft-standard-WSL2 x86_64)

  * Documentation:  https://help.ubuntu.com
  * Management:     https://landscape.canonical.com
  * Support:        https://ubuntu.com/pro

  System information as of Mon Mar 10 10:43:13 CDT 2025

    System load:  0.0                 Processes:             31
    Usage of /:   0.1% of 1006.85GB   Users logged in:       0
    Memory usage: 1%                  IPv4 address for eth0: 172.17.249.45
    Swap usage:   0%
  ```


# CUDA - This file takes input an image and applies the split-merge technique to detect the connected components. 
The install steps for CUDA are as follows -
For UBUNTU 14.04 :

1)Verify You Have a CUDA-Capable GPU :
$ lspci | grep -i nvidia

If you do not see any settings, update the PCI hardware database that Linux maintains 
by entering update-pciids (generally found in /sbin ) at the command line and rerun 
the previous lspci command. 
If your graphics card is from NVIDIA and it is listed in http://developer.nvidia.com/ 
cuda-gpus, your GPU is CUDA-capable.

2)Verify You Have a Supported Version of Linux :
$ uname -m && cat /etc/*release

You should see output similar to the following, modified for your particular system: 
x86_64 
Red Hat Enterprise Linux Workstation release 6.0 (Santiago)

3)Verify the System Has gcc Installed :
gcc --version 
If an error message displays, you need to install the development tools from your Linux 
distribution or obtain a version of gcc and its accompanying toolchain from the Web.

4) Download the NVIDIA CUDA Toolkit :
The NVIDIA CUDA Toolkit is available at http://developer.nvidia.com/cuda-downloads. (Download the .deb package)
Choose the platform you are using and download the NVIDIA CUDA Toolkit

5) Install repository meta-data :
$ sudo dpkg -i cuda-repo-<distro>_<version>_<architecture>.deb

6)Update the Apt repository cache :
$ sudo apt-get update

7)Install CUDA :
$ sudo apt-get install cuda

8)Environment Setup :
The PATH variable needs to include /usr/local/cuda-7.0/bin 
The LD_LIBRARY_PATH variable needs to contain /usr/local/cuda-7.0/lib64 on a 
64-bit system, and /usr/local/cuda-7.0/lib on a 32-bit system 

To change the environment variables for 64-bit operating systems: 
$ export PATH=/usr/local/cuda-7.0/bin:$PATH 
$ export LD_LIBRARY_PATH=/usr/local/cuda-7.0/lib64:$LD_LIBRARY_PATH 
To change the environment variables for 32-bit operating systems: 
$ export PATH=/usr/local/cuda-7.0/bin:$PATH 
$ export LD_LIBRARY_PATH=/usr/local/cuda-7.0/lib:$LD_LIBRARY_PATH

9) Edit the .bashrc file using editor:
Add the following lines to the file :
$ export PATH=/usr/local/cuda-7.0/bin:$PATH 
$ export LD_LIBRARY_PATH=/usr/local/cuda-7.0/lib64:$LD_LIBRARY_PATH 

10) Reboot

11) Verify on terminal if installed successfully:
$ nvcc --version

The output should be given as:

nvcc: NVIDIA (R) Cuda compiler driver 
Copyright (c) 2005-2015 NVIDIA Corporation 
Built on Mon_Feb_16_22:59:02_CST_2015 
Cuda compilation tools, release 7.0, V7.0.27 


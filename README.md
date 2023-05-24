
# A Practical Guide to Apptainer - UT Data Engineering (Spring 2023)


This guide will introduce you to Apptainer (formerly Singularity), a containerization system for scientific computing environments that is available on many scientific computing clusters. Containers allow you to package the environment that your code depends on inside of a portable unit. This is extremely useful for ensuring that your code can be run portably on other machines. It is also useful for installing software, packages, libraries, etc. in environments where you do not have root privileges, like an HPC account.
The repository contains the guide and files for the practical session of Apptainer containers for the course Data Engineering at the University of Tartu.
It is divided in four parts and it goes from the installation process, knowing basic commands and finally a more advanced exercise.

## Part I. Installing Apptainer

You have two options to get Apptainer installed on your machine.

### Option 1: The Docker way (recommended for the practice session)

`docker` and `git` should be installed on your machine. Then we need to create a container that has the dependencies and binary of apptainer in it. The container to run uses the `kaderno/apptainer` image that was built with a custom [Dockerfile](./Dockerfile).

Download the contents of the repo:
```
$ git clone https://github.com/DataSystemsGroupUT/singularity-tutorial.git
$ cd singularity-tutorial
$ docker run --name apptainer -v $(pwd)/material:/material -it --privileged kaderno/apptainer:latest
```

Test that the installation works.
```bash
$ apptainer --version
apptainer version 1.1.8
```

### Option 2: The traditional way

Depending on your machine, install the dependencies and the apptainer program.
The [official website](https://github.com/apptainer/apptainer/blob/main/INSTALL.md) provides a comprehensive manual to get it done.

Test that installation works.
```bash
$ apptainer --version
apptainer version 1.1.8
```

Now clone the repository locally. If you have `git`, then just execute:

```
$ git clone https://github.com/DataSystemsGroupUT/singularity-tutorial.git
$ cd singularity-tutorial
```

**NB!** In the following sections we will assume that commands and examples will run under the "Docker way" configuration.

Now you're ready to go :)

## Part II. First steps with Apptainer

Apptainer instantiates containers from images that define their environment. Apptainer images are stored in `.sif` files.
You build a .sif file by defining your environment in a text file and providing that definition to the command apptainer build.
Building an image file does require root privileges, so it is most convenient to build the image on your local machine or workstation and then copy it to your HPC cluster.
Once you've uploaded your image to your HPC cluster, you can submit a batch job that runs apptainer exec with the image file you created and the command you want to run.

### Running containers

__Example 1__: Latest Ubuntu image from the Docker Hub:

```
$ apptainer run docker://ubuntu:latest
$ docker run ubuntu:latest # Docker equivalent
```

__Example 2__: Any image from the Docker Hub:

```
$ apptainer run docker://godlovedc/lolcow
$ docker run godlovedc/lolcow # Docker equivalent
```

__Example 3__: Pre-built `.sif` file:

```
$ apptainer run hello/hello.sif
```

We can run containers from different sources.

```
*.sif               Singularity Image Format (SIF)
*.sqsh              SquashFS format.  Native to Singularity 2.4+
*.img               ext3 format. Native to Singularity versions < 2.4
directory/          sandbox format. Directory containing a valid root file
instance://*        A local running instance of a container
library://*         A SIF container hosted on a Library
docker://*          A Docker/OCI container hosted on Docker Hub
shub://*            A container hosted on Singularity Hub
oras://*            A SIF container hosted on an OCI registry
```

### Building our own container image

To build a apptainer container, we use the `build` command.  The `build` command installs an OS, sets up a container's environment and installs the apps we will need.
The `build` command accepts a target as input and produces a container as output.
To use the `build` command, we need a **recipe file** (a.k.a definition file).

A Apptainer recipe file is a set of instructions telling Apptainer what software to install in the container.
A Apptainer Definition file is divided in two parts:

- __Header :__ Describes configuration of the base operating system within the container. The most important keyword here is `Bootstrap` and you can find the supported options in the [documentation](https://apptainer.org/docs/user/latest/appendix.html#buildmodules).
```
BootStrap: debootstrap
OSVersion: jammy
MirrorURL: http://us.archive.ubuntu.com/ubuntu/
```

- __Sections :__ Group definitions of the container. Each section is defined by the `%` character and a reserved keyword:

```
%runscript
    echo "This is what happens when you run the container..."

%post
    echo "Hello from inside the container"
```

Here we can see an overview of the valid sections. The complete reference can be found [here](https://apptainer.org/docs/user/latest/definition_files.html#sections).

```
%setup              groups commands to be executed first on the host system
%files              copies files into the container
%app*               redundant to build different containers for each app
%post               installs new software and libraries, write configuration files, create new directories
%test               runs at the very end of the build process to validate the container using a method of your choice
%environment        defines environment variables used at runtime
%startscript        groups files executed when the instance start command is issued
%runscript          groups commands to be executed when the container image is run
%labels             used to add metadata to the file
%help               adds information to the metadata file in the container during the build
```

The Apptainer source code contains several example definition files in the `/examples` subdirectory.
Let's take its `ubuntu` example definition that has been copied to the `material/ubuntu` directory.

```
BootStrap: debootstrap
OSVersion: jammy
MirrorURL: http://archive.ubuntu.com/ubuntu/


%runscript
    echo "This is what happens when you run the container..."


%post
    echo "Hello from inside the container"
    sed -i 's/$/ universe/' /etc/apt/sources.list
    apt-get update
    apt-get -y install vim
    apt-get clean

```

Now let's use this definition file as a starting point to build our `ubuntu.sif` container. Note that the build command requires `sudo` privileges when executing in non-docker mode.

```
$ cd /material/ubuntu
$ apptainer build ubuntu.sif Apptainer
$ apptainer run ubuntu.sif
```

We can also spawn a shell within the container and interact with it. For this we execute the `shell` command.

```
$ apptainer shell ubuntu.sif
```

Depending on the environment on your host system you may see your prompt change. Let's see the information of the OS running in the container.

```
Apptainer> cat /etc/os-release 
PRETTY_NAME="Ubuntu 22.04 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04 (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy

```
As an additional experiment, let's build the lolcow program in two different ways. These two ways will only differ in the bootstrap agent and they will contain the same definitions for the sections. This is described below:
```
%runscript
    fortune | cowsay | lolcat

%files
    install-dependencies.sh install-dependencies.sh

%post
    echo "Hello from inside the container"
    sh -x install-dependencies.sh

%environment
    export PATH=/usr/games:$PATH
    export LC_ALL=C
```
The first way uses the `ubuntu.sif` image that we previously built.

```
BootStrap: localimage
From: /material/ubuntu/ubuntu.sif
```
Let's build the image
```
$ cd /material/lolcow
$ apptainer build lolcow-localimage.sif lolcow-localimage.def
$ apptainer run lolcow-localimage.sif
```
The second way uses the base library, which is commonly used for Apptainer containerized environments. 

```
BootStrap: library
From: ubuntu:22.04
```
Let's build and run the second image

```
$ cd /material/lolcow
$ apptainer build lolcow-library.sif lolcow-library.def
FATAL:   Unable to get library client configuration: remote has no library client (see https://apptainer.org/docs/user/latest/endpoint.html#no-default-remote)

$ apptainer run lolcow-library.sif
```

Unlike Singularity, Apptainer’s default remote endpoint configures only a public key server, it does not support the `library:// protocol`. If you would still like to have the previous default, these are the commands to restore the library behavior from before Apptainer, where using the `ibrary://` URI would download from the Sylabs Cloud anonymously:
```
$ apptainer remote add --no-login SylabsCloud cloud.sycloud.io
INFO:    Remote "SylabsCloud" added.


$ apptainer remote use SylabsCloud
INFO:    Remote "SylabsCloud" now in use.

$ apptainer remote list
Cloud Services Endpoints
========================

NAME           URI                  ACTIVE  GLOBAL  EXCLUSIVE  INSECURE
DefaultRemote  cloud.apptainer.org  NO      YES     NO         NO
SylabsCloud    cloud.sycloud.io     YES     NO      NO         NO

Keyservers
==========

URI                     GLOBAL  INSECURE  ORDER
https://keys.sylabs.io  YES     NO        1*

```
Now we will be able to build and run the image

```
$ apptainer build lolcow-library.sif lolcow-library.def
$ apptainer run lolcow-library.sif
```

Remember that Apptainer can build containers in several different file formats. The default is to build a [squashfs](https://en.wikipedia.org/wiki/SquashFS) image. The `squashfs` format is compressed and immutable making it a good choice for reproducible, production-grade containers. However, if you want to shell into a container and have more freedom with it, you should build a sandbox (which is just a directory). This is great when you are still developing your container and don't yet know what should be included in the recipe file.
The command would look like this:

```
$ apptainer build --sandbox lolcow-library.sif lolcow-library.def
```

## Part III. Data intensive application

For this part we will execute a Tensorflow program (borrowed from [here](https://keras.io/examples/vision/captcha_ocr/)) that trains a neural network to solve captchas. It also logs the progress of the training and saves the result into a file.
Since we want to avoid installing all the dependencies of tensorflow in a blank Apptainer image, we better use the `tensorflow/tensorflow:2.12.0` image from the Docker Hub. Additionally we install the `matplotlib` dependency in the `%post` stage.

```
Bootstrap: docker
From: tensorflow/tensorflow:2.12.0

%post
    pip install matplotlib
```

The definition of the image can be found in [material/tensorflow/Apptainer](material/tensorflow/Apptainer).
Now we can build this definition into a `.sif` image file using the following command:

```
$ cd /material/tensorflow
$ apptainer build tensorflow.sif Apptainer
```
This ran the commands we defined in the `%post` section inside a container and
afterwards saved the state of the container in the image `tensorflow.sif`.

Let's run our Tensorflow program in a container based on the image we just built.
Before executing the command we have to copy the python source code files into the new container.
We achieve this by adding the `--bind` flag and specifying the source and destintation paths to mount.
Finally we run the program using the`sh` command.

```
$ apptainer exec --bind /material/tensorflow/:/material tensorflow.sif sh -c "cd /material && python captcha_ocr.py"
```

This program does not take long to run. Once it finishes, it creates the file `out.png` with all the captchas and predictions.

![Plot](images/plot.png)

Worth to mention that, for convenience, Apptainer
[binds a few important directories by default](https://apptainer.org/docs/user/latest/bind_paths_and_mounts.html#bind-paths-and-mounts):
* Your home directory
* The current working directory
* `/sys`
* `/proc`
* `/tmp`
* `/var`
* `/etc/resolv.conf`
* `/etc/passwd`


## Part IV. Advanced Usage of Apptainer

For this part it is necessary to get access to an HPC cluster or set it up locally.

### MPI
You can run Apptainer containers via MPI. You'll need to have MPI installed within the container.
- If you are working on a single node, you can run MPI within a container.
- However, more commonly you would use the MPI executable on your HPC cluster to execute Apptainer containers.

The key thing in order to use the system MPI to run Apptainer containers is to make sure the MPI installed inside the container is compatible with the MPI installed on the HPC.
The easiest way to ensure this is to have the version inside the container be the same version as the MPI module you plan to use on any HPC cluster. You can see these modules with:

```
$ module load gcc # load the gcc version of interest
$ module avail openmpi  # see the MPI versions available for that gcc
```
Here is an example of running a Apptainer container via MPI. Fist we build the image:

```
$ cd /material/mpi
$ apptainer build openmpi.sif Apptainer
```
This will prepare the `mpitest.c` to execute MPI natively on the HPC cluster.
The program is simple. It ranks the completion order of MPI executors.
For that we launch 2 processes per node on all allocated nodes.
```
$ module load gcc openmpi
$ mpirun -n 2 apptainer run openmpi.sif /opt/mpitest

```

Since we are not connected to an HPC cluster, we can still run the container locally:

```
$ sudo mpirun --allow-run-as-root -n 2 apptainer run openmpi.sif -c /opt/mpitest
Hello, I am rank 1/2
Hello, I am rank 0/2

```


### SLURM

If your target system is setup with a batch system such as SLURM, a standard way to execute MPI applications is through a batch script. The following example illustrates the context of a batch script for Slurm that aims at starting a Apptainer container on each node allocated to the execution of the job. It can easily be adapted for all major batch systems available.
Here's an example of running a Apptainer container with SLURM:

```
#!/bin/bash
#SBATCH --job-name apptainer-mpi
#SBATCH -N $NNODES # total number of nodes
#SBATCH --time=00:05:00 # Max execution time

mpirun -n $NP apptainer exec openmpi.sif /opt/mpitest
```

### GPU/CUDA

You can easily use a Apptainer container that does computation on a GPU. Apptainer supports NVIDIA’s CUDA GPU compute framework.
By using the `--nv` flag when running Apptainer, the NVIDIA drivers in the HPC cluster are dynamically mounted into the container at run time. The container should provide the CUDA toolkit, using a version of the toolkit that is compatible with the NVIDIA driver version in the HPC.

Here's an example of running a Apptainer container based on a Docker container that provides GPU-using software.
```
$ apptainer run --nv docker://pytorch/pytorch:1.6.0-cuda10.1-cudnn7-runtime
```

## Conclusion

- We have learned the necessary commands of Apptainer to start producing containers that can run in HPC environments.
- Apptainer enables isolation, reproducibility and security in HPC environments.
- Its use is mostly targeted to scientific applications with intensive performance requirements.

## References

- [https://github.com/sylabs/singularity-userdocs/blob/master/mpi.rst](https://github.com/sylabs/singularity-userdocs/blob/master/mpi.rst)
- [https://github.com/maheshbabuadapa/Singularity-Tutorial](https://github.com/maheshbabuadapa/Singularity-Tutorial)
- [https://docs-research-it.berkeley.edu/services/high-performance-computing/user-guide/software/using-software/using-singularity-savio](https://docs-research-it.berkeley.edu/services/high-performance-computing/user-guide/software/using-software/using-singularity-savio)
- [https://github.com/bdusell/singularity-tutorial](https://github.com/bdusell/singularityn-tutorial)

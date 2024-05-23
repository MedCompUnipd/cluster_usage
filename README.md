# MedComp Cluster Instructions
This cluster uses [SLURM](https://slurm.schedmd.com/documentation.html) as a job scheduler, meaning that every operation to be run on it must be launched using SLURM with the appropriate options. The rationile is to have a structure similar to real life instances of High Performance Computing (HPC) platforms, where standard users do not have permissions to install its own softwares and/or libraries. Nonetheless, it is possible to run any type of program requiring any type of software/libraries using containers. Each job is run calling a batch script (used to submit jobs to SLURM), inside which a container must be used to launch any program.

## Job preparing steps
The steps for the correct utilisation of the cluster for running a job are:
* [Building a container](https://apptainer.org/docs/user/main/cli/apptainer_build.html) with all the necessary software and libraries
* Executing the container with the appropriate [apptainer](https://github.com/apptainer/apptainer) instructions, paying attention to the [binding](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html) options
* Writing a [sbatch](https://slurm.schedmd.com/sbatch.html) script with the appropriate options for SLURM to execute the container

Here follows a breakdown of all those steps.

### Building a container
The process of building a container is done using the command:
Then you can run FunTaxIS-lite as follow:

    apptainer build <container_name.sif> <container_name.def

where:
- `container_name.sif` is the name of the resulting container which will be built;
- `container_name.def` is the container definition file with all the instructions for apptainer to build the container.

Inside the file `container_definition.txt` you can find a complete list of the possible steps to be included in the definition file, although the most common cases use few of those sections. Some practical examples are available inside the `definitions` folder of this repository. Each of those examples will have comments further explaining what is done whithin the definition file and the container itself.

The three most common cases of building a container are the following:
* Installing custom libraries and/or commands (e.g. python modules like [tqdm](https://pypi.org/project/tqdm/) or bash commands like [pip](https://pip.pypa.io/en/stable/) to be used for executing downstream scripts. See `definitions/custom_python.def` as an example.
* Creating a standalone container which executes code and/or programs within its own environment. Those are typically called passing an input and some options. See `definitions/standalone_container.def` as an example.
* Expanding an existing container adding custom libraries and/or commands, like with case 1 but not from scratch. See `definitions/expand_container.def` as an example.

Once the container is built and the `container_name.sif` image is created, the next step is how to correctly execute it using apptainer

### Executing a container
The container must be un inside the cluster using apptainer, and in most cases the command which will be used is one of the following:
* `apptainer run`: used to run a container with a predefined action or entry point. The container's definition file specifies the default action, such as a script or application that should be executed when the container is run
* `apptainer exec`: allows you to execute a specific command or script inside the container, bypassing the default entry point defined by the container

#### Apptainer run
**Example:**
  ```bash
  apptainer run <my_container.sif>

Here, my_container.sif will execute its default run action.
This is the case which applies to the example container built with `definitions/standalone_container.def`: inside the container itself are the executables which will be run when calling it in this way, and eventually you will need only to complete the command with the appropriate options.

**Usage:**
  ```bash
  apptainer run --bind </path/on/host/>:</path/inside/container> <my_container.sif> [options]

For this particular example, this is the command line to execute the container. The `--bind` option pertains to the `apptainer run` command and will be expanded on later. The options after <my_container.sif> are the options which are passed to the script/program executed as entry point of the container, and depend on the options (mandatory or not) required by such script/program.

#### Apptainer exec
**Example:**
   ```bash
  apptainer exec <my_container.sif> ls /home

This runs the ls /home command inside the my_container.sif container, listing the contents of the /home directory.
This is the case which applies to the example containers built with `definitions/custom_python.def` or `definitions/expand_container.def`: those don't have executables inside themselves, but provide just an environment for external scripts/programs to be executed. 

**Usage:**
   ```bash
   apptainer exec --bind </path/on/host/>:</path/inside/container> <my_container.sif> <my_script> [options]

For this particular example, this is the command line to execute the container. The `--bind` option pertains to the `apptainer exec` command and will be expanded on later. The options after <my_script> are the options which are passed to the script/program (which is on the host, outside the container) executed within the container environment. Also in this case, the options depend on the options (mandatory or not) required by such script/program.

#### Mechanics of the --bind option
The `--bind` option is used to mount directories from the host file system into the container. This means that the container filesystem, which is independent from the host filesystem and cannot access it, will be able to access and modify host files and directories from within the container (useful for reading inputs and/or producing output files).

**Synthax:**
   ```bash
   apptainer exec --bind <host_path>:<container_path> my_container.sif <command> [options]
   apptainer run --bind <host_path>:<container_path> my_container.sif [options]

In both those cases, this binding option will create a path <container_path> inside the container filesystem, which will correspond to the <host_path> inside the host filesystem: hence, the container will be able to read/write files on <host_path> via <container_path>.

**Example:**
   ```bash
   apptainer exec --bind /data:/mnt/data my_container.sif ls /mnt/data

In this example, the host directory /data is mounted to /mnt/data inside the container. The ls /mnt/data command lists the contents of the /data directory from the host, but accessed within the container.
#### BEWARE
* The container can only access its own filesystem and not the host's, therefore it is necessary to use the `--bind` option if the executed container needs to read/write files which are on the host.
* The [options] passed to the container's entry point (or to the script/program executed within the container environment) must be consistent with the container filesystem. If /data/input_file.tsv is the input file on the host, the correct synthax is for the container to use it is:
   ```bash
   apptainer exec --bind /data:/mnt/data my_container.sif <command> -i /mnt/data/input_file.tsv
   apptainer run --bind /data:/mnt/data my_container.sif -i /mnt/data/input_file.tsv

* Be careful in how you name the bind path inside the container, because if there exist already a path with the same name inside the container, its content will be deleted and substituted with the (eventual) content of the host path used for the binding. For example, let's assume during the container definition some scripts are copied inside /mnt/data inside the container, and are used by it for the execution of its purpose. Then, assuming it needs the same input file as before, using the same command line as the previous point will result in a deletion of the scripts inside the container, because the path /mnt/data is overwritten by the binding operation. The correct way to execute the container is to use a different name for the binding, one which will not disrupt any content of its filesystem:
   ```bash
   apptainer exec --bind /data:/mnt/inputs my_container.sif <command> -i /mnt/inputs/input_file.tsv
   apptainer run --bind /data:/mnt/inputs my_container.sif -i /mnt/inputs/input_file.tsv

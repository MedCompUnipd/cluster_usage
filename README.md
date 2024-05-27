# MedComp Cluster Instructions
On MedComp's cluster the policy is not to grant users the direct permissions to install their own versions of any kind of software (such as whole programming langiages, libraries, executables). This means that each user can not install custom versions of such environments, hence every script/program must be launched using a container, which is a lightweight, portable, and self-sufficient unit that packages software and its dependencies, ensuring that the application runs consistently across different computing environments. Containers encapsulate everything needed to run an application, including the code, runtime, system tools, libraries, and settings. Hence, any kind of custom applciation can be run on the cluster using the appropriate container, without the need of installing on the cluster itself all the necessary dependancies, libraries and executables.

## Cluster structure
The cluster structure is made of six computing nodes and a frontend node, used only as access point and from which jobs can be submitted to be computed on the appropriate node. The six computing nodes are: 
* node01 - node04: four identical nodes each with 512GB of RAM
* fat: a node with 1TB of RAM
* gpu: a node with 1TB of RAM and a NVIDIA A100 GPU with 40GB of dedicated RAM.

To submit jobs from frontend to a node, this cluster uses [SLURM](https://slurm.schedmd.com/documentation.html) (Simple Linux Utility for Resource Management) as a job scheduler, meaning that every operation to be run on it must be launched using SLURM with the appropriate options. The rationile is to have a structure similar to real life instances of High Performance Computing (HPC) platforms, where standard users do not have permissions to install its own softwares and/or libraries. Nonetheless, it is possible to run any type of program requiring any type of software/libraries using containers. Each job is run calling a batch script (used to submit jobs to SLURM), inside which a container must be used to launch any program.

## Step-by-step job submission
The steps for the correct utilisation of the cluster for running a job are are the following:
* [Building a container](https://apptainer.org/docs/user/main/cli/apptainer_build.html) with all the necessary software and libraries
* Executing the container with the appropriate [apptainer](https://github.com/apptainer/apptainer) instructions, paying attention to the [binding](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html) options
* Writing a [sbatch](https://slurm.schedmd.com/sbatch.html) script with the appropriate options for SLURM to run the software on some computing node

Here follows a breakdown of all those steps.

## Building a container
The process of building a container is done using the command:
   ```bash
   # NB: for big containers, a custom temporary directory can be set in order to avoid OOM (out ot mermory) errors:
   # export SINGULARITY_TMPDIR=/path/to/custom_temporary/

   # NB: to build a container you must have root permissions or be a sudoer!
   sudo apptainer build <container_name.sif> <container_name.def>
   ```

where:
- `container_name.sif` is the name of the resulting container which will be built;
- `container_name.def` is the container definition file with all the instructions for apptainer to build the container.

WARNING: to run this command (or the equivalent but obsolete `apptainer build <--->`) you must have root permissions, therefore it CANNOT be run on the cluster itself. Either use another machine or yout local computer. The resulting sif can then be copied to wherever you want on the cluster via scp:
   ```bash   
   scp /path/to/built/container.sif user.name@medcomp.medicina.unipd.it:/path/inside/cluster/
   ```

Inside the file `container_definition.txt` you can find a complete list of the possible steps to be included in the definition file, although the most common cases use few of those sections. Some practical examples are available inside the `definitions` folder of this repository. Each of those examples will have comments further explaining what is done whithin the definition file and the container itself.

The three most common cases of building a container are the following:
* Installing custom libraries and/or commands (e.g. python modules like [tqdm](https://pypi.org/project/tqdm/) or bash commands like [pip](https://pip.pypa.io/en/stable/) to be used for executing downstream scripts. See `definitions/custom_python.def` as an example.
* Creating a standalone container which executes code and/or programs within its own environment. Those are typically called passing an input and some options. See `definitions/standalone_container.def` as an example.
* Expanding an existing container adding custom libraries and/or commands, like with case 1 but not from scratch. See `definitions/expand_container.def` as an example.

Once the container is built and the `container_name.sif` image is created, the next step is how to correctly execute it using apptainer

## Executing a container
The container must be un inside the cluster using apptainer, and in most cases the command which will be used is one of the following:
* `apptainer run`: used to run a container with a predefined action or entry point. The container's definition file specifies the default action, such as a script or application that should be executed when the container is run
* `apptainer exec`: allows you to execute a specific command or script inside the container, bypassing the default entry point defined by the container

### Apptainer run
Example:
  ```bash
  apptainer run <my_container.sif>
  ```

Here, my_container.sif will execute its default run action.
This is the case which applies to the example container built with `definitions/standalone_container.def`: inside the container itself are the executables which will be run when calling it in this way, and eventually you will need only to complete the command with the appropriate options.

Usage:
  ```bash
  apptainer run --bind </path/on/host/>:</path/inside/container> <my_container.sif> [options]
  ```

For this particular example, this is the command line to execute the container. The `--bind` option pertains to the `apptainer run` command and will be expanded on later. The options after <my_container.sif> are the options which are passed to the script/program executed as entry point of the container, and depend on the options (mandatory or not) required by such script/program.

### Apptainer exec
Example:
   ```bash
   apptainer exec <my_container.sif> ls /home
   ```

This runs the ls /home command inside the my_container.sif container, listing the contents of the /home directory.
This is the case which applies to the example containers built with `definitions/custom_python.def` or `definitions/expand_container.def`: those don't have executables inside themselves, but provide just an environment for external scripts/programs to be executed. 

Usage:
   ```bash
   apptainer exec --bind </path/on/host/>:</path/inside/container> <my_container.sif> <my_script> [options]
   ```

For this particular example, this is the command line to execute the container. The `--bind` option pertains to the `apptainer exec` command and will be expanded on later. The options after <my_script> are the options which are passed to the script/program (which is on the host, outside the container) executed within the container environment. Also in this case, the options depend on the options (mandatory or not) required by such script/program.

## Mechanics of the --bind option
The `--bind` option is used to mount directories from the host file system into the container. This means that the container filesystem, which is independent from the host filesystem and cannot access it, will be able to access and modify host files and directories from within the container (useful for reading inputs and/or producing output files).

Synthax:
   ```bash
   apptainer exec --bind <host_path>:<container_path> my_container.sif <command> [options]
   ```
   ```bash
   apptainer run --bind <host_path>:<container_path> my_container.sif [options]
   ```

In both those cases, this binding option will create a path <container_path> inside the container filesystem, which will correspond to the <host_path> inside the host filesystem: hence, the container will be able to read/write files on <host_path> via <container_path>.

Example:
   ```bash
   apptainer exec --bind /data:/mnt/data my_container.sif ls /mnt/data
   ```

In this example, the host directory /data is mounted to /mnt/data inside the container. The ls /mnt/data command lists the contents of the /data directory from the host, but accessed within the container.
### BEWARE
* The container can only access its own filesystem and not the host's, therefore it is necessary to use the `--bind` option if the executed container needs to read/write files which are on the host.
* The [options] passed to the container's entry point (or to the script/program executed within the container environment) must be consistent with the container filesystem. If /data/input_file.tsv is the input file on the host, the correct synthax is for the container to use it is:
   ```bash
   apptainer exec --bind /data:/mnt/data my_container.sif <command> -i /mnt/data/input_file.tsv
   ```
   ```bash
   apptainer run --bind /data:/mnt/data my_container.sif -i /mnt/data/input_file.tsv
   ```

* Be careful in how you name the bind path inside the container, because if there exist already a path with the same name inside the container, its content will be deleted and substituted with the (eventual) content of the host path used for the binding. For example, let's assume during the container definition some scripts are copied inside /mnt/data inside the container, and are used by it for the execution of its purpose. Then, assuming it needs the same input file as before, using the same command line as the previous point will result in a deletion of the scripts inside the container, because the path /mnt/data is overwritten by the binding operation. The correct way to execute the container is to use a different name for the binding, one which will not disrupt any content of its filesystem:
   ```bash
   apptainer exec --bind /data:/mnt/inputs my_container.sif <command> -i /mnt/inputs/input_file.tsv
   ```
   ```bash
   apptainer run --bind /data:/mnt/inputs my_container.sif -i /mnt/inputs/input_file.tsv
   ```

## Writing a sbatch file
When the container with the software is ready and needs to be executed on the cluster, it must be submitted as a job using SLURM. This means encapsulating the launch command line inside a sbatch script `my_job.sbatch`. The structure of this script is:
* A header, usually `#!/bin/bash` which tells the interpreter to read it as a bash script
* Some options providing details to SLURM on the job (a comprehensive list can be found in `sbatch_options.txt`)
* The actual command line which execute the software through its container

### Cluster Partitions
The computing nodes are organised in partitions, which are groups of nodes. Partitions in SLURM are a way to group compute nodes into logical sets based on their characteristics, such as hardware configurations, intended usage, or administrative policies. When submitting a job via SLURM, you must specify which partition you wish to use, hence which node(s) do you intend to use for yout computations, according to the estimated computing power you need. On the cluster there exist 8 partitions:
* base: this partition contains 4 nodes (node01, node02, node03, node04), and is the default partition on where your jobs will be submitted if not otherwise indicated
* all: this group is populated by all 6 nodes (node01, node02, node03, node04, fat, gpu), and slurm will submit your job on the one whose resources are most available
* node01 - node04: each of those four partitions is a group with just the corresponding node (useful if you know your job won't require more than one node)
* bigmem: a partition populated only by the node fat
* gpu: a partition populated only by the node gpu
When a job is submitted, SLURM's scheduler looks for available resources that match the job’s requirements within the specified partition(s). Jobs are prioritized based on factors like partition configuration, job size, job age (how long it has been waiting), and user fair-share policies. SLURM uses these priorities to decide the order in which jobs are scheduled.

### Submitting a job
Inside the `slurm` folder can be found some examples of sbatch files, each with an explanation of the options used. Although the variety of options which can be provided to SLURM is wide, some are commonly used such setting the job name, asking for a partition of the cluster where to run the job and providing the path of two log files where slurm will redirect stdout and stderr coming from the job. An example is:
   ```bash
   #!/bin/bash

   #SBATCH --job-name=prova
   #SBATCH --output=/path/to/logs/prova.out
   #SBATCH --error=/path/to/logs/prova.err
   #SBATCH --partition=bigmem
   #SBATCH --no-requeue

   apptainer exec --bind /path/to/data/:/data/ /path/to/containers/my_container.sif python3 -c print("hello world!")
   ```
This is the content of a sbatch file asking SLURM to create a job named "prova" to be submitted on the "bigmem" partition (aka node fat), to redirect all stdout to he logfile "/path/to/logs/prova.out" and all stderr to the logfile "/path/to/logs/prova.err". The --no-requeue option is used to avoid SLURM requeueing the job unpon failure, which can be bad practice if the job fails due to bugs or internal problems.

### Example workflow
* Submit Job: A user submits a job specifying the desired partition. Command: `sbatch my_sbatch.sbatch`
* Queue Placement: The job is placed in the queue of the specified partition(s). To monitor the current queue for the whole cluster, use command: `squeue`. To monitor the current status of the partitions for the whole cluster, use command: `sinfo`
* Resource Allocation: SLURM matches the job's requirements with available resources in the partition.
* Job Execution: Once resources are available, SLURM allocates the nodes and starts the job.
* Job Monitoring: SLURM monitors the job, ensuring it adheres to the partition’s resource limits and policies. To monitor the status of your jobs and its resouces utilisation, use command `seff <job_id>`. The <job_id> can be obtained via `squeue`
* Completion: Upon completion, resources are released, and the job's status is updated.


## Practical Examples
Now, for clarity some practical examples of the whole workflow (from the container creation to the slurm execution) will be probvided.

### 1) Custom Python Usage
To be executed on a machine where you yield root permissions:
   ```bash
   cd definitions/custom_python
   sudo apptainer build custom_python.sif custom_python.def
   scp custom_python.sif user.name@www.medcomp.medicina.unipd.it:/path/to/sifs/custom_python.sif
   ```

To be included in a sbatch file using the appropriate SLURM options:
   ```bash
   # If the paths are left unchanged, this can be run from definitions/custom_python as a test.

   apptainer exec --bind ./:/data/ custom_python.sif python3 /data/src/dummy_script.py
   # or (to change the number of interations to 20 from the default 10):
   # apptainer exec --bind ./:/data/ custom_python.sif python3 /data/src/dummy_script.py -n 20 
   ```

### 2) Expand Container Usage
To be executed on a machine where you yield root permissions:
   ```bash
   cd definitions/expand_container
   sudo apptainer build expand_python.sif expand_python.def
   scp expand_container.sif user.name@www.medcomp.medicina.unipd.it:/path/to/sifs/custom_python.sif
   ```

To be included in a sbatch file using the appropriate SLURM options:
   ```bash
   # If the paths are left unchanged, this can be run from definitions/expand_container as a test.
   # NB: to get GPU usage via apptainer, the --nv options must be included

   apptainer exec --nv --bind ./:/data/ expand_python.sif python3 /data/src/dummy_script.py
   ```

### 3) Standalone Container
To be executed on a machine where you yield root permissions:
   ```bash
   cd definitions/standalone_container
   apptainer build standalone_container.sif standalone_container.def
   scp standalone_container.sif user.name@www.medcomp.medicina.unipd.it:/path/to/sifs/custom_python.sif
   ```

To be included in a sbatch file using the appropriate SLURM options
   ```bash
   # If the paths are left unchanged, this can be run from definitions/standalone_container as a test.
   # NB: the go.owl file must be downloaded, see instructions in definitions/standalone_container/input/download_owl.txt

   apptainer run --bind ./:/data/ standalone_container.sif
   # or:
   # apptainer run --bind ./:/data/ standalone_container.sif -o /data/output/my_output.txt
   # apptainer run --bind ./:/data/ --bind /path/to/my_owl/:/data/owl/ standalone_container.sif -o /data/output/my_output.txt -w /data/owl/go.owl
   ```

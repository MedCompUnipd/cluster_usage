# MedComp Cluster Instructions
This cluster uses SLURM as a job scheduler, meaning that every operation to be run on it must be launched using SLURM with the appropriate options. The rationile is to have a structure similar to real life instances of High Performance Computing (HPC) platforms, where standard users do not have permissions to install its own softwares and/or libraries. Nonetheless, it is possible to run any type of program requiring any type of software/libraries using containers. Each job is run calling a batch script (used to submit jobs to SLURM), inside which a container must be used to launch any program.

## Job preparing steps
The steps for the correct utilisation of the cluster for running a job are:
* [Building a container](https://apptainer.org/docs/user/main/cli/apptainer_build.html) with all the necessary software and libraries
* Writing a [sbatch](https://slurm.schedmd.com/sbatch.html) script with the appropriate options
* Implementing inside the sbatch script the correct call to the container, paying attention to the binding options

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

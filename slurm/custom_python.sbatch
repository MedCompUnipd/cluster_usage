#!/usr/bin/bash

# The following options are always required, in order for the job to have a recognisable name,
# the appropriate logfiles for stdout and stderr, a partition where to submit the job ans the
# "good practice" --no-requeue option.
# NB: the path to the logfiles must already exist otherwise the job won't start. Any existing
# file with the same name will be opened in append mode.

#SBATCH --job-name=custom_python
#SBATCH --output=./log/custom_python.out
#SBATCH --errorr=./log/custom_python.err
#SBATCH --partition=base
#SBATCH --no-requeue

# The options below are optional, but it is a good practice to include them to give SLURM a
# description of the resources to be allocated for the job. In this case, since it is a dummy
# example, the resources asked are very limited: a sngle cpu in one node, expecting to execute
# one single task (the script is not parallelised) using no more than 1GB RAM memory.

#SBATCH --mem=1G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1


#NB: It is good practice to use absolute host paths for the binding option
#NB: The container must be called using the host path
#NB: The options to the container must be passed using container paths

apptainer exec --bind ./:/data/ custom_python.sif python3 /data/src/dummy_script.py
# or (to change the number of interations to 20 from the default 10):
# apptainer exec --bind ./:/data/ custom_python.sif python3 /data/src/dummy_script.py -n 20

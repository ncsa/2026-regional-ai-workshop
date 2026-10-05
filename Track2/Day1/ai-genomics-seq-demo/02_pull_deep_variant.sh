#!/bin/bash

#SBATCH --time=00:20:00
#SBATCH --job-name=pull
#SBATCH --account=${YOUR_ACCOUNT}
#SBATCH --partition=${YOUR_PARTITION}
#SBATCH --mem=118000
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --output=test.o%j
#SBATCH --error=test.e%j

SCRATCH=${YOUR_SCRATCH_DIR}
export APPTAINER_CACHEDIR=${SCRATCH}/.apptainer_cache   # avoid filling $HOME
export APPTAINER_TMPDIR=${SCRATCH}/tmp
mkdir -p $APPTAINER_CACHEDIR $APPTAINER_TMPDIR

BIN_VERSION="1.10.0"
apptainer pull deepvariant_${BIN_VERSION}.sif docker://google/deepvariant:${BIN_VERSION}
# GPU version:
# apptainer pull deepvariant_${BIN_VERSION}-gpu.sif docker://google/deepvariant:${BIN_VERSION}-gpu

# pull hap.py
apptainer pull happy.sif docker://jmcdani20/hap.py:v0.3.12

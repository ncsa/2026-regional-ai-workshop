#!/usr/bin/bash
#
#SBATCH --time=01:00:00
#SBATCH --job-name=kernel
#SBATCH --account=${YOUR_ACCOUNT_NAME}
#SBATCH --partition=${YOUR_PARTITION}
#SBATCH --mem=118000
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --output=kernel.o%j
#SBATCH --error=kernel.e%j


# One-time setup for the Genomics AI workshop notebook (DeepVariant + Enformer + Cellpose).

set -eo pipefail

# ---------------- edit these ----------------

SCRATCH=${YOUR_SCRATCH_DIRECTORY}
WORKSHOP_DIR="${SCRATCH}/ai-genomics-seq-demo"   # shared/project space is best
KERNEL_NAME="genomics-ai-workshop"
KERNEL_DISPLAY="Genomics AI Workshop"
DOWNLOAD_DATA=1                                               # 0 = skip data/weight pre-caching
# --------------------------------------------


ENV_DIR="$WORKSHOP_DIR/genomics_ai_env"
CACHE_DIR="$WORKSHOP_DIR/cache"
mkdir -p "$WORKSHOP_DIR"

# 1) conda environment
eval "$(conda shell.bash hook)"
conda create -y -p "$ENV_DIR" python=3.11 pip
conda activate "$ENV_DIR"
PYTHON="$ENV_DIR/bin/python"
"$PYTHON" -m pip install --upgrade pip wheel

# 2) packages
# CPU-only torch (CPU queue). For GPU nodes, drop --index-url to get the CUDA build.
"$PYTHON" -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
"$PYTHON" -m pip install \
    ipykernel ipywidgets \
    numpy pandas matplotlib seaborn tqdm joblib \
    enformer-pytorch pyfaidx \
    "cellpose>=4" tifffile imagecodecs scikit-image \
    pysam igv-notebook

# 3) register the kernel; caches point to the shared dir so weights are downloaded once
"$PYTHON" -m ipykernel install --user \
    --name "$KERNEL_NAME" --display-name "$KERNEL_DISPLAY" \
    --env HF_HOME "$CACHE_DIR/huggingface" \
    --env CELLPOSE_LOCAL_MODELS_PATH "$CACHE_DIR/cellpose" \
    --env WORKSHOP_DIR "$WORKSHOP_DIR"

# 4) quick check
"$PYTHON" - <<'EOF'
import torch, enformer_pytorch, cellpose, pysam, pyfaidx, matplotlib, pandas
print("torch", torch.__version__, "| CUDA available:", torch.cuda.is_available())
print("All imports OK.")
EOF
command -v apptainer >/dev/null || echo "WARNING: apptainer not on PATH — load it before starting Jupyter for the DeepVariant part."

echo "Done. Next: bash download_data.sh"

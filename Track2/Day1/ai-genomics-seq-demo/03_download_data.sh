#!/usr/bin/bash
#
#SBATCH --time=01:00:00
#SBATCH --job-name=ddata
#SBATCH --account=${YOUR_ACCOUNT_NAME}
#SBATCH --partition=${YOUR_PARTITION}
#SBATCH --mem=118000
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --output=ddata.o%j
#SBATCH --error=ddata.e%j


# One-time setup for the Genomics AI workshop notebook (DeepVariant + Enformer + Cellpose).

# Usage:  bash setup_kernel.sh            (edit the variables below first)
set -eo pipefail

# ---------------- edit these ----------------
SCRATCH=${YOUR_SCRATCH_DIR}

WORKSHOP_DIR="${SCRATCH}/ai-genomicsseq-demo"   # shared/project space is best
PYTHON="$WORKSHOP_DIR/genomics_ai_env/bin/python"
REF="$WORKSHOP_DIR/data/deepvariant/input/GRCh38_no_alt_analysis_set.fasta"   # reused as hg38 for Enformer


# --------------- DeepVariant ------------
BASE="$WORKSHOP_DIR/data/deepvariant/input" 

# Set up input and output directory data
INPUT_DIR="${BASE}/input"
OUTPUT_DIR="${BASE}/output"

## Create local directory structure
mkdir -p "${INPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Download reference to input directory
FTPDIR=ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids
curl ${FTPDIR}/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz | gunzip > ${INPUT_DIR}/GRCh38_no_alt_analysis_set.fasta
curl ${FTPDIR}/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai > ${INPUT_DIR}/GRCh38_no_alt_analysis_set.fasta.fai

HTTPDIR=https://storage.googleapis.com/deepvariant/pacbio-case-study-testdata
curl ${HTTPDIR}/HG003.SPRQ.pacbio.GRCh38.nov2024.chr20.bam > ${INPUT_DIR}/HG003.SPRQ.pacbio.GRCh38.nov2024.chr20.bam
curl ${HTTPDIR}/HG003.SPRQ.pacbio.GRCh38.nov2024.chr20.bam.bai > ${INPUT_DIR}/HG003.SPRQ.pacbio.GRCh38.nov2024.chr20.bam.bai

# Set up input variables
REF="GRCh38_no_alt_analysis_set.fasta"
BAM="HG003.SPRQ.pacbio.GRCh38.nov2024.chr20.bam"
THREADS=$(nproc)
REGION="chr20"

# Set up output variable
OUTPUT_VCF="HG003_PACBIO_SPRQ_GRCh38.chr20.output.vcf.gz"
OUTPUT_GVCF="HG003_PACBIO_SPRQ_GRCh38.chr20.output.g.vcf.gz"
INTERMEDIATE_DIRECTORY="intermediate_results_dir"

mkdir -p "${OUTPUT_DIR}/${INTERMEDIATE_DIRECTORY}"

# -------------- Enformer, CellPose ---------- 

ENF_DIR="$WORKSHOP_DIR/data/enformer"
export HF_HOME="$WORKSHOP_DIR/cache/huggingface"
export CELLPOSE_LOCAL_MODELS_PATH="$WORKSHOP_DIR/cache/cellpose"
mkdir -p "$ENF_DIR" "$HF_HOME" "$CELLPOSE_LOCAL_MODELS_PATH"

[[ -f "$REF" ]] || { echo "ERROR: $REF not found (needed as the hg38 reference)."; exit 1; }
cd "$ENF_DIR"

# Enformer inputs (same as Google's enformer-usage Colab; hg38 is linked from the DeepVariant reference)
ln -sf "$REF" hg38.fa
ln -sf "$REF.fai" hg38.fa.fai
wget -nc https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz
wget -nc https://raw.githubusercontent.com/calico/basenji/master/manuscripts/cross2020/targets_human.txt

# Model weights -> cache dirs
"$PYTHON" - <<'EOF'
from enformer_pytorch import from_pretrained
from_pretrained("EleutherAI/enformer-official-rough")      # Enformer weights -> HF_HOME
from cellpose import models
models.CellposeModel(gpu=False)                             # Cellpose-SAM weights -> CELLPOSE_LOCAL_MODELS_PATH
print("Weights cached.")
EOF

ls -lh "$ENF_DIR"
du -sh "$HF_HOME" "$CELLPOSE_LOCAL_MODELS_PATH"

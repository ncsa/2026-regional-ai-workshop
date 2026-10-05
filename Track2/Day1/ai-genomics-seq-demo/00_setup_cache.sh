# set up cache directories not to explode the home directory disk quota

SCRATCH=YOUR_SCRATCH_DIRECTORY

export CONDA_PKGS_DIRS=${SCRATCH}/conda/pkgs
export PIP_CACHE_DIR=${SCRATCH}/cache/pip
export XDG_CACHE_HOME=${SCRATCH}/cache

mkdir -p "$CONDA_PKGS_DIRS" "$PIP_CACHE_DIR" ${SCRATCH}/model_cache/clip ~/.cache
[ -L ~/.cache/clip ] || rm -rf ~/.cache/clip
ln -sfn ${SCRATCH}/model_cache/clip ~/.cache/clip

conda config --show pkgs_dirs
ls -ld ~/.cache/clip

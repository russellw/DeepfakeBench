conda config --set channel_priority strict
call conda create --name %1 python=3.7 -y
Rem should this specify 3.7.12?
conda activate %1
conda install -y -c conda-forge "libffi=3.3.*"
conda install -y -c conda-forge opencv ffmpeg
conda install -y -c conda-forge numpy
conda install -y -c conda-forge opencv
conda install -y -c conda-forge pyyaml tqdm Pillow scikit-learn 

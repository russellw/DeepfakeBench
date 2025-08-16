call conda config --set channel_priority strict
call conda create --name %1 python=3.7 -y
Rem should this specify 3.7.12?
call conda activate %1
call conda install -y -c conda-forge "libffi=3.3.*"
call conda install -y -c pytorch -c conda-forge pytorch=1.12.1 torchvision=0.13.1 torchaudio=0.12.1 cpuonly
call conda install -y -c conda-forge opencv ffmpeg
call conda install -y -c conda-forge numpy
call conda install -y -c conda-forge opencv
call conda install -y -c conda-forge pyyaml tqdm Pillow scikit-learn scikit-image albumentations dlib matplotlib imgaug python-lmdb
call conda install -y -c conda-forge "einops<=0.6.1"
call conda install -y -c conda-forge tensorboard simplejson fvcore iopath efficientnet-pytorch
call conda install -y -c conda-forge "kornia<0.7"
call conda install -y -c conda-forge timm

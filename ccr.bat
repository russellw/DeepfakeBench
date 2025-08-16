conda config --set channel_priority strict
call conda create --name %1 python=3.7 -y
Rem should this specify 3.7.12?
conda activate %1


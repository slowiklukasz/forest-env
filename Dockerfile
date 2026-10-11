FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

ENV DEBIAN_FRONTEND=noninteractive \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6" \
    FORCE_CUDA=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget build-essential libsparsehash-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "numpy>=1.19.5,<1.27.0" \
        ninja h5py pyyaml sharedarray tensorboard tensorboardx \
        yapf addict einops scipy plyfile termcolor timm

RUN pip install --no-cache-dir spconv-cu120

RUN pip install --no-cache-dir torch-scatter torch-sparse torch-cluster \
        -f https://data.pyg.org/whl/torch-2.1.0+cu121.html \
    && pip install --no-cache-dir torch-geometric

RUN pip install --no-cache-dir "laspy[lazrs]" torchmetrics pandas \
        open3d==0.19.0 seaborn==0.13.2 wandb

RUN pip install --no-cache-dir "setuptools<70.0.0" \
    && git clone --recurse-submodules https://github.com/pointcept/pointtransformerv3.git /opt/Pointcept \
    && cd /opt/Pointcept/Pointcept/libs/pointops && python setup.py install \
    && cd /opt/Pointcept/Pointcept/libs/pointgroup_ops && python setup.py install \
    && git clone https://github.com/Pointcept/PointTransformerV3.git /opt/PTv3_Standalone

ENV PYTHONPATH=/opt/Pointcept/Pointcept:/opt/PTv3_Standalone

RUN pip install --no-cache-dir jupyterlab ipykernel

WORKDIR /notebooks

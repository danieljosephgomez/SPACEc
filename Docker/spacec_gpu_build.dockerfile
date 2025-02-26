FROM debian:bullseye-slim

ARG DEBIAN_FRONTEND=noninteractive

# Update the package list and install dependencies
RUN apt-get update && \
    apt-get install -y \
    fontconfig \
    fonts-dejavu-core \
    fonts-droid-fallback \
    fonts-liberation \
    fonts-noto-mono \
    ttf-bitstream-vera \
    git \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Install Miniforge
RUN apt-get update && \
    apt-get install -y wget && \
    wget "https://github.com/conda-forge/miniforge/releases/download/23.11.0-0/Miniforge3-23.11.0-0-Linux-x86_64.sh" && \
    bash Miniforge3-*.sh -b -p /miniforge && \
    rm Miniforge3-*.sh

# Add Miniforge to PATH
ENV PATH="/miniforge/bin:${PATH}"

# Create a new conda environment with Python 3.10
RUN conda create -n spacec python=3.10 -y

# Install mamba
RUN conda install -n spacec -c conda-forge mamba -y

# Install libxml2
RUN mamba install -n spacec -c conda-forge libxml2=2.13.5 -y

# Install other dependencies
RUN mamba install -n spacec -c conda-forge graphviz libvips pyvips openslide-python -y

# Install gcc
RUN apt-get update && \
    apt-get install -y build-essential gcc && \
    rm -rf /var/lib/apt/lists/*

RUN mamba install -n spacec -c conda-forge cudatoolkit=11.2.2 cudnn=8.1.0.77 -y

# Install SPACEc
RUN mamba run -n spacec pip install spacec

# Install additional Python packages
RUN mamba run -n spacec pip install networkx==3.2.* protobuf==3.20.0 numpy==1.24.*

# Install PyTorch
RUN mamba run -n spacec pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113

# UNCOMMENT THE FOLLOWING LINES IF YOU ARE USING STELLAR
# RUN mamba run -n spacec pip install torch-scatter torch-sparse torch-cluster torch-spline-conv torch-geometric -f https://data.pyg.org/whl/torch-1.12.0+cu113.html

# Install RAPIDS and related packages
RUN mamba install -n spacec -c rapidsai -c conda-forge -c nvidia rapids=24.02 -y && \
    mamba run -n spacec pip install rapids-singlecell==0.9.5 pandas==1.5.3

# Clean up
RUN mamba clean --all -f -y && \
    rm -rf /root/.cache/pip

# Copy notebooks into the image YOU CAN CHANGE THIS TO COPY YOUR OWN NOTEBOOKS
COPY ../notebooks /notebooks
WORKDIR /notebooks

# Expose relevant ports
EXPOSE 8888
EXPOSE 5100

# Default command
CMD ["conda", "run", "-n", "spacec", "jupyter", "lab", "--ip='0.0.0.0'", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]

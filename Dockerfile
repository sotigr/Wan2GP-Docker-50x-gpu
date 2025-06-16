FROM nvidia/cuda:12.9.0-cudnn-devel-ubuntu22.04

RUN apt update
RUN apt install -y curl

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"

# Install wget to fetch Miniconda
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda on x86 or ARM platforms
RUN arch=$(uname -m) && \
    if [ "$arch" = "x86_64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"; \
    elif [ "$arch" = "aarch64" ]; then \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"; \
    else \
    echo "Unsupported architecture: $arch"; \
    exit 1; \
    fi && \
    wget $MINICONDA_URL -O miniconda.sh && \
    mkdir -p /root/.conda && \
    bash miniconda.sh -b -p /root/miniconda3 && \
    rm -f miniconda.sh

RUN pip install torch==2.7.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/test/cu128

RUN conda install -c conda-forge sentencepiece

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

RUN apt update
RUN apt install -y git
RUN pip install flash-attn==2.7.2.post1

RUN apt update && apt install ffmpeg libsm6 libxext6  -y

WORKDIR "/app"

# Clone my fork. The only change is that it defaults to version 12.0
# because it tries to detect the gpu but the docker build step does not
# mount the gpus, so the version must be explicitly defined.
RUN git clone https://github.com/sotigr/SageAttention.git

WORKDIR "/app/SageAttention"

RUN pip install -e .


ENV ALSA_CARD=Generic
ENV XDG_RUNTIME_DIR=/tmp
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:pipewire-debian/pipewire-upstream
RUN apt update && apt upgrade -y && \
apt install -y wget gcc swig libmariadb-dev pipewire-alsa pipewire libasound2-dev alsa-utils
ENV SERVER_NAME=0.0.0.0


WORKDIR "/app"
COPY . .

CMD ["/bin/bash", "-c", "python wgp.py --lora-dir-i2v lora-i2v --lora-dir lora"]

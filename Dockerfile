# Sthāna: container for Render (or any Docker host)
FROM python:3.11-slim

# OpenCV needs these system libraries even in headless mode
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    YOLO_CONFIG_DIR=/tmp/Ultralytics \
    OMP_NUM_THREADS=2 \
    PORT=10000

WORKDIR /app

# 1) CPU-only PyTorch (the default wheel bundles CUDA and is ~2 GB larger)
RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu

# 2) App dependencies; swap in headless OpenCV (no GUI libs on a server)
COPY requirements.txt .
RUN pip install -r requirements.txt \
    && pip uninstall -y opencv-python \
    && pip install --force-reinstall --no-deps opencv-python-headless

# 3) Code, model weights and sample frames
COPY . .

EXPOSE 10000
# ONE worker on purpose: live seats, timers and the video player live in memory.
# Threads handle concurrent page polls; the long timeout covers first model load and big uploads.
CMD gunicorn app:app --workers 1 --threads 8 --timeout 300 --bind 0.0.0.0:${PORT}

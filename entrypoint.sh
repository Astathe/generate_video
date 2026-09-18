#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Ensuring models are present..."
/download_models.sh

# Start ComfyUI in the background
echo "Starting ComfyUI in the background..."
# --disable-pinned-memory: pinned (page-locked) RAM can't be reclaimed and
# counts fully against the container's memory limit.
# Override everything with the COMFYUI_ARGS env var on the endpoint.
GPU_CC=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | tr -d ' ')
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
echo "GPU: $GPU_NAME (compute capability $GPU_CC)"
# The base image's SageAttention build only has kernels for Blackwell (12.x).
# On older GPUs (RTX 4090 = 8.9, A-series = 8.6) it fails with
# "no kernel image is available", so it is only enabled on Blackwell.
# Force it with SAGE_ATTENTION=on / off.
case "${SAGE_ATTENTION:-auto}" in
  on)  USE_SAGE=1 ;;
  off) USE_SAGE=0 ;;
  *)   if [ "${GPU_CC%%.*}" -ge 12 ] 2>/dev/null; then USE_SAGE=1; else USE_SAGE=0; fi ;;
esac
export USE_SAGE
if [ "$USE_SAGE" = "1" ]; then
  DEFAULT_ARGS="--use-sage-attention --disable-pinned-memory"
  echo "SageAttention: ON"
else
  DEFAULT_ARGS="--disable-pinned-memory"
  echo "SageAttention: OFF (not a Blackwell GPU)"
fi
COMFYUI_ARGS="${COMFYUI_ARGS:-$DEFAULT_ARGS}"
echo "ComfyUI args: $COMFYUI_ARGS"
python /ComfyUI/main.py --listen $COMFYUI_ARGS &

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
max_wait=120  # 최대 2분 대기
wait_count=0
while [ $wait_count -lt $max_wait ]; do
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    echo "Waiting for ComfyUI... ($wait_count/$max_wait)"
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "Error: ComfyUI failed to start within $max_wait seconds"
    exit 1
fi

# Start the handler in the foreground
# 이 스크립트가 컨테이너의 메인 프로세스가 됩니다.
echo "Starting the handler..."
exec python handler.py
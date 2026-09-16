#!/bin/bash
set -euo pipefail

# Prefer a network volume so multi-GB weights survive across workers.
# Attach a RunPod volume (50GB+) at /runpod-volume. Without it, files go into
# the container disk, which is often only 5GB and will fail.
if [ -d /runpod-volume ]; then
  MODELS_ROOT=/runpod-volume/models
  LORAS_ROOT=/runpod-volume/loras
  FOLEY_ROOT=/runpod-volume/foley
  CLIP_ROOT=/runpod-volume/clip_vision
  TEXT_ROOT=/runpod-volume/text_encoders
  VAE_ROOT=/runpod-volume/vae
  echo "Using network volume at /runpod-volume"
else
  MODELS_ROOT=/ComfyUI/models/diffusion_models
  LORAS_ROOT=/ComfyUI/models/loras
  FOLEY_ROOT=/ComfyUI/models/foley
  CLIP_ROOT=/ComfyUI/models/clip_vision
  TEXT_ROOT=/ComfyUI/models/text_encoders
  VAE_ROOT=/ComfyUI/models/vae
  echo "WARNING: /runpod-volume is missing. Downloading onto container disk."
fi

mkdir -p "$MODELS_ROOT" "$LORAS_ROOT" "$FOLEY_ROOT" "$CLIP_ROOT" "$TEXT_ROOT" "$VAE_ROOT"

download() {
  local url="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    local size
    size="$(stat -c%s "$dest" 2>/dev/null || echo 0)"
    if [ "$size" -gt 1000000 ]; then
      echo "Already present: $dest ($size bytes)"
      return 0
    fi
    echo "Removing incomplete file: $dest ($size bytes)"
    rm -f "$dest"
  fi
  echo "Downloading $dest"
  wget -nv --tries=3 --timeout=60 -O "${dest}.part" "$url"
  mv "${dest}.part" "$dest"
}

download "https://huggingface.co/buckets/Astathe/DaSiWa-WAN2.2-S2V-bucket/resolve/Distilled/FP8/v02/DasiwaWan2214BS2V_littledemonV2.safetensors" \
  "$MODELS_ROOT/DasiwaWan2214BS2V_littledemonV2.safetensors"
download "https://huggingface.co/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors" \
  "$MODELS_ROOT/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors"
download "https://huggingface.co/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors" \
  "$MODELS_ROOT/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors"

download "https://huggingface.co/75dhsx2/mizukir0418575/resolve/main/merged_CB_H_V2.safetensors" \
  "$LORAS_ROOT/merged_CB_H_V2.safetensors"
download "https://huggingface.co/75dhsx2/mizukir0418575/resolve/main/merged_CB_L_V2.safetensors" \
  "$LORAS_ROOT/merged_CB_L_V2.safetensors"
download "https://huggingface.co/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_HIGH_V2.safetensors" \
  "$LORAS_ROOT/DR34ML4Y_I2V_14B_HIGH_V2.safetensors"
download "https://huggingface.co/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_LOW_V2.safetensors" \
  "$LORAS_ROOT/DR34ML4Y_I2V_14B_LOW_V2.safetensors"
download "https://huggingface.co/rahul7star/wan2.2Lora/resolve/main/NSFW-22-H-e8.safetensors" \
  "$LORAS_ROOT/NSFW-22-H-e8.safetensors"
download "https://huggingface.co/rahul7star/wan2.2Lora/resolve/main/NSFW-22-L-e8.safetensors" \
  "$LORAS_ROOT/NSFW-22-L-e8.safetensors"

download "https://huggingface.co/phazei/HunyuanVideo-Foley/resolve/main/synchformer_state_dict_fp16.safetensors" \
  "$FOLEY_ROOT/synchformer_state_dict_fp16.safetensors"
download "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
  "$CLIP_ROOT/clip_vision_h.safetensors"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" \
  "$TEXT_ROOT/umt5-xxl-enc-bf16.safetensors"
download "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
  "$VAE_ROOT/Wan2_1_VAE_bf16.safetensors"

echo "Model download check complete."

#!/bin/bash
# Downloads model weights on worker start. Files that already exist are skipped,
# so with a network volume this only does real work the first time.
#
# Env vars (set them on the RunPod endpoint):
#   MODEL_SETS           comma list of sets to fetch (default: "dasiwa,wan22")
#                          dasiwa  - DaSiWa v11 workflow (workflow: "dasiwa")
#                          wan22   - original upstream workflow (workflow: "wan22")
#                          extras  - S2V model + HunyuanFoley synchformer
#                                    (not used by the current API workflows)
#   HF_TOKEN             sent to huggingface.co if set (private/gated repos)
#   PARALLEL_DOWNLOADS   concurrent downloads (default: 3)
#   DRY_RUN=1            only print what would be downloaded
#   VOLUME_ROOT          volume mount point (default /runpod-volume; use
#                        /workspace when running on a regular pod)
set -uo pipefail

MODEL_SETS="${MODEL_SETS:-dasiwa,wan22}"
PARALLEL_DOWNLOADS="${PARALLEL_DOWNLOADS:-3}"
DRY_RUN="${DRY_RUN:-0}"

# ---------------------------------------------------------------------------
# Target folders (must match extra_model_paths.yaml)
# ---------------------------------------------------------------------------
# VOLUME_ROOT lets you fill the same network volume from a regular pod, where
# it is mounted at /workspace instead of /runpod-volume:
#   VOLUME_ROOT=/workspace bash download_models.sh
VOLUME_ROOT="${VOLUME_ROOT:-/runpod-volume}"

if [ -d "$VOLUME_ROOT" ]; then
  ROOT="$VOLUME_ROOT"
  DIFFUSION="$ROOT/models"
  LORAS="$ROOT/loras"
  FOLEY="$ROOT/foley"
  CLIP_VISION="$ROOT/clip_vision"
  TEXT="$ROOT/text_encoders"
  VAE="$ROOT/vae"
  echo "Using network volume at $ROOT"
else
  ROOT=/ComfyUI/models
  DIFFUSION="$ROOT/diffusion_models"
  LORAS="$ROOT/loras"
  FOLEY="$ROOT/foley"
  CLIP_VISION="$ROOT/clip_vision"
  TEXT="$ROOT/text_encoders"
  VAE="$ROOT/vae"
  echo "WARNING: $VOLUME_ROOT is missing. Downloading onto container disk (every cold start!)."
fi
mkdir -p "$DIFFUSION" "$LORAS" "$FOLEY" "$CLIP_VISION" "$TEXT" "$VAE"

HF="https://huggingface.co"
COMFY_WAN21="$HF/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"

# ---------------------------------------------------------------------------
# Model sets: "URL|destination"
# ---------------------------------------------------------------------------
DASIWA_FILES=(
  # Diffusion models (UNETLoader)
  "$HF/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors|$DIFFUSION/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors"
  "$HF/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors|$DIFFUSION/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors"
  # Text encoder + VAE with the exact names the workflow asks for
  "$COMFY_WAN21/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors|$TEXT/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
  "$COMFY_WAN21/vae/wan_2.1_vae.safetensors|$VAE/wan_2.1_vae.safetensors"
  # LoRAs (workflow defaults: CB + NSFW-22 on, DR34ML4Y available via lora_pairs)
  "$HF/75dhsx2/mizukir0418575/resolve/main/merged_CB_H_V2.safetensors|$LORAS/merged_CB_H_V2.safetensors"
  "$HF/75dhsx2/mizukir0418575/resolve/main/merged_CB_L_V2.safetensors|$LORAS/merged_CB_L_V2.safetensors"
  "$HF/rahul7star/wan2.2Lora/resolve/main/NSFW-22-H-e8.safetensors|$LORAS/NSFW-22-H-e8.safetensors"
  "$HF/rahul7star/wan2.2Lora/resolve/main/NSFW-22-L-e8.safetensors|$LORAS/NSFW-22-L-e8.safetensors"
  "$HF/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_HIGH_V2.safetensors|$LORAS/DR34ML4Y_I2V_14B_HIGH_V2.safetensors"
  "$HF/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_LOW_V2.safetensors|$LORAS/DR34ML4Y_I2V_14B_LOW_V2.safetensors"
)

WAN22_FILES=(
  # Everything the upstream Dockerfile used to bake into the image
  "$HF/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors|$DIFFUSION/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors"
  "$HF/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors|$DIFFUSION/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors"
  "$HF/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors|$LORAS/high_noise_model.safetensors"
  "$HF/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors|$LORAS/low_noise_model.safetensors"
  "$COMFY_WAN21/clip_vision/clip_vision_h.safetensors|$CLIP_VISION/clip_vision_h.safetensors"
  "$HF/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors|$TEXT/umt5-xxl-enc-bf16.safetensors"
  "$HF/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors|$VAE/Wan2_1_VAE_bf16.safetensors"
)

EXTRAS_FILES=(
  "$HF/buckets/Astathe/DaSiWa-WAN2.2-S2V-bucket/resolve/Distilled/FP8/v02/DasiwaWan2214BS2V_littledemonV2.safetensors|$DIFFUSION/DasiwaWan2214BS2V_littledemonV2.safetensors"
  "$HF/phazei/HunyuanVideo-Foley/resolve/main/synchformer_state_dict_fp16.safetensors|$FOLEY/synchformer_state_dict_fp16.safetensors"
)

# ---------------------------------------------------------------------------
# Download logic
# ---------------------------------------------------------------------------
download() {
  local url="$1" dest="$2"
  if [ -s "$dest" ]; then
    echo "  present  $(basename "$dest") ($(du -h "$dest" | cut -f1))"
    return 0
  fi
  if [ "$DRY_RUN" = "1" ]; then
    echo "  MISSING  $dest"
    return 0
  fi

  # Unique temp name per worker: several workers starting at once on the same
  # volume can't corrupt each other's files, and the final mv is atomic.
  local tmp="${dest}.part.$(hostname)-$$"
  local auth=()
  if [ -n "${HF_TOKEN:-}" ] && [[ "$url" == https://huggingface.co/* ]]; then
    auth=(--header="Authorization: Bearer ${HF_TOKEN}")
  fi

  echo "  fetching $(basename "$dest")"
  local log="/tmp/wget-$(basename "$dest").log"
  wget -nv --tries=5 --waitretry=10 --timeout=120 "${auth[@]}" -O "$tmp" "$url" > "$log" 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    if [ -s "$dest" ]; then
      rm -f "$tmp"   # another worker finished first
    else
      mv -f "$tmp" "$dest"
    fi
    echo "  done     $(basename "$dest") ($(du -h "$dest" | cut -f1))"
    rm -f "$log"
    return 0
  fi

  local reason
  case "$rc" in
    3) reason="file write error - volume/disk is probably FULL" ;;
    4) reason="network failure" ;;
    5) reason="SSL error" ;;
    6) reason="authentication failed - check HF_TOKEN" ;;
    8) reason="server returned an error (404 = wrong URL, 401/403 = private/gated, 429 = rate limited)" ;;
    *) reason="wget exit code $rc" ;;
  esac
  rm -f "$tmp"
  {
    echo "  FAILED   $(basename "$dest"): $reason"
    echo "           $url"
    tail -n 3 "$log" | sed 's/^/           | /'
  } >&2
  return 1
}

# Remove temp files abandoned by workers that died mid-download (> 6 h old)
find "$DIFFUSION" "$LORAS" "$FOLEY" "$CLIP_VISION" "$TEXT" "$VAE" \
  -maxdepth 1 -name '*.part.*' -mmin +360 -delete 2>/dev/null || true

FILES=()
IFS=',' read -ra SETS <<< "$MODEL_SETS"
for s in "${SETS[@]}"; do
  s="$(echo "$s" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  case "$s" in
    dasiwa) FILES+=("${DASIWA_FILES[@]}") ;;
    wan22)  FILES+=("${WAN22_FILES[@]}") ;;
    extras) FILES+=("${EXTRAS_FILES[@]}") ;;
    "")     ;;
    *) echo "Unknown model set '$s' (use dasiwa, wan22, extras)" >&2; exit 1 ;;
  esac
done

echo "Model sets: $MODEL_SETS  (${#FILES[@]} files)"
df -h "$ROOT" | tail -1 | awk '{print "Disk " $6 ": size " $2 ", used " $3 ", free " $4}'

# Estimate how much still needs downloading (HEAD request per missing file)
if [ "$DRY_RUN" != "1" ]; then
  need=0
  for entry in "${FILES[@]}"; do
    url="${entry%%|*}"; dest="${entry#*|}"
    [ -s "$dest" ] && continue
    hdr=()
    if [ -n "${HF_TOKEN:-}" ] && [[ "$url" == https://huggingface.co/* ]]; then
      hdr=(-H "Authorization: Bearer ${HF_TOKEN}")
    fi
    size=$(curl -sIL "${hdr[@]}" "$url" | grep -i '^content-length' | tail -1 | tr -dc '0-9')
    need=$((need + ${size:-0}))
  done
  free=$(df -B1 --output=avail "$ROOT" | tail -1 | tr -dc '0-9')
  echo "Still to download: $((need / 1024**3)) GB, free: $((free / 1024**3)) GB"
  if [ "$need" -gt "$free" ]; then
    echo "ERROR: not enough space on $ROOT. Enlarge the network volume or reduce MODEL_SETS." >&2
    exit 1
  fi
fi

failed=0
running=0
for entry in "${FILES[@]}"; do
  download "${entry%%|*}" "${entry#*|}" &
  running=$((running + 1))
  if [ "$running" -ge "$PARALLEL_DOWNLOADS" ]; then
    wait -n || failed=$((failed + 1))
    running=$((running - 1))
  fi
done
while [ "$running" -gt 0 ]; do
  wait -n || failed=$((failed + 1))
  running=$((running - 1))
done

if [ "$failed" -gt 0 ]; then
  echo "ERROR: $failed download(s) failed. See messages above." >&2
  exit 1
fi
echo "Model download check complete."
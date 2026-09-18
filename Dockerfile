FROM wlsdml1114/engui_genai-base_blackwell:1.1 as runtime

ENV PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore

RUN pip install -U "huggingface_hub[hf_transfer]" runpod websocket-client

# Freeze the base image's torch stack so no custom-node requirements.txt can
# silently replace the Blackwell/CUDA 12.8 build (several of them list torch).
RUN pip list --format=freeze | grep -iE '^(torch|torchvision|torchaudio|xformers|triton|sageattention)==' > /constraints.txt && \
    cat /constraints.txt

WORKDIR /

# ---------------------------------------------------------------------------
# ComfyUI + original upstream custom nodes (needed by the wan22 workflow)
# ---------------------------------------------------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd /ComfyUI && \
    pip install -c /constraints.txt -r requirements.txt && \
    cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    pip install -c /constraints.txt -r ComfyUI-Manager/requirements.txt && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    pip install -c /constraints.txt -r ComfyUI-GGUF/requirements.txt && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    pip install -c /constraints.txt -r ComfyUI-KJNodes/requirements.txt && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    pip install -c /constraints.txt -r ComfyUI-VideoHelperSuite/requirements.txt && \
    git clone https://github.com/kael558/ComfyUI-GGUF-FantasyTalking && \
    pip install -c /constraints.txt -r ComfyUI-GGUF-FantasyTalking/requirements.txt && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    pip install -c /constraints.txt -r ComfyUI-WanVideoWrapper/requirements.txt && \
    git clone https://github.com/eddyhhlure1Eddy/IntelligentVRAMNode && \
    git clone https://github.com/eddyhhlure1Eddy/auto_wan2.2animate_freamtowindow_server && \
    git clone https://github.com/eddyhhlure1Eddy/ComfyUI-AdaptiveWindowSize && \
    mv ComfyUI-AdaptiveWindowSize/ComfyUI-AdaptiveWindowSize/* ComfyUI-AdaptiveWindowSize/

# ---------------------------------------------------------------------------
# Extra custom nodes required by the DaSiWa v11 workflow
#   rgthree-comfy               Power Lora Loader, Context, Context Switch,
#                               Any Switch, KSampler Config
#   ComfyUI-Easy-Use            easy ifElse, easy mathFloat
#   ComfyUI-Custom-Scripts      MathExpression|pysssss
#   ComfyUI-Frame-Interpolation RIFE VFI
#   comfyui-WhiteRabbit v1.1.1  PrepareLoopFrames, RIFE_SeamTimingAnalyzer,
#                               RIFE_VFI_Advanced, AssembleLoopFrames,
#                               AutocropToLoop, UpscaleWithModelAdvanced
#                               (pinned: v1.2.0 is a rewrite, the workflow
#                               was built with v1.1.x)
# ---------------------------------------------------------------------------
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/rgthree/rgthree-comfy && \
    pip install -c /constraints.txt -r rgthree-comfy/requirements.txt && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use && \
    pip install -c /constraints.txt -r ComfyUI-Easy-Use/requirements.txt && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation && \
    pip install -c /constraints.txt -r ComfyUI-Frame-Interpolation/requirements-no-cupy.txt && \
    git clone --branch v1.1.1 --depth 1 https://github.com/Artificial-Sweetener/comfyui-WhiteRabbit && \
    pip install -c /constraints.txt -r comfyui-WhiteRabbit/requirements.txt

# ---------------------------------------------------------------------------
# Small auxiliary models, baked in so they aren't downloaded on every cold
# start. Both RIFE packs keep their own checkpoint folder.
# ---------------------------------------------------------------------------
RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife \
             /ComfyUI/custom_nodes/comfyui-WhiteRabbit/vendor/ckpts/rife \
             /ComfyUI/models/upscale_models && \
    wget -nv https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/releases/download/models/rife49.pth \
         -O /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth && \
    echo "e55fd00f3cc184e3c65961f4bb827a9da022e78eed36b055242c0ac30000d533  /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth" | sha256sum -c - && \
    cp /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth \
       /ComfyUI/custom_nodes/comfyui-WhiteRabbit/vendor/ckpts/rife/rife49.pth && \
    wget -nv https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth \
         -O /ComfyUI/models/upscale_models/RealESRGAN_x4plus_anime_6B.pth

# Fail the build if any custom-node install swapped out the torch stack
RUN pip list --format=freeze | grep -iE '^(torch|torchvision|torchaudio|xformers|triton|sageattention)==' | diff - /constraints.txt && \
    echo "torch stack unchanged"

RUN mkdir -p \
    /ComfyUI/models/diffusion_models \
    /ComfyUI/models/loras \
    /ComfyUI/models/foley \
    /ComfyUI/models/clip_vision \
    /ComfyUI/models/text_encoders \
    /ComfyUI/models/vae

COPY . .
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
RUN chmod +x /entrypoint.sh /download_models.sh

CMD ["/entrypoint.sh"]
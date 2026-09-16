# Use specific version of nvidia cuda image
# FROM wlsdml1114/my-comfy-models:v1 as model_provider
# FROM wlsdml1114/multitalk-base:1.7 as runtime
FROM wlsdml1114/engui_genai-base_blackwell:1.1 as runtime

RUN pip install -U "huggingface_hub[hf_transfer]" runpod websocket-client

WORKDIR /

RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd /ComfyUI && \
    pip install -r requirements.txt && \
    cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    pip install -r ComfyUI-Manager/requirements.txt && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    pip install -r ComfyUI-GGUF/requirements.txt && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    pip install -r ComfyUI-KJNodes/requirements.txt && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    pip install -r ComfyUI-VideoHelperSuite/requirements.txt && \
    git clone https://github.com/kael558/ComfyUI-GGUF-FantasyTalking && \
    pip install -r ComfyUI-GGUF-FantasyTalking/requirements.txt && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    pip install -r ComfyUI-WanVideoWrapper/requirements.txt && \
    git clone https://github.com/eddyhhlure1Eddy/IntelligentVRAMNode && \
    git clone https://github.com/eddyhhlure1Eddy/auto_wan2.2animate_freamtowindow_server && \
    git clone https://github.com/eddyhhlure1Eddy/ComfyUI-AdaptiveWindowSize && \
    mv ComfyUI-AdaptiveWindowSize/ComfyUI-AdaptiveWindowSize/* ComfyUI-AdaptiveWindowSize/

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

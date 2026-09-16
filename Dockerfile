# Use specific version of nvidia cuda image
# FROM wlsdml1114/my-comfy-models:v1 as model_provider
# FROM wlsdml1114/multitalk-base:1.7 as runtime
FROM wlsdml1114/engui_genai-base_blackwell:1.1 as runtime

RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client

WORKDIR /

RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd /ComfyUI && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    cd ComfyUI-GGUF && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    cd ComfyUI-KJNodes && \
    pip install -r requirements.txt

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    cd ComfyUI-VideoHelperSuite && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kael558/ComfyUI-GGUF-FantasyTalking && \
    cd ComfyUI-GGUF-FantasyTalking && \
    pip install -r requirements.txt
    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap

RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper && \
    cd ComfyUI-WanVideoWrapper && \
    pip install -r requirements.txt

    
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/eddyhhlure1Eddy/IntelligentVRAMNode && \
    git clone https://github.com/eddyhhlure1Eddy/auto_wan2.2animate_freamtowindow_server && \
    git clone https://github.com/eddyhhlure1Eddy/ComfyUI-AdaptiveWindowSize && \
    cd ComfyUI-AdaptiveWindowSize/ComfyUI-AdaptiveWindowSize && \
    mv * ../

RUN mkdir -p \
    /ComfyUI/models/diffusion_models \
    /ComfyUI/models/loras \
    /ComfyUI/models/foley \
    /ComfyUI/models/clip_vision \
    /ComfyUI/models/text_encoders \
    /ComfyUI/models/vae

# DaSiWa WAN 2.2 S2V + I2V (UNETLoader)
RUN wget -q "https://huggingface.co/buckets/Astathe/DaSiWa-WAN2.2-S2V-bucket/resolve/Distilled/FP8/v02/DasiwaWan2214BS2V_littledemonV2.safetensors" -O /ComfyUI/models/diffusion_models/DasiwaWan2214BS2V_littledemonV2.safetensors
RUN wget -q "https://huggingface.co/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors" -O /ComfyUI/models/diffusion_models/DasiwaWAN22I2V14BLightspeed_synthseductionHighV9.safetensors
RUN wget -q "https://huggingface.co/johnjohn200/wanautoinstall/resolve/49ef17f027512fbbfea5508e00ed15082a683b6e/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors" -O /ComfyUI/models/diffusion_models/DasiwaWAN22I2V14BLightspeed_synthseductionLowV9.safetensors

# DaSiWa LoRAs
RUN wget -q "https://huggingface.co/75dhsx2/mizukir0418575/resolve/main/merged_CB_H_V2.safetensors" -O /ComfyUI/models/loras/merged_CB_H_V2.safetensors
RUN wget -q "https://huggingface.co/75dhsx2/mizukir0418575/resolve/main/merged_CB_L_V2.safetensors" -O /ComfyUI/models/loras/merged_CB_L_V2.safetensors
RUN wget -q "https://huggingface.co/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_HIGH_V2.safetensors" -O /ComfyUI/models/loras/DR34ML4Y_I2V_14B_HIGH_V2.safetensors
RUN wget -q "https://huggingface.co/Serenak/chilloutmix/resolve/main/DR34ML4Y_I2V_14B_LOW_V2.safetensors" -O /ComfyUI/models/loras/DR34ML4Y_I2V_14B_LOW_V2.safetensors
RUN wget -q "https://huggingface.co/rahul7star/wan2.2Lora/resolve/main/NSFW-22-H-e8.safetensors" -O /ComfyUI/models/loras/NSFW-22-H-e8.safetensors
RUN wget -q "https://huggingface.co/rahul7star/wan2.2Lora/resolve/main/NSFW-22-L-e8.safetensors" -O /ComfyUI/models/loras/NSFW-22-L-e8.safetensors

# HunyuanVideo Foley synchformer
RUN wget -q "https://huggingface.co/phazei/HunyuanVideo-Foley/resolve/main/synchformer_state_dict_fp16.safetensors" -O /ComfyUI/models/foley/synchformer_state_dict_fp16.safetensors

RUN wget -q https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors -O /ComfyUI/models/clip_vision/clip_vision_h.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors -O /ComfyUI/models/text_encoders/umt5-xxl-enc-bf16.safetensors
RUN wget -q https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors -O /ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors

COPY . .
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
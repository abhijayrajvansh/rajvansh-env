#!/usr/bin/env bash
# Genjutsu setup for Vast's ComfyUI image (rent-gpu image option 1).
# Sets up one workflow at a time and finishes it (nodes, Python packages, models, node check) before the next:
#   1. Edit Image      Qwen-Image 2.1 Turbo + base, VAE, Qwen3-VL 8B, consistency and BFS LoRAs   (docs/qwen-image-edit)
#   2. Motion control  MiniMax H3 swap, OpenMotion + Check mask: H3 nodes, SAM 3.1, the H3 models and the Motion Transfer LoRA (docs/minimax-h3-comfyui)
#   3. Fix colours     Image Detail Contrast + Orion4D tone mapper; no models                   (docs/h3-post-processing)
#   4. Fix faces       H3-FaceRefine + Impact Pack/Subpack, YOLO detectors, SAM ViT-B            (docs/h3-post-processing)
#   5. Smooth motion   Frame-Interpolation (RIFE VFI) + the RIFE 4.9 checkpoint                   (docs/h3-post-processing)
#   6. Video upscaler  SeedVR2 3B + 7B int8 and its VAE (built-in nodes), FlashVSR+ Turbo int8 (FlashVSR+ T8), VideoHelperSuite (docs/image-upscale-workflow)
# Pick workflows by passing their keys (comma or space separated; default all): edit motion color face smooth upscale.
# They install in the order given. Fix faces runs H3, so Motion control goes in just before it.
# Run again while a setup is running and the new keys are queued: when the running setup ends, it restarts with its
# own workflows plus the queued ones (finished files are only re-checked, so just the new workflows download). A model or node pack two workflows share is set up once.
# Each workflow downloads its models in parallel (PARALLEL_DOWNLOADS, default 3), largest first.
# Resumable and safe to rerun: finished files are kept, partial downloads resume, every model is sha256-checked.
#
# rent-gpu uploads and starts this automatically. By hand, from your Mac:
#   ssh -p PORT root@HOST 'bash -s' < rent-gpu-genjutsu.sh                 (all workflows)
#   ssh -p PORT root@HOST 'bash -s -- motion face' < rent-gpu-genjutsu.sh  (only these)
# Log:    /workspace/.rent-gpu-setup/setup.log (progress lines with % done and % left)
# Status: /workspace/.rent-gpu-setup/status, one line:
#         state|message|ready workflows|step %|step detail|workflow|workflow %|overall %|model bytes done|model bytes
# Env: COMFY_DIR, COMFY_PYTHON (defaults match vastai/comfy), HF_TOKEN for rate-limited downloads, PARALLEL_DOWNLOADS.
set -Eeuo pipefail

STATE_DIR=/workspace/.rent-gpu-setup
STATUS="$STATE_DIR/status"
COMFY=${COMFY_DIR:-${WORKSPACE:-/workspace}/ComfyUI}
PY=${COMFY_PYTHON:-/venv/main/bin/python}
COMFY_API=http://127.0.0.1:18188  # vastai/comfy's internal ComfyUI port (Caddy serves 8188)
MIN_COMFY=0.44.0                  # Qwen-Image 2.1 nodes; H3 alone needs 0.41.2
HF=https://huggingface.co
# rent-gpu copies your token here (from $HF_TOKEN, ~/.config/rent-gpu/hf_token or `hf auth login` on your Mac).
HF_TOKEN=${HF_TOKEN:-$(cat /workspace/.rent-gpu-setup/hf_token 2>/dev/null || true)}
H3_REV=912b6e38b2092ec4d2e86d24183e0d59ea059d48
Q21="$HF/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b"
GB=1000000000
IDLE_BEFORE_RESTART=60  # seconds the ComfyUI queue must stay empty before a restart
PARALLEL_DOWNLOADS=${PARALLEL_DOWNLOADS:-3}  # models downloaded at once within a workflow
NODE_UNIT=$GB  # progress weight of one custom-node pack (clone + Python packages), in downloaded-byte terms

mkdir -p "$STATE_DIR"
exec 9>"$STATE_DIR/lock"
QUEUE="$STATE_DIR/queue"  # workflows asked for while a setup was running; that setup picks them up when it ends
if ! flock -n 9; then
  if [ $# -gt 0 ]; then
    printf '%s\n' "$*" >> "$QUEUE"
    echo "Genjutsu setup is running; queued after it: $*"
  else
    echo 'Genjutsu setup is already running on this instance.'
  fi
  exit 0
fi

# ---------------------------------------------------------------------------------------------------------------
# Workflows, in install order. Per workflow: <key>_NODES (dir|git URL[|requirements file, default requirements.txt]),
# <key>_PIP (extra packages), <key>_MODELS (folder|URL at a pinned revision|bytes|sha256; the folder is under
# ComfyUI/models, or under ComfyUI when it starts with custom_nodes/), <key>_TYPES (node types it must load; write a
# space inside a type name as _, e.g. RIFE_VFI for "RIFE VFI").
# Filenames are Genjutsu's defaults (lib/h3-swap.ts, lib/server/qwen-edit-workflow.ts, lib/server/h3-workflow.ts).
WORKFLOWS=(edit motion color face smooth upscale)
declare -A TITLE=([edit]='Edit Image' [motion]='Motion control' [color]='Fix colours' [face]='Fix faces'
  [smooth]='Smooth motion' [upscale]='Video upscaler')

edit_NODES=()
edit_PIP=()
edit_MODELS=(
  "text_encoders|$Q21/text_encoders/qwen3vl_8b_int8_convrot.safetensors|9350798360|8bfd0f6e12abf2d2d697ecc888e5e90b0d6741d6708f05799f53afa560452e8f"
  "diffusion_models|$Q21/diffusion_models/qwen_image_2.1_turbo_int8_convrot.safetensors|7256787829|8144a0182964aa8403ad6dbc011db837304167d235161b9aabaa8532e967314c"
  "vae|$Q21/vae/qwen_image_2.1_vae_bf16.safetensors|675509688|bb21f7473051e1ac368515dd3f2e15cd44d7a11748ee8823e1ddca3e4876b7c9"
  "diffusion_models|$Q21/diffusion_models/qwen_image_2.1_int8_convrot.safetensors|7256783064|cb74113cb03faecd79611b01fd7fd642f0aa60d6f0b95086abee214d75eaa57d"
  "loras|$HF/ausboss/Qwen-Image-2.1-Consistency-LoRA/resolve/58897a02f4f60f88376eab5676738dd45e5ed1a2/qwen-image-2.1-consistency.safetensors|159436496|4f44ada1be2189cc23b3d010f9603543403f48454e2f76842a3d30109b20bd63"
  "loras|$HF/Alissonerdx/BFS-Best-Face-Swap/resolve/2209ae537ac5e883d6ec7db5b7bd6dccf1a0eba7/bfs_head_v1.1_qwen_2.1.safetensors|260096144|d1d748d5601077f3b6d05766f6823510e901970d916afa404a97e85dc92fa88e"
)
edit_TYPES="UNETLoader CLIPLoader VAELoader LoraLoaderModelOnly QwenImage21Cache LoadImage TextEncodeQwenImage21
EmptyLatentImage KSampler RandomNoise KSamplerSelect ManualSigmas CFGGuider SamplerCustomAdvanced VAEDecode SaveImage"

motion_NODES=(
  "comfyui-h3-oneclick-swap|https://github.com/D3voz/comfyui-h3-oneclick-swap"
  "ComfyUI-MiniMaxH3-Context-Loop|https://github.com/ethanfel/ComfyUI-MiniMaxH3-Context-Loop"
  "ComfyUI-Fantastic-MiniMaxH3-PromptBuilder|https://github.com/Adudeguyman/ComfyUI-Fantastic-MiniMaxH3-PromptBuilder"
  "ComfyUI-KJNodes|https://github.com/kijai/ComfyUI-KJNodes"
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "ComfyUI-Spectrum-MiniMax-H3|https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3"  # optional Acceleration → Spectrum
)
motion_PIP=()
# Qwen3-VL 8B is the H3 describer and Edit Image's text encoder; whichever of the two runs first downloads it.
motion_MODELS=(
  "text_encoders|$Q21/text_encoders/qwen3vl_8b_int8_convrot.safetensors|9350798360|8bfd0f6e12abf2d2d697ecc888e5e90b0d6741d6708f05799f53afa560452e8f"
  "checkpoints|$HF/Comfy-Org/sam3.1/resolve/7bb8374780a725b4353ed31f3a9395c9742b5621/checkpoints/sam3.1_multiplex_fp16.safetensors|1745546848|9ba99c92703c2e8b4f47de2d34a539bb8e18923049e238b780d70dbe6368eb03"
  "diffusion_models|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors|20970379616|9255f52b6677845ad238f20dfaafa94727053694127ab7f255c048f0f9365779"
  "loras|$HF/Kijai/MiniMax-H3-experimental/resolve/f5c3b1d5a63e008a691fca1b6096fd57a5307536/loras/minimax_h3_DMAD_4step_full_lora_avg_rank_39_bf16.safetensors|366647000|ddfdd94f4c9a0f32bf3649bb8e98ca20db572e4db6bcd9cca546a5b33ea32d11"
  # MiniMax H3 · OpenMotion (incoming hands and objects). BFS Motion Transfer Community License 1.0: local/internal
  # media creation allowed, hosted model services prohibited.
  "loras|$HF/Alissonerdx/Minimax-H3-ComfyUI/resolve/64244a4fdf226c8d37b8470d1893b6ba9ab54de1/loras/minimax_h3_motion_transfer_v1.0_ref2va.safetensors|184840504|7512973749c3658e0fa2b398b5810dfc8666a32aba6262cf689d407e297076da"
  "text_encoders|$HF/Abiray/MiniMax-H3-GGUF/resolve/9fc3454d3ebe1be1bade862cd4a5011f325a22cb/text_encoders/qwen3vl_32b_minimax_h3_int4_convrot.safetensors|14952506709|21fd2e2f06bc4fc422c6aa20893fe189edbbd9ab3068215f96e7a6cf2f6cb5bb"
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/vae/minimax_h3_video_vae_int8_convrot.safetensors|2811065184|52a2c8c73583c86e4f41cdcce3a6ad0ea562987bc0bf3d60a0cef5f5c8e60c0e"
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/vae/minimax_h3_audio_vae_fp32.safetensors|605254808|8e505d95dd1561d47abd43d4238fd40d9bb1ae9e147ed0a4cba778d76ae4db48"
)
# simple.api.json + mask.api.json, plus the nodes Genjutsu adds while editing those graphs (H3PictureSwapPlan,
# MiniMaxH3AddGuide and GetImageSize for MiniMax H3 · OpenMotion; AddGuide is built into ComfyUI 0.34+).
motion_TYPES="AudioAdjustVolume BasicGuider BasicScheduler CLIPLoader CLIPTextEncode CheckpointLoaderSimple
ComfyMathExpression GetImageSize GrowMaskWithBlur H3ClipShots H3FillShots H3GreyMannequins H3OneClickSwapPlan H3PeopleMask H3PictureSwapPlan
H3SoundtrackOrSilence H3SourceSlice ImageAndMaskPreview ImageFromBatch ImageScale ImageScaleToMaxDimension ImageStitch
KSamplerSelect LoadImage LoraLoaderModelOnly MaskComposite MiniMaxH3ChainAssemble MiniMaxH3ChainContext
MiniMaxH3ChainCurrent MiniMaxH3ChainLoopEnd MiniMaxH3ChainLoopStart MiniMaxH3ChainPlanModern MiniMaxH3ChainReview
MiniMaxH3ChainSegmentSave MiniMaxH3ContexMaskGridPreview MiniMaxH3ContexMaskedTarget MiniMaxH3FantasticVideoEditLatent
MiniMaxH3AddGuide MiniMaxH3GenerationProfile MiniMaxH3LoopTrim MiniMaxH3ReferenceToVideo MiniMaxH3SigmaShift MiniMaxH3SourceTimeline
ModelAttentionBackend PreviewAny PreviewImage PrimitiveBoolean RandomNoise SAM3_TrackToMask SAM3_VideoTrack
SamplerCustomAdvanced StringConcatenate TextGenerate TrimAudioDuration UNETLoader VAEDecode VAEDecodeAudio VAELoader
VHS_LoadVideo VHS_SelectEveryNthImage VHS_VideoCombine"

color_NODES=(
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"  # load and save the video
  "comfyui-image-detail-contrast|https://github.com/D3voz/comfyui-image-detail-contrast"
  "Orion4D_FXMax|https://github.com/orion4d/Orion4D_FXMax"
)
color_PIP=()
color_MODELS=()
color_TYPES="ImageDetailContrast Orion4D_FXMax_DCTLToneMapper VHS_LoadVideo VHS_VideoCombine"

face_NODES=(
  "ComfyUI-H3-FaceRefine|https://github.com/Carasibana/ComfyUI-H3-FaceRefine"
  "ComfyUI-Impact-Pack|https://github.com/ltdrdata/ComfyUI-Impact-Pack"
  "ComfyUI-Impact-Subpack|https://github.com/ltdrdata/ComfyUI-Impact-Subpack"  # lets FaceRefine list the YOLO files
)
face_PIP=(onnxruntime-gpu)  # insightface (FaceRefine) needs an ONNX runtime it does not declare
face_MODELS=(
  "ultralytics/bbox|$HF/Bingsu/adetailer/resolve/53cc19de382014514d9d4038601d261a7faa9b7b/face_yolov8m.pt|52026019|717923c19b3f4bbf5250b728f1fa6b2cb72a33aed1d236ea9caf0e21ad943e5f"
  "ultralytics/segm|$HF/Bingsu/adetailer/resolve/53cc19de382014514d9d4038601d261a7faa9b7b/person_yolov8m-seg.pt|54827683|c8ab26f517173b1fe8342d336a09f443eb61cb08dcbfc78d53fff4c2547ae81e"
  "sams|$HF/ybelkada/segment-anything/resolve/7790786db131bcdc639f24a915d9f2c331d843ee/checkpoints/sam_vit_b_01ec64.pth|375042383|ec2df62732614e57411cdcf32a23ffdf28910380d03139ee0f4fcbe91eb8c912"
)
face_TYPES="BasicGuider BasicScheduler CLIPLoader H3FaceChunks H3FaceJoin H3FaceMaskSAM H3FaceStitch H3FaceTrackCrop
ImageBlur ImageScaleToMaxDimension KSamplerSelect LoadImage LoraLoaderModelOnly MiniMaxH3ContexMaskedTarget
MiniMaxH3FantasticVideoEditLatent MiniMaxH3ReferenceToVideo ModelAttentionBackend RandomNoise SAMLoader
SamplerCustomAdvanced TextGenerate UNETLoader VAEDecode VAELoader VHS_LoadVideo VHS_VideoCombine"

# The node imports every VFI model at load (kornia, scipy, opencv); cupy is only for GMFSS and friends, not RIFE.
smooth_NODES=(
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"  # load and save the video
  "ComfyUI-Frame-Interpolation|https://github.com/Fannovel16/ComfyUI-Frame-Interpolation|requirements-no-cupy.txt"
)
smooth_PIP=()
# Genjutsu uses rife49 (rife426's release is a training checkpoint the node cannot load). The node would fetch it
# from GitHub on the first job; this saves that wait.
smooth_MODELS=(
  "custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife|https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/releases/download/models/rife49.pth|21345274|e55fd00f3cc184e3c65961f4bb827a9da022e78eed36b055242c0ac30000d533"
)
smooth_TYPES="RIFE_VFI VHS_LoadVideo VHS_SelectEveryNthImage VHS_VideoCombine"

# upscale.api.json: SeedVR2's nodes are built into ComfyUI (0.44+); the Video Upscaler picks 3B (default), 7B or
# FlashVSR+ Turbo. FlashVSR+ T8 runs Turbo with the preconverted INT8 DiT (needs comfy-kitchen >= 0.2.35, in the image)
# and the Tiny decoder; its loader finds them in models/flashvsr_plus (the pack's own pinned, checksummed mirror).
SEEDVR2="$HF/Comfy-Org/SeedVR2/resolve/df48879708206a403d2a61acd55578c2e80fd233"
FLASHVSR="$HF/t8star/Flashvsr-Plus-Comfy/resolve/56c806f1357d90c8a0b4b054e21bcefe3cb9ac1d"
upscale_NODES=(
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"  # load and save the video
  "Comfyui-Flashvsr-Plus-T8|https://github.com/T8mars/Comfyui-Flashvsr-Plus-T8"
)
upscale_PIP=()
upscale_MODELS=(
  "diffusion_models|$SEEDVR2/diffusion_models/seedvr2_3b_int8_convrot.safetensors|3458259704|c3dec8bcc5916843a8a858572970597462e1f2dc598d6dfd818f6cd40f53a157"
  "vae|$SEEDVR2/vae/seedvr2_ema_vae_fp16.safetensors|501324814|20678548f420d98d26f11442d3528f8b8c94e57ee046ef93dbb7633da8612ca1"
  "diffusion_models|$SEEDVR2/diffusion_models/seedvr2_7b_int8_convrot.safetensors|8334897976|5aa0d25fc9d35e449b659d0c9a5dcb22e2a4fa04032101b95a39da42b32c1be6"
  "flashvsr_plus/turbo|$FLASHVSR/turbo/dit_int8_convrot.safetensors|1448886272|14150f06a5661e6da479f7583766c55e310e16cf3ce538ba56dc70188f03d773"
  "flashvsr_plus/turbo|$FLASHVSR/turbo/lq_proj_in.safetensors|1151384272|e77b378ae12342eefbb58f924256f362a151b93ce73dd32808fcdaca9c051496"
  "flashvsr_plus|$FLASHVSR/TCDecoder.ckpt|189018333|e224bdcf2f52745cbf4d393ff5374c2ba09e90285d5d19062d2bf63b915b6161"
)
upscale_TYPES="ImageScaleBy KSampler SeedVR2Conditioning SeedVR2PostProcessing SeedVR2Preprocess SeedVR2TemporalChunk
SeedVR2TemporalMerge UNETLoader VAEDecodeTiled VAEEncodeTiled VAELoader VHS_LoadVideo VHS_VideoCombine ImageBlend ImageAddNoise
FlashVSRPlusModelLoader FlashVSRPlusUpscaleFrames"

# ---------------------------------------------------------------------------------------------------------------
# Which workflows to set up. Fix faces samples with H3, so it needs Motion control's nodes and models.
ALL_WORKFLOWS=("${WORKFLOWS[@]}")
declare -A REQUIRES=([face]=motion)
declare -A ALIAS=([edit]=edit [image]=edit [qwen]=edit [motion]=motion [h3]=motion [swap]=motion [color]=color
  [colour]=color [colours]=color [colors]=color [face]=face [faces]=face [smooth]=smooth [rife]=smooth
  [upscale]=upscale [upscaler]=upscale [seedvr2]=upscale)
declare -A WANT=()
ORDER=()
want() {  # want KEY: queue KEY after its dependency, once
  if [ -n "${WANT[$1]:-}" ]; then return 0; fi
  if [ -n "${REQUIRES[$1]:-}" ]; then want "${REQUIRES[$1]}"; fi
  WANT[$1]=1
  ORDER+=("$1")
}
for arg in "$@"; do
  for word in ${arg//,/ }; do
    word=${word,,}
    if [ "$word" = all ]; then
      for key in "${ALL_WORKFLOWS[@]}"; do want "$key"; done
    elif [ -n "${ALIAS[$word]:-}" ]; then
      want "${ALIAS[$word]}"
    else
      printf 'Unknown workflow: %s. Use any of: %s, or all.\n' "$word" "${ALL_WORKFLOWS[*]}" >&2
      printf 'failed|unknown workflow %s||||||||\n' "$word" > "$STATUS"
      exit 2
    fi
  done
done
if [ ${#ORDER[@]} -eq 0 ]; then for key in "${ALL_WORKFLOWS[@]}"; do want "$key"; done; fi
WORKFLOWS=("${ORDER[@]}")
printf 'Workflows: %s\n' "$(for key in "${WORKFLOWS[@]}"; do printf '%s, ' "${TITLE[$key]}"; done | sed 's/, $//')"

# A node pack or model listed by several selected workflows belongs to the first one in the queue, so it is installed once
# and counted once in the progress bars.
declare -A OWNED=()
for key in "${WORKFLOWS[@]}"; do
  declare -n _own_nodes="${key}_NODES" _own_models="${key}_MODELS"
  kept=()
  for entry in "${_own_nodes[@]}"; do
    id="node:${entry%%|*}"
    if [ -z "${OWNED[$id]:-}" ]; then OWNED[$id]=1; kept+=("$entry"); fi
  done
  _own_nodes=("${kept[@]}")
  kept=()
  for entry in "${_own_models[@]}"; do
    IFS='|' read -r folder url _ <<<"$entry"
    id="model:$folder/${url##*/}"
    if [ -z "${OWNED[$id]:-}" ]; then OWNED[$id]=1; kept+=("$entry"); fi
  done
  _own_models=("${kept[@]}")
  unset -n _own_nodes _own_models
done

# ---------------------------------------------------------------------------------------------------------------
# Progress. Units are bytes for downloads and NODE_UNIT per custom-node pack.
READY=()
WARNINGS=()
TOTAL_UNITS=0 DONE_UNITS=0     # all workflows
MODEL_BYTES=0 MODEL_DONE=0     # model files only (the monitor's Download row), finished ones in MODEL_DONE
WF_TITLE='' WF_UNITS=0 WF_DONE=0 # current workflow
CUR_UNITS=0                    # part of the current step already done (bytes of the files downloading now)
LAST_LOG=0

pct() { if [ "$2" -le 0 ]; then echo 100; else echo $(( $1 * 100 / $2 )); fi; }
gb() { awk "BEGIN {printf \"%.1f\", $1 / 1e9}"; }
duration() { local s=$1; if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60));
  elif [ "$s" -ge 60 ]; then printf '%dm%02ds' $((s / 60)) $((s % 60)); else printf '%ds' "$s"; fi; }
ready_list() { local IFS=,; printf '%s' "${READY[*]:-}" | sed 's/,/, /g'; }

# status STATE MESSAGE [STEP_PCT] [STEP_DETAIL] [quiet]: rewrites the status line and logs a progress line
# (progress updates from a running download pass "quiet" and are logged at most every 15 s).
status() {
  local state=$1 message=$2 step=${3:-} detail=${4:-} quiet=${5:-}
  local wf_pct='' all_pct
  [ -n "$WF_TITLE" ] && wf_pct=$(pct $((WF_DONE + CUR_UNITS)) "$WF_UNITS")
  all_pct=$(pct $((DONE_UNITS + CUR_UNITS)) "$TOTAL_UNITS")
  [ "$state" = done ] && all_pct=100
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$state" "$message" "$(ready_list)" "$step" "$detail" "$WF_TITLE" \
    "$wf_pct" "$all_pct" "$((MODEL_DONE + CUR_UNITS))" "$MODEL_BYTES" > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
  if [ -n "$quiet" ] && [ $((SECONDS - LAST_LOG)) -lt 15 ]; then return; fi
  LAST_LOG=$SECONDS
  local line="[$(date +%H:%M:%S)] $message"
  [ -n "$step" ] && line+=" — $step% done, $((100 - step))% left"
  [ -n "$detail" ] && line+=" ($detail)"
  [ -n "$wf_pct" ] && line+=" | $WF_TITLE $wf_pct% ($((100 - wf_pct))% left)"
  line+=" | overall $all_pct% ($((100 - all_pct))% left)"
  printf '%s\n' "$line"
}
warn() { WARNINGS+=("$1"); printf 'WARNING: %s\n' "$1" >&2; }
trap 'status failed "failed at line $LINENO • see $STATE_DIR/setup.log"' ERR

workflow_units() {
  local -n _wn="${1}_NODES" _wm="${1}_MODELS"
  local units=$(( ${#_wn[@]} * NODE_UNIT )) entry bytes
  for entry in "${_wm[@]}"; do IFS='|' read -r _ _ bytes _ <<<"$entry"; units=$((units + bytes)); done
  echo "$units"
}
installed() { [ -f "$1" ] && [ "$(stat -c %s "$1")" = "$2" ]; }
model_dir() { case $1 in custom_nodes/*) printf '%s\n' "$COMFY/$1" ;; *) printf '%s\n' "$COMFY/models/$1" ;; esac; }

# ---------------------------------------------------------------------------------------------------------------
# ComfyUI helpers
missing_types() {  # prints the node types from $1 that ComfyUI does not list; fails if ComfyUI is unreachable
  curl -sf --max-time 60 "$COMFY_API/object_info" -o "$STATE_DIR/object_info.json" || return 1
  "$PY" - "$STATE_DIR/object_info.json" "$1" <<'PYTHON'
import json, sys
info = {name.replace(' ', '_') for name in json.load(open(sys.argv[1]))}
print(' '.join(t for t in sys.argv[2].split() if t not in info))
PYTHON
}
wait_comfy() {
  local i
  for i in $(seq 120); do curl -sf --max-time 10 "$COMFY_API/system_stats" -o /dev/null && return 0; sleep 5; done
  return 1
}
queue_busy() {
  local queue
  queue=$(curl -sf --max-time 10 "$COMFY_API/queue") || return 1
  "$PY" -c 'import json, sys; q = json.loads(sys.argv[1]); sys.exit(0 if q.get("queue_running") or q.get("queue_pending") else 1)' "$queue"
}
restart_comfy() {
  # Never kill a job someone started on a workflow that is already set up. A restart also wipes ComfyUI's in-memory
  # history, so wait until the queue has stayed empty for IDLE_BEFORE_RESTART seconds: the app polls /history and
  # needs that time to collect a just-finished result (a restart 1 s after a job ended lost its result once).
  # `restart` in the rent-gpu monitor drops $STATE_DIR/restart-now to skip the wait (it cancels the running job).
  local waited=0 idle=0
  while [ $idle -lt "$IDLE_BEFORE_RESTART" ] && [ $waited -lt 3600 ]; do
    if [ -e "$STATE_DIR/restart-now" ]; then
      rm -f "$STATE_DIR/restart-now"
      printf 'Restart requested from the monitor; not waiting for the ComfyUI queue.\n'
      break
    fi
    if queue_busy; then
      idle=0
      status running "waiting for ComfyUI's job to finish, then restarting ($(duration $waited)) • restart skips" '' '' quiet
    else
      idle=$((idle + 5))
      status running "ComfyUI idle; restarting in $((IDLE_BEFORE_RESTART - idle + 5))s to load the new nodes" '' '' quiet
    fi
    sleep 5; waited=$((waited + 5))
  done
  rm -f "$STATE_DIR/restart-now"
  status running 'restarting ComfyUI to load the new nodes'
  if ! command -v supervisorctl >/dev/null; then warn 'supervisorctl not found; restart ComfyUI yourself'; return; fi
  supervisorctl restart comfyui >/dev/null || warn 'could not restart ComfyUI'
  sleep 5
  wait_comfy || warn 'ComfyUI did not come back within 10 minutes after the restart'
}

# ---------------------------------------------------------------------------------------------------------------
# Install steps
pip_install() {
  if command -v uv >/dev/null; then
    uv pip install -q --python "$PY" -c "$STATE_DIR/constraints.txt" "$@"
  else
    "$PY" -m pip install -q --no-cache-dir -c "$STATE_DIR/constraints.txt" "$@"
  fi
}

install_nodes() {
  local -n _nodes="${1}_NODES" _pip="${1}_PIP"
  local count=${#_nodes[@]} i=0 entry dir url path requirements reqfile
  for entry in "${_nodes[@]}"; do
    IFS='|' read -r dir url reqfile <<<"$entry"
    i=$((i + 1))
    status running "custom nodes $i/$count • $dir" "$(pct $((i - 1)) "$count")"
    path="$COMFY/custom_nodes/$dir"
    if [ -d "$path/.git" ]; then
      git -C "$path" pull --ff-only -q || warn "$dir: git pull failed; keeping $(git -C "$path" rev-parse --short HEAD)"
    elif [ -e "$path" ]; then
      warn "$dir exists but is not a git checkout; left as is"
    else
      git clone -q --depth 1 --recursive "$url" "$path"
    fi
    if [ -d "$path/.git" ]; then printf '  %s @ %s\n' "$dir" "$(git -C "$path" rev-parse --short HEAD)"; fi
    requirements="$path/${reqfile:-requirements.txt}"
    if [ -f "$requirements" ]; then
      status running "Python packages $i/$count • $dir" "$(pct $((i - 1)) "$count")" 'pip install'
      pip_install -r "$requirements" || warn "$dir: some Python requirements failed to install"
    fi
    DONE_UNITS=$((DONE_UNITS + NODE_UNIT)); WF_DONE=$((WF_DONE + NODE_UNIT))
  done
  if [ ${#_pip[@]} -gt 0 ]; then
    status running "Python packages • ${_pip[*]}" '' 'pip install'
    pip_install "${_pip[@]}" || warn "could not install ${_pip[*]}"
  fi
}

ensure_types() {  # after new nodes: restart ComfyUI only if this workflow's node types are not loaded yet
  local key=$1 missing
  status running "checking ComfyUI loaded the ${TITLE[$key]} nodes"
  wait_comfy || { warn "ComfyUI is not answering on $COMFY_API"; return 1; }
  local -n _types="${key}_TYPES"
  missing=$(missing_types "$_types") || { warn 'could not read ComfyUI node list'; return 1; }
  if [ -n "$missing" ]; then
    restart_comfy
    missing=$(missing_types "$_types") || { warn 'could not read ComfyUI node list'; return 1; }
  fi
  if [ -n "$missing" ]; then
    warn "${TITLE[$key]}: ComfyUI is missing node types: $missing (see ComfyUI's startup log)"
    return 1
  fi
}

# fetch ENTRY: downloads one model, checks its size and sha256 and moves it into place. Runs in the background,
# several at once; prints the reason on failure. "$JOBS/<name>.verifying" marks the hashing phase.
fetch() {
  trap - ERR
  set +e
  local folder url bytes sha
  IFS='|' read -r folder url bytes sha <<<"$1"
  local name=${url##*/}
  local target token=''
  target="$(model_dir "$folder")/$name"
  case $url in "$HF"/*) token=$HF_TOKEN ;; esac  # the Hugging Face token goes to Hugging Face only
  if command -v aria2c >/dev/null; then
    # 16 connections per file: one connection to Hugging Face often caps near 30 MB/s.
    aria2c -x16 -s16 -k16M -c --file-allocation=none --max-tries=10 --retry-wait=5 \
      --console-log-level=warn --summary-interval=0 --download-result=hide \
      ${token:+--header="Authorization: Bearer $token"} -d "${target%/*}" -o "$name.part" "$url" \
      >> "$STATE_DIR/download.log" 2>&1
  else
    curl -sSL --fail --retry 5 --retry-delay 5 -C - ${token:+-H "Authorization: Bearer $token"} \
      -o "$target.part" "$url" >> "$STATE_DIR/download.log" 2>&1
  fi || { echo "download failed: $name (see $STATE_DIR/download.log)"; return 1; }
  [ "$(stat -c %s "$target.part")" = "$bytes" ] || { echo "size mismatch for $name"; return 1; }
  touch "$JOBS/$name.verifying"
  if [ "$(sha256sum "$target.part" | cut -d' ' -f1)" != "$sha" ]; then
    rm -f "$target.part" "$target.part.aria2"
    echo "checksum mismatch for $name (deleted)"
    return 1
  fi
  mv "$target.part" "$target" && rm -f "$target.part.aria2"
}

# download_models KEY: fetches the workflow's models PARALLEL_DOWNLOADS at a time, largest first, so one slow file
# no longer holds up the rest. A file is hashed while the others keep downloading.
download_models() {
  local -n _models="${1}_MODELS"
  local count=${#_models[@]}
  [ "$count" -gt 0 ] || return 0
  JOBS="$STATE_DIR/jobs"
  rm -rf "$JOBS"; mkdir -p "$JOBS"
  local entry folder url bytes sha name pid part b failed='' ready=0 total=0 finished=0 queued=0
  local -a queue=()
  local -A job_name=() job_bytes=() job_part=() job_first=()
  while IFS= read -r entry; do
    IFS='|' read -r folder url bytes sha <<<"$entry"
    total=$((total + bytes))
    if installed "$(model_dir "$folder")/${url##*/}" "$bytes"; then
      printf '✓ %s already installed\n' "${url##*/}"
      DONE_UNITS=$((DONE_UNITS + bytes)); WF_DONE=$((WF_DONE + bytes)); finished=$((finished + bytes))
      MODEL_DONE=$((MODEL_DONE + bytes))
      ready=$((ready + 1))
    else
      queue+=("$entry"); queued=$((queued + bytes))
    fi
  done < <(printf '%s\n' "${_models[@]}" | sort -t'|' -k3,3nr)

  local start=$SECONDS fetched_done=0 fetched have left speed=0 detail downloading verifying
  while [ ${#queue[@]} -gt 0 ] || [ ${#job_name[@]} -gt 0 ]; do
    # Start downloads until PARALLEL_DOWNLOADS are running.
    while [ -z "$failed" ] && [ ${#queue[@]} -gt 0 ] && [ ${#job_name[@]} -lt "$PARALLEL_DOWNLOADS" ]; do
      entry=${queue[0]}; queue=("${queue[@]:1}")
      IFS='|' read -r folder url bytes sha <<<"$entry"
      name=${url##*/} part="$(model_dir "$folder")/${url##*/}.part"
      mkdir -p "$(model_dir "$folder")"
      fetch "$entry" > "$JOBS/$name.result" 2>&1 &
      pid=$!
      job_name[$pid]=$name job_bytes[$pid]=$bytes job_part[$pid]=$part
      job_first[$pid]=$(( $(stat -c '%b*%B' "$part" 2>/dev/null || echo 0) ))  # resumed bytes, not this run's speed
      printf '↓ %s (%s GB) started\n' "$name" "$(gb "$bytes")"
    done

    # Collect finished downloads.
    for pid in "${!job_name[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then continue; fi
      name=${job_name[$pid]} bytes=${job_bytes[$pid]}
      if wait "$pid"; then
        DONE_UNITS=$((DONE_UNITS + bytes)); WF_DONE=$((WF_DONE + bytes)); finished=$((finished + bytes))
        MODEL_DONE=$((MODEL_DONE + bytes))
        ready=$((ready + 1))
        printf '✓ %s verified\n' "$name"
      elif [ -z "$failed" ]; then
        failed=$(tail -n 1 "$JOBS/$name.result" 2>/dev/null || true)
        failed=${failed:-download failed: $name}
      fi
      fetched_done=$((fetched_done + bytes - ${job_first[$pid]}))
      unset "job_name[$pid]" "job_bytes[$pid]" "job_part[$pid]" "job_first[$pid]"
    done

    if [ -n "$failed" ]; then  # stop the others; aria2 keeps their .part files, so setup resumes them
      for pid in "${!job_name[@]}"; do pkill -TERM -P "$pid" 2>/dev/null || true; done
      wait 2>/dev/null || true
      CUR_UNITS=0
      status failed "$failed; type setup to resume"
      exit 1
    fi
    [ ${#queue[@]} -gt 0 ] || [ ${#job_name[@]} -gt 0 ] || break

    # Progress across every running download.
    have=0 fetched=$fetched_done downloading=0 verifying=0
    for pid in "${!job_name[@]}"; do
      name=${job_name[$pid]}
      b=$(( $(stat -c '%b*%B' "${job_part[$pid]}" 2>/dev/null || echo 0) ))  # sparse file: bytes written so far
      [ "$b" -lt "${job_bytes[$pid]}" ] || b=${job_bytes[$pid]}
      if [ -e "$JOBS/$name.verifying" ]; then verifying=$((verifying + 1)); else downloading=$((downloading + 1)); fi
      have=$((have + b)) fetched=$((fetched + b - ${job_first[$pid]}))
    done
    [ "$have" -lt $((total - finished)) ] || have=$((total - finished - 1))
    CUR_UNITS=$have
    detail=''
    if [ "$downloading" -gt 0 ] && [ $((SECONDS - start)) -ge 5 ]; then
      speed=$(( fetched / (SECONDS - start) ))
      left=$(( total - finished - have ))
      if [ "$speed" -gt 0 ]; then detail="$((speed / 1000000)) MB/s, $(duration $((left / speed))) left"; fi
    elif [ "$downloading" -eq 0 ]; then
      detail='verifying sha256'
    fi
    [ -n "$detail" ] || detail='starting'
    local what="$downloading downloading"
    [ "$verifying" -eq 0 ] || what+=", $verifying verifying"
    [ ${#queue[@]} -eq 0 ] || what+=", ${#queue[@]} queued"
    status running "models $ready/$count ready • $what" "$(pct $((finished + have)) "$total")" "$detail" quiet
    sleep 3
  done
  CUR_UNITS=0
}

run_workflow() {  # run_workflow KEY INDEX
  local key=$1 index=$2 ok=1
  local -n _nodes_ref="${key}_NODES"
  WF_TITLE="${TITLE[$key]} ($index/${#WORKFLOWS[@]})" WF_UNITS=$(workflow_units "$key") WF_DONE=0
  status running "setting up ${TITLE[$key]}"
  if [ ${#_nodes_ref[@]} -gt 0 ]; then install_nodes "$key"; fi
  # Models first: they need no ComfyUI restart, so a busy queue only delays loading the new nodes, not the downloads.
  download_models "$key"
  ensure_types "$key" || ok=0
  if [ $ok = 1 ]; then
    READY+=("${TITLE[$key]}")
    status running "${TITLE[$key]} ready"
  else
    status running "${TITLE[$key]} installed with warnings"
  fi
}

# ---------------------------------------------------------------------------------------------------------------
# Preflight
for key in "${WORKFLOWS[@]}"; do TOTAL_UNITS=$((TOTAL_UNITS + $(workflow_units "$key"))); done

status running 'waiting for ComfyUI files'
for _ in $(seq 120); do [ -f "$COMFY/main.py" ] && [ -x "$PY" ] && break; sleep 5; done
[ -f "$COMFY/main.py" ] || { status failed "ComfyUI not found at $COMFY (set COMFY_DIR)"; exit 1; }
[ -x "$PY" ] || { status failed "Python not found at $PY (set COMFY_PYTHON)"; exit 1; }
version=$(sed -n 's/^__version__ *= *"\(.*\)".*/\1/p' "$COMFY/comfyui_version.py" 2>/dev/null || true)
if ! "$PY" - "${version:-0}" "$MIN_COMFY" <<'PYTHON'
import sys
parse = lambda v: tuple(int(p) for p in (v.split('.') + ['0', '0'])[:3])
sys.exit(parse(sys.argv[1]) < parse(sys.argv[2]))
PYTHON
then
  status failed "ComfyUI ${version:-unknown} is too old; Genjutsu needs $MIN_COMFY+. Rent with a newer vastai/comfy image."
  exit 1
fi
printf 'ComfyUI %s at %s\n' "$version" "$COMFY"

need=0
for key in "${WORKFLOWS[@]}"; do
  declare -n _check="${key}_MODELS"
  for entry in "${_check[@]}"; do
    IFS='|' read -r folder url bytes _ <<<"$entry"
    MODEL_BYTES=$((MODEL_BYTES + bytes))
    installed "$(model_dir "$folder")/${url##*/}" "$bytes" || need=$((need + bytes))
  done
  unset -n _check
done
mkdir -p "$COMFY/models"
free=$(df -PB1 "$COMFY/models" | awk 'NR==2 {print $4}')
headroom=$((8 * GB))  # node dependencies (insightface, ultralytics, sam2) and first outputs
if [ $((need + headroom)) -gt "$free" ]; then
  status failed "not enough disk: need $(((need + headroom) / GB + 1)) GB, $((free / GB)) GB free; rent with a larger --disk"
  exit 1
fi
printf 'To download: %s GB of %s GB in models; %s GB free\n' "$(gb $need)" "$(gb $TOTAL_UNITS)" "$(gb "$free")"

status running 'installing system tools'
missing_apt=()
command -v aria2c >/dev/null || missing_apt+=(aria2)
command -v g++ >/dev/null || missing_apt+=(build-essential)  # insightface (Fix faces) builds from source
command -v git >/dev/null || missing_apt+=(git)
if [ ${#missing_apt[@]} -gt 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  (apt-get install -y -qq "${missing_apt[@]}" || (apt-get update -qq && apt-get install -y -qq "${missing_apt[@]}")) \
    >/dev/null 2>&1 || warn "apt could not install ${missing_apt[*]}"
fi

# Keep the image's CUDA build of torch (and numpy ABI) no matter what a requirements file asks for.
freeze() { if command -v uv >/dev/null; then uv pip freeze --python "$PY"; else "$PY" -m pip freeze; fi; }
freeze 2>/dev/null | grep -iE '^(torch|torchvision|torchaudio|numpy)==' > "$STATE_DIR/constraints.txt" || true
grep -qi '^torch==' "$STATE_DIR/constraints.txt" \
  || { status failed "could not read the installed torch version; refusing to risk replacing it"; exit 1; }
printf '  pinned: %s\n' "$(paste -sd' ' "$STATE_DIR/constraints.txt")"
export SAM2_BUILD_CUDA=0  # Impact-Pack's sam2 dependency: skip the optional CUDA extension build

# ---------------------------------------------------------------------------------------------------------------
index=0
for key in "${WORKFLOWS[@]}"; do
  index=$((index + 1))
  run_workflow "$key" "$index"
done

WF_TITLE=''
missing_optional=$(missing_types SpectrumApplyMiniMaxH3 2>/dev/null || true)
[ -z "$missing_optional" ] || printf 'Note: optional Spectrum acceleration is unavailable.\n'

trap - ERR
# Workflows queued while this ran: start over with these workflows plus the queued ones. Before the final status, so the
# monitor never sees "done" in between.
if [ -s "$QUEUE" ] && [ -f "$0" ]; then
  queued=$(tr '\n' ' ' < "$QUEUE"); rm -f "$QUEUE"
  printf '\nQueued workflows: %s\n' "$queued"
  status running "starting queued workflows: $queued"
  # shellcheck disable=SC2086  # the queued keys are words
  exec bash "$0" "${WORKFLOWS[@]}" $queued
fi
if [ ${#WARNINGS[@]} -eq 0 ]; then
  if [ "${WORKFLOWS[*]}" = "${ALL_WORKFLOWS[*]}" ]; then status done "all ${#WORKFLOWS[@]} workflows ready"
  else status done "$(ready_list) ready"; fi
else
  status warn "installed with ${#WARNINGS[@]} warning(s): ${WARNINGS[0]}"
  printf '\nWarnings:\n'; printf '  - %s\n' "${WARNINGS[@]}"
fi
printf '\nIn Genjutsu (Edit Image, Motion Control → MiniMax H3, Post-processing incl. Smooth motion, Video Upscaler), paste the ComfyUI link and press Check.\n'
if [ -s "$QUEUE" ]; then printf '\nQueued workflows (%s) need another run: this setup came from stdin.\n' "$(tr '\n' ' ' < "$QUEUE")"; fi

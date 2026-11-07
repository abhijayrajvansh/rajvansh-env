#!/usr/bin/env bash
# Genjutsu setup for Vast's ComfyUI image (rent-gpu image option 1).
# Installs what docs/minimax-h3-comfyui, docs/h3-post-processing and docs/qwen-image-edit need: MiniMax H3 motion
# control, Check mask, Fix faces, Fix colours and Edit Image (Qwen-Image 2.1 with both LoRAs).
# Resumable and safe to rerun; every model is sha256-checked. Models download in the order that makes each tab
# usable soonest; the status line lists the tabs that are ready so far.
#
# rent-gpu uploads and starts this automatically. By hand, from your Mac:
#   ssh -p PORT root@HOST 'bash -s' < rent-gpu-genjutsu.sh
# Progress: /workspace/.rent-gpu-setup/setup.log
# Status:   /workspace/.rent-gpu-setup/status, one line: state|message|ready tabs
# Env: COMFY_DIR, COMFY_PYTHON (defaults match vastai/comfy), HF_TOKEN for rate-limited downloads.
set -Eeuo pipefail

STATE_DIR=/workspace/.rent-gpu-setup
STATUS="$STATE_DIR/status"
COMFY=${COMFY_DIR:-${WORKSPACE:-/workspace}/ComfyUI}
PY=${COMFY_PYTHON:-/venv/main/bin/python}
COMFY_API=http://127.0.0.1:18188  # vastai/comfy's internal ComfyUI port (Caddy serves 8188)
MIN_COMFY=0.41.2
HF=https://huggingface.co
H3_REV=912b6e38b2092ec4d2e86d24183e0d59ea059d48

mkdir -p "$STATE_DIR"
exec 9>"$STATE_DIR/lock"
flock -n 9 || { echo 'Genjutsu setup is already running on this instance.'; exit 0; }

READY=()
ready_list() { local IFS=,; printf '%s' "${READY[*]:-}" | sed 's/,/, /g'; }
status() {
  printf '%s|%s|%s\n' "$1" "$2" "$(ready_list)" > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
  printf '\n==> %s\n' "$2"
}
WARNINGS=()
warn() { WARNINGS+=("$1"); printf 'WARNING: %s\n' "$1" >&2; }
trap 'status failed "failed at line $LINENO • see $STATE_DIR/setup.log"' ERR

# dir | git URL. Packs from both docs, plus Impact-Subpack so FaceRefine lists the YOLO detectors.
NODES=(
  "comfyui-h3-oneclick-swap|https://github.com/D3voz/comfyui-h3-oneclick-swap"
  "ComfyUI-MiniMaxH3-Context-Loop|https://github.com/ethanfel/ComfyUI-MiniMaxH3-Context-Loop"
  "ComfyUI-Fantastic-MiniMaxH3-PromptBuilder|https://github.com/Adudeguyman/ComfyUI-Fantastic-MiniMaxH3-PromptBuilder"
  "ComfyUI-KJNodes|https://github.com/kijai/ComfyUI-KJNodes"
  "ComfyUI-VideoHelperSuite|https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "ComfyUI-Spectrum-MiniMax-H3|https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3"
  "ComfyUI-H3-FaceRefine|https://github.com/Carasibana/ComfyUI-H3-FaceRefine"
  "ComfyUI-Impact-Pack|https://github.com/ltdrdata/ComfyUI-Impact-Pack"
  "ComfyUI-Impact-Subpack|https://github.com/ltdrdata/ComfyUI-Impact-Subpack"
  "comfyui-image-detail-contrast|https://github.com/D3voz/comfyui-image-detail-contrast"
  "Orion4D_FXMax|https://github.com/orion4d/Orion4D_FXMax"
)
# insightface (FaceRefine) needs an ONNX runtime it does not declare.
EXTRA_PIP=(onnxruntime-gpu)

# models/<folder> | URL (pinned revision) | bytes | sha256 | tab ready once this file is in.
# Filenames are Genjutsu's defaults (lib/h3-swap.ts, lib/server/qwen-edit-workflow.ts). Order = soonest usable tab:
# Check mask (1.7 GB) → Edit Image Turbo (+17 GB) → Motion control (+40 GB) → Fix faces → Edit Image Balanced, LoRAs.
Q21="$HF/Comfy-Org/Qwen-Image-2.1/resolve/aacf31a6d48e707f352ecba714cee0680da3479b"
MODELS=(
  "checkpoints|$HF/Comfy-Org/sam3.1/resolve/7bb8374780a725b4353ed31f3a9395c9742b5621/checkpoints/sam3.1_multiplex_fp16.safetensors|1745546848|9ba99c92703c2e8b4f47de2d34a539bb8e18923049e238b780d70dbe6368eb03|Check mask"
  "text_encoders|$Q21/text_encoders/qwen3vl_8b_int8_convrot.safetensors|9350798360|8bfd0f6e12abf2d2d697ecc888e5e90b0d6741d6708f05799f53afa560452e8f|"
  "diffusion_models|$Q21/diffusion_models/qwen_image_2.1_turbo_int8_convrot.safetensors|7256787829|8144a0182964aa8403ad6dbc011db837304167d235161b9aabaa8532e967314c|"
  "vae|$Q21/vae/qwen_image_2.1_vae_bf16.safetensors|675509688|bb21f7473051e1ac368515dd3f2e15cd44d7a11748ee8823e1ddca3e4876b7c9|Edit Image Turbo"
  "diffusion_models|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors|20970379616|9255f52b6677845ad238f20dfaafa94727053694127ab7f255c048f0f9365779|"
  "loras|$HF/Kijai/MiniMax-H3-experimental/resolve/f5c3b1d5a63e008a691fca1b6096fd57a5307536/loras/minimax_h3_DMAD_4step_full_lora_avg_rank_39_bf16.safetensors|366647000|ddfdd94f4c9a0f32bf3649bb8e98ca20db572e4db6bcd9cca546a5b33ea32d11|"
  "text_encoders|$HF/Abiray/MiniMax-H3-GGUF/resolve/9fc3454d3ebe1be1bade862cd4a5011f325a22cb/text_encoders/qwen3vl_32b_minimax_h3_int4_convrot.safetensors|14952506709|21fd2e2f06bc4fc422c6aa20893fe189edbbd9ab3068215f96e7a6cf2f6cb5bb|"
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/vae/minimax_h3_video_vae_int8_convrot.safetensors|2811065184|52a2c8c73583c86e4f41cdcce3a6ad0ea562987bc0bf3d60a0cef5f5c8e60c0e|"
  "vae|$HF/Comfy-Org/MiniMax-H3/resolve/$H3_REV/vae/minimax_h3_audio_vae_fp32.safetensors|605254808|8e505d95dd1561d47abd43d4238fd40d9bb1ae9e147ed0a4cba778d76ae4db48|Motion control"
  "ultralytics/bbox|$HF/Bingsu/adetailer/resolve/53cc19de382014514d9d4038601d261a7faa9b7b/face_yolov8m.pt|52026019|717923c19b3f4bbf5250b728f1fa6b2cb72a33aed1d236ea9caf0e21ad943e5f|"
  "ultralytics/segm|$HF/Bingsu/adetailer/resolve/53cc19de382014514d9d4038601d261a7faa9b7b/person_yolov8m-seg.pt|54827683|c8ab26f517173b1fe8342d336a09f443eb61cb08dcbfc78d53fff4c2547ae81e|"
  "sams|$HF/ybelkada/segment-anything/resolve/7790786db131bcdc639f24a915d9f2c331d843ee/checkpoints/sam_vit_b_01ec64.pth|375042383|ec2df62732614e57411cdcf32a23ffdf28910380d03139ee0f4fcbe91eb8c912|Fix faces"
  "diffusion_models|$Q21/diffusion_models/qwen_image_2.1_int8_convrot.safetensors|7256783064|cb74113cb03faecd79611b01fd7fd642f0aa60d6f0b95086abee214d75eaa57d|Edit Image Balanced/Best"
  "loras|$HF/ausboss/Qwen-Image-2.1-Consistency-LoRA/resolve/58897a02f4f60f88376eab5676738dd45e5ed1a2/qwen-image-2.1-consistency.safetensors|159436496|4f44ada1be2189cc23b3d010f9603543403f48454e2f76842a3d30109b20bd63|"
  "loras|$HF/Alissonerdx/BFS-Best-Face-Swap/resolve/2209ae537ac5e883d6ec7db5b7bd6dccf1a0eba7/bfs_head_v1.1_qwen_2.1.safetensors|260096144|d1d748d5601077f3b6d05766f6823510e901970d916afa404a97e85dc92fa88e|Edit Image LoRAs"
)

# Node types used by simple/mask/face/color.api.json and the Qwen edit graph, plus ones Genjutsu adds while editing.
REQUIRED_TYPES="AudioAdjustVolume BasicGuider BasicScheduler CLIPLoader CLIPTextEncode CheckpointLoaderSimple
ComfyMathExpression GrowMaskWithBlur H3ClipShots H3FaceChunks H3FaceJoin H3FaceMaskSAM H3FaceStitch H3FaceTrackCrop
H3FillShots H3GreyMannequins H3OneClickSwapPlan H3PeopleMask H3SoundtrackOrSilence H3SourceSlice ImageAndMaskPreview
ImageBlur ImageDetailContrast ImageFromBatch ImageScale ImageScaleToMaxDimension ImageStitch KSamplerSelect LoadImage
LoraLoaderModelOnly MaskComposite MiniMaxH3ChainAssemble MiniMaxH3ChainContext MiniMaxH3ChainCurrent
MiniMaxH3ChainLoopEnd MiniMaxH3ChainLoopStart MiniMaxH3ChainPlanModern MiniMaxH3ChainReview MiniMaxH3ChainSegmentSave
MiniMaxH3ContexMaskGridPreview MiniMaxH3ContexMaskedTarget MiniMaxH3FantasticVideoEditLatent
MiniMaxH3GenerationProfile MiniMaxH3LoopTrim MiniMaxH3ReferenceToVideo MiniMaxH3SigmaShift MiniMaxH3SourceTimeline
ModelAttentionBackend Orion4D_FXMax_DCTLToneMapper PreviewAny PreviewImage PrimitiveBoolean RandomNoise
SAM3_TrackToMask SAM3_VideoTrack SAMLoader SamplerCustomAdvanced StringConcatenate TextGenerate TrimAudioDuration
UNETLoader VAEDecode VAEDecodeAudio VAELoader VHS_LoadVideo VHS_SelectEveryNthImage VHS_VideoCombine
QwenImage21Cache TextEncodeQwenImage21 EmptyLatentImage KSampler ManualSigmas CFGGuider SaveImage"
OPTIONAL_TYPES="SpectrumApplyMiniMaxH3"

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
  status failed "ComfyUI ${version:-unknown} is too old; H3 needs $MIN_COMFY+. Rent with a newer vastai/comfy image."
  exit 1
fi
printf 'ComfyUI %s at %s\n' "$version" "$COMFY"

need=0
for entry in "${MODELS[@]}"; do
  IFS='|' read -r folder url bytes _ _ <<<"$entry"
  target="$COMFY/models/$folder/${url##*/}"
  [ -f "$target" ] && [ "$(stat -c %s "$target")" = "$bytes" ] || need=$((need + bytes))
done
mkdir -p "$COMFY/models"
free=$(df -PB1 "$COMFY/models" | awk 'NR==2 {print $4}')
headroom=$((8 * 1000000000))  # node dependencies (insightface, ultralytics, sam2) and first outputs
if [ $((need + headroom)) -gt "$free" ]; then
  status failed "not enough disk: need $(((need + headroom) / 1000000000 + 1)) GB, $((free / 1000000000)) GB free; rent with a larger --disk"
  exit 1
fi

status running 'installing system tools'
missing_apt=()
command -v aria2c >/dev/null || missing_apt+=(aria2)
command -v g++ >/dev/null || missing_apt+=(build-essential)  # insightface builds from source
command -v git >/dev/null || missing_apt+=(git)
if [ ${#missing_apt[@]} -gt 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  (apt-get install -y -qq "${missing_apt[@]}" || (apt-get update -qq && apt-get install -y -qq "${missing_apt[@]}")) \
    >/dev/null 2>&1 || warn "apt could not install ${missing_apt[*]}"
fi

count=0
for entry in "${NODES[@]}"; do
  IFS='|' read -r dir url <<<"$entry"
  count=$((count + 1))
  status running "custom nodes $count/${#NODES[@]} • $dir"
  path="$COMFY/custom_nodes/$dir"
  if [ -d "$path/.git" ]; then
    git -C "$path" pull --ff-only -q || warn "$dir: git pull failed; keeping $(git -C "$path" rev-parse --short HEAD)"
  elif [ -e "$path" ]; then
    warn "$dir exists but is not a git checkout; left as is"
  else
    git clone -q --depth 1 --recursive "$url" "$path"
  fi
  if [ -d "$path/.git" ]; then printf '  %s @ %s\n' "$dir" "$(git -C "$path" rev-parse --short HEAD)"; fi
done

status running 'installing Python packages for the custom nodes'
# Keep the image's CUDA build of torch (and numpy ABI) no matter what a requirements file asks for.
freeze() { if command -v uv >/dev/null; then uv pip freeze --python "$PY"; else "$PY" -m pip freeze; fi; }
freeze 2>/dev/null | grep -iE '^(torch|torchvision|torchaudio|numpy)==' > "$STATE_DIR/constraints.txt" || true
grep -qi '^torch==' "$STATE_DIR/constraints.txt" \
  || { status failed "could not read the installed torch version; refusing to risk replacing it"; exit 1; }
printf '  pinned: %s\n' "$(paste -sd' ' "$STATE_DIR/constraints.txt")"
pip_install() {
  if command -v uv >/dev/null; then
    uv pip install -q --python "$PY" -c "$STATE_DIR/constraints.txt" "$@"
  else
    "$PY" -m pip install -q --no-cache-dir -c "$STATE_DIR/constraints.txt" "$@"
  fi
}
export SAM2_BUILD_CUDA=0  # Impact-Pack's sam2 dependency: skip the optional CUDA extension build
for entry in "${NODES[@]}"; do
  IFS='|' read -r dir _ <<<"$entry"
  requirements="$COMFY/custom_nodes/$dir/requirements.txt"
  [ -f "$requirements" ] || continue
  printf '  %s/requirements.txt\n' "$dir"
  pip_install -r "$requirements" || warn "$dir: some Python requirements failed to install"
done
pip_install "${EXTRA_PIP[@]}" || warn "could not install ${EXTRA_PIP[*]}"

status running 'restarting ComfyUI to load the custom nodes'
if command -v supervisorctl >/dev/null; then
  supervisorctl restart comfyui >/dev/null || warn 'could not restart ComfyUI; restart it before checking'
else
  warn 'supervisorctl not found; restart ComfyUI yourself to load the custom nodes'
fi
READY+=("Fix colours")  # no model files

auth=()
[ -n "${HF_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $HF_TOKEN")
count=0
for entry in "${MODELS[@]}"; do
  IFS='|' read -r folder url bytes sha unlocks <<<"$entry"
  count=$((count + 1))
  name="${url##*/}"
  dir="$COMFY/models/$folder"
  target="$dir/$name"
  mkdir -p "$dir"
  if [ -f "$target" ] && [ "$(stat -c %s "$target")" = "$bytes" ]; then
    printf '✓ %s already installed\n' "$name"
    if [ -n "$unlocks" ]; then READY+=("$unlocks"); fi
    continue
  fi
  status running "models $count/${#MODELS[@]} • $name ($(awk "BEGIN {printf \"%.1f\", $bytes / 1e9}") GB)"
  if command -v aria2c >/dev/null; then
    # 16 connections: one connection to Hugging Face often caps near 30 MB/s.
    aria2c -x16 -s16 -k16M -c --file-allocation=none --max-tries=10 --retry-wait=5 \
      --console-log-level=warn --summary-interval=30 --download-result=hide \
      ${HF_TOKEN:+--header="Authorization: Bearer $HF_TOKEN"} -d "$dir" -o "$name.part" "$url"
  else
    curl -L --fail --retry 5 --retry-delay 5 -C - "${auth[@]}" -o "$target.part" "$url"
  fi
  [ "$(stat -c %s "$target.part")" = "$bytes" ] || { status failed "size mismatch for $name; rerun setup to resume"; exit 1; }
  printf '  verifying %s… ' "$name"
  if [ "$(sha256sum "$target.part" | cut -d' ' -f1)" != "$sha" ]; then
    rm -f "$target.part"
    status failed "checksum mismatch for $name (deleted); rerun setup"
    exit 1
  fi
  mv "$target.part" "$target"
  echo ok
  if [ -n "$unlocks" ]; then READY+=("$unlocks"); status running "$unlocks ready"; fi
done

status running 'checking ComfyUI loaded every node'
info="$STATE_DIR/object_info.json"
for _ in $(seq 60); do
  curl -sf --max-time 30 "$COMFY_API/object_info" -o "$info" && break
  sleep 5
done
if [ ! -s "$info" ]; then
  warn "ComfyUI did not answer on $COMFY_API; open it and press Check in Genjutsu"
else
  missing=$("$PY" - "$info" "$REQUIRED_TYPES" <<'PYTHON'
import json, sys
info = json.load(open(sys.argv[1]))
print(' '.join(t for t in sys.argv[2].split() if t not in info))
PYTHON
)
  optional=$("$PY" - "$info" "$OPTIONAL_TYPES" <<'PYTHON'
import json, sys
info = json.load(open(sys.argv[1]))
print(' '.join(t for t in sys.argv[2].split() if t not in info))
PYTHON
)
  [ -z "$missing" ] || warn "ComfyUI is missing node types: $missing (see ComfyUI's startup log)"
  [ -z "$optional" ] || printf 'Note: optional Spectrum acceleration is unavailable (%s).\n' "$optional"
fi

trap - ERR
if [ ${#WARNINGS[@]} -eq 0 ]; then
  status done "all tabs ready • ${#NODES[@]} node packs, ${#MODELS[@]} models verified"
else
  status warn "installed with ${#WARNINGS[@]} warning(s): ${WARNINGS[0]}"
  printf '\nWarnings:\n'; printf '  - %s\n' "${WARNINGS[@]}"
fi
printf '\nIn Genjutsu (Motion Control → MiniMax H3, Post-processing, Edit Image), paste the ComfyUI link and press Check.\n'

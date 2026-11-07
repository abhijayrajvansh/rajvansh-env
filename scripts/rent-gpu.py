#!/usr/bin/env python3
"""Rent-only Vast.ai GPU launcher (Genjutsu, Qwen, …). Needs python3, the `vastai` CLI and, for image 1,
rent-gpu-genjutsu.sh next to this script.

Rents immediately after an explicit numbered offer choice (re-checked for price/availability). Image 1 then installs
Genjutsu's nodes and models (MiniMax H3 motion control, post-processing, Qwen-Image 2.1 Edit Image) in the
background over SSH. Only the
monitor's explicit `kill` destroys a rental, `stop`/`start` pause/resume it, `comfy` recycles one to enable ComfyUI web
access, and `setup` (re)runs the Genjutsu installer.
"""
import argparse
import json
import math
import os
from pathlib import Path
import re
import select
import ssl
import subprocess
import sys
import threading
import time
from typing import Any
import unicodedata
import urllib.error
import urllib.request
import webbrowser

# All local data (SSH key registered on Vast, rental state) lives here; override with RENT_GPU_HOME.
ROOT = Path(os.environ.get('RENT_GPU_HOME') or Path.home() / '.config' / 'rent-gpu').expanduser()
STATE = ROOT / 'rentals'
SSH_KEY = ROOT / 'id_ed25519'
# Offer blocklist: hosts/offers with repeated container-start or SSH failures.
BLOCKED_OFFER_IDS = {'50584158'}
BLOCKED_HOST_IDS = {'155385'}  # RTX 5080/3090 container-start/SSH failures, 2026-10-29
BLOCKED_MACHINE_IDS: set[str] = set()
# H3 needs ComfyUI >= 0.41.2 and Qwen-Image 2.1 >= 0.44. CUDA 12.9 builds match --min-cuda's default.
COMFY_IMAGE = 'vastai/comfy:v0.44.0-cuda-12.9-py312'
# Setup presets: an installer started over SSH once the rental is up, plus rental defaults sized for it.
PRESETS: dict[str, dict[str, Any]] = {
    # ~67 GB of models (H3 ~51 GB + Qwen-Image 2.1 ~16 GB); int8 H3 streams weights from system RAM.
    # setup_gb: models + node packages fetched on the rental, for the per-offer setup cost estimate.
    'genjutsu': dict(script='rent-gpu-genjutsu.sh', title='Genjutsu', label='Genjutsu', disk=120, min_ram=64,
                     min_download=1000, setup_gb=70,
                     # Slow disks take many minutes to unpack the ~10 GB image before the container even boots.
                     min_disk_speed=2500,
                     max_setup_cost=0.30),  # bandwidth + GPU time to download the models, in USD
}
PRESET_ALIASES = {'genjutsu-h3': 'genjutsu'}  # rentals saved before Qwen-Image 2.1 joined the preset
DEFAULT_SETUP = 'genjutsu'
DEFAULTS = dict(label='Qwen', disk=60, min_ram=32, min_download=500, min_disk_speed=1000, max_setup_cost=None)
# Hugging Face rarely serves one file faster than ~300 MB/s even over 16 connections; real throughput ≈ 80% of the line.
HF_CAP_MBPS = 2400
NET_EFFICIENCY = 0.8
IMAGES: list[tuple[str, str, str | None]] = [
    ('ComfyUI + Genjutsu — H3 motion control, Check mask, Fix faces, Fix colours,\n'
     '     Edit Image (Qwen-Image 2.1 + consistency/BFS LoRAs)\n'
     '     installs nodes + ~67 GB of models automatically • 120 GB disk, ≥64 GB RAM', COMFY_IMAGE, 'genjutsu'),
    ('ComfyUI (stock, no models preinstalled)', COMFY_IMAGE, None),
    ('Ubuntu 24.04 + Python 3.12 (bare; install vLLM / Transformers yourself)',
     'vastai/base-image:stock-ubuntu24.04-py312-2026-10-23', None),
]
SETUP_DIR = '/workspace/.rent-gpu-setup'
# (public port, internal app port, portal name) for Vast's own images.
PORTALS = {
    'comfy': [(1111, 11111, 'Instance Portal'), (8188, 18188, 'ComfyUI'), (8080, 18080, 'Jupyter')],
    'base': [(1111, 11111, 'Instance Portal'), (8080, 18080, 'Jupyter')],
}
NUMERIC = ('id', 'dph_total', 'gpu_ram', 'cpu_ram', 'disk_space', 'inet_down', 'inet_down_cost',
           'inet_up_cost', 'reliability', 'direct_port_count')


def vast(*args: str) -> Any:
    result = subprocess.run(['vastai', *args, '--raw'], capture_output=True, text=True, timeout=120)
    if result.returncode:
        raise RuntimeError(f'Vast CLI `{" ".join(args[:2])}` failed (exit {result.returncode}). '
                           'Check login/network; nothing was rented.')
    raw = result.stdout
    start = min((i for i in (raw.find('['), raw.find('{')) if i >= 0), default=-1)
    if start < 0:
        raise RuntimeError('Unrecognized Vast CLI output; nothing was rented.')
    return json.JSONDecoder().raw_decode(raw[start:])[0]


def finite(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def offer_allowed(row: dict[str, Any]) -> bool:
    """Reject blocklisted offers/hosts/machines and offers with an unknown download rate."""
    if (str(row.get('id')) in BLOCKED_OFFER_IDS or str(row.get('host_id')) in BLOCKED_HOST_IDS
            or str(row.get('machine_id')) in BLOCKED_MACHINE_IDS):
        return False
    rate = row.get('inet_down_cost')
    return finite(rate) and rate >= 0


def ssh_candidates(instance: dict[str, Any]) -> list[tuple[str, int]]:
    """Prefer live direct mappings; proxy SSH is the fallback, not a cached endpoint."""
    ports = instance.get('ports') or {}
    if isinstance(ports, str):
        ports = json.loads(ports)
    candidates: list[tuple[Any, Any]] = []
    if isinstance(ports, dict):
        mappings = ports.get('22/tcp') or []
        if isinstance(mappings, list):
            candidates.extend((instance.get('public_ipaddr'), mapping.get('HostPort'))
                              for mapping in mappings if isinstance(mapping, dict))
    candidates.append((instance.get('ssh_host'), instance.get('ssh_port')))
    result: list[tuple[str, int]] = []
    for host, raw_port in candidates:
        if not isinstance(host, str) or not re.fullmatch(r'[A-Za-z0-9.:-]+', host):
            continue
        try:
            port = int(raw_port)
        except (TypeError, ValueError):
            continue
        if not isinstance(raw_port, bool) and 1 <= port <= 65535 and (host, port) not in result:
            result.append((host, port))
    return result


def eligible(row: Any, opts: argparse.Namespace) -> bool:
    if not isinstance(row, dict) or any(not finite(row.get(k)) or row[k] < 0 for k in NUMERIC):
        return False
    cuda = row.get('cuda_max_good', row.get('cuda_vers'))
    return (offer_allowed(row) and isinstance(row.get('gpu_name'), str)
            and row.get('num_gpus') == opts.gpus and row.get('rentable') and not row.get('rented')
            and row.get('gpu_arch') == 'nvidia' and row.get('cpu_arch') == 'amd64'
            and finite(cuda) and cuda >= opts.min_cuda
            and finite(row.get('compute_cap')) and row['compute_cap'] >= opts.min_compute * 100
            and row['gpu_ram'] >= opts.min_vram * 1000 and row['cpu_ram'] >= opts.min_ram * 1000 and row['disk_space'] >= opts.disk
            and row['reliability'] >= opts.reliability and row['inet_down'] >= opts.min_download
            and finite(row.get('disk_bw')) and row['disk_bw'] >= opts.min_disk_speed
            and row['direct_port_count'] >= 1)


def search(opts: argparse.Namespace, gpu: str | None = None, offer_id: int | None = None) -> list[dict[str, Any]]:
    query = (f'num_gpus={opts.gpus} rentable=true rented=false gpu_arch=nvidia cpu_arch=amd64 '
             f'gpu_ram>={opts.min_vram} cpu_ram>={opts.min_ram} disk_space>={opts.disk} cuda_vers>={opts.min_cuda} '
             f'reliability>={opts.reliability} inet_down>={opts.min_download} disk_bw>={opts.min_disk_speed} '
             'inet_down_cost>=0 inet_up_cost>=0 direct_port_count>=1 duration>=1')
    if gpu:
        query += ' gpu_name=' + gpu.replace(' ', '_')
    if offer_id:
        query += f' ask_contract_id={offer_id}'
    rows = vast('search', 'offers', query, '--no-default', '--type', 'on-demand',
                '--storage', str(opts.disk), '--order', 'dph_total', '--limit', '10000')
    if not isinstance(rows, list):
        raise RuntimeError('Unrecognized offer listing; nothing was rented.')
    rows = [r for r in rows if eligible(r, opts) and (not gpu or r['gpu_name'] == gpu)]
    if getattr(opts, 'setup_gb', None) and opts.max_setup_cost is not None:
        rows = [r for r in rows if sum(setup_cost(r, opts.setup_gb)[:2]) <= opts.max_setup_cost]
    return sorted(rows, key=lambda r: (r['dph_total'], r['inet_down_cost'], r['id']))


ANSI = re.compile(r'\033\[[0-9;]*m')


def paint_text(text: str, code: str) -> str:
    return f'\033[{code}m{text}\033[0m' if sys.stdout.isatty() and 'NO_COLOR' not in os.environ else text


def green(text: str) -> str:
    return paint_text(text, '1;32')


def bold(text: str) -> str:
    return paint_text(text, '1')


def dim(text: str) -> str:
    return paint_text(text, '2')


def cyan(text: str) -> str:
    return paint_text(text, '36')


def yellow(text: str) -> str:
    return paint_text(text, '33')


def text_width(text: str) -> int:
    """Terminal columns used by text, ignoring color codes and counting wide glyphs as two."""
    return sum(0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in 'WF' else 1
               for c in ANSI.sub('', text))


def field(label: str, value: str, size: int = 9) -> str:
    return dim(label.ljust(size)) + ' ' + value


REFRESH = -1


def ask_number(prompt: str, count: int, refresh: bool = False) -> int | None:
    extra = ', r refreshes' if refresh else ''
    while True:
        answer = input(f'{prompt} [1–{count}{extra}, Enter cancels]: ').strip()
        if not answer:
            return None
        if refresh and answer.lower() in ('r', 'refresh'):
            return REFRESH
        if answer.isdigit() and 1 <= int(answer) <= count:
            return int(answer) - 1
        print('Choose a listed number' + (', r to refresh' if refresh else '') + ', or press Enter to cancel.')


def load_state(instance_id: int) -> dict[str, Any]:
    state = json.loads((STATE / f'{instance_id}.json').read_text())
    if state.get('setup') in PRESET_ALIASES:
        state['setup'] = PRESET_ALIASES[state['setup']]
    return state


def preset_script(name: str) -> Path:
    path = Path(__file__).resolve().parent / PRESETS[name]['script']
    if not path.is_file():
        raise RuntimeError(f'Setup script missing: {path}. Nothing was rented.')
    return path


def apply_defaults(opts: argparse.Namespace, preset: str | None) -> None:
    """Explicit flags win; otherwise the preset's sizing, then the general defaults."""
    for key, value in DEFAULTS.items():
        if getattr(opts, key) is None:
            setattr(opts, key, PRESETS[preset].get(key, value) if preset else value)
    opts.setup_gb = PRESETS[preset].get('setup_gb') if preset else None


def choose_image(opts: argparse.Namespace) -> tuple[str | None, str | None]:
    """Returns (image, setup preset)."""
    if opts.setup:
        preset_script(opts.setup)
        return opts.image or COMFY_IMAGE, opts.setup
    if opts.image:
        return opts.image, None
    print('\nContainer image:')
    for index, (label, image, _) in enumerate(IMAGES, 1):
        print(f'  {index}) {label}\n     {dim(image)}')
    print(f'  {len(IMAGES) + 1}) Custom Docker image')
    choice = ask_number('Choose image', len(IMAGES) + 1)
    if choice is None:
        return None, None
    if choice < len(IMAGES):
        _, image, preset = IMAGES[choice]
        if preset:
            preset_script(preset)
        return image, preset
    image = input('Docker image (e.g. vllm/vllm-openai:latest): ').strip()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._/:@-]*', image):
        raise RuntimeError('Invalid image name; nothing was rented.')
    return image, None


def choose_gpu(opts: argparse.Namespace) -> tuple[str | None, list[dict[str, Any]]]:
    print('\nFetching live Vast.ai offers…', flush=True)
    rows = search(opts)
    cheapest: dict[str, dict[str, Any]] = {}
    counts: dict[str, int] = {}
    for row in rows:
        name = row['gpu_name']
        counts[name] = counts.get(name, 0) + 1
        cheapest.setdefault(name, row)
    names = sorted(cheapest, key=lambda n: (cheapest[n]['dph_total'], n.casefold()))
    if not names:
        print('No offers match these filters. Nothing was rented.')
        return None, []
    print(f'\nGPU models (≥{opts.min_vram} GB VRAM, ≥{opts.min_ram} GB RAM, {opts.disk} GB disk priced in, '
          f'disk ≥{opts.min_disk_speed:,} MB/s, ↓ ≥{opts.min_download:,} Mbps'
          + (f', setup ≤ ${opts.max_setup_cost:.2f}' if getattr(opts, 'setup_gb', None) and opts.max_setup_cost is not None
             else '') + ', cheapest first):\n')
    for index, name in enumerate(names, 1):
        row = cheapest[name]
        price = green(f"${row['dph_total']:.4f}/hour")
        print(f"{index:>2}. {name:<22} {price}  {row['gpu_ram'] / 1024:5.1f} GB VRAM  • {counts[name]} offer(s)")
    print()
    choice = ask_number('Choose GPU', len(names))
    if choice is None:
        return None, []
    gpu = names[choice]
    return gpu, [r for r in rows if r['gpu_name'] == gpu][:opts.top]


def disk_speed(row: dict[str, Any]) -> str:
    speed = row.get('disk_bw')
    return f'{speed:,.0f} MB/s' if finite(speed) and speed > 0 else 'unknown speed'


def setup_cost(row: dict[str, Any], gigabytes: float) -> tuple[float, float, float]:
    """(bandwidth $, GPU-time $, minutes) to download a setup's models on this offer."""
    mbps = min(row['inet_down'], HF_CAP_MBPS) * NET_EFFICIENCY
    seconds = gigabytes * 8000 / mbps if mbps > 0 else math.inf
    return row['inet_down_cost'] * gigabytes, row['dph_total'] * seconds / 3600, seconds / 60


def show_offers(rows: list[dict[str, Any]], disk: int, setup_gb: float | None = None) -> None:
    if setup_gb:
        print(dim(f'\nSetup = downloading ~{setup_gb:.0f} GB of models: bandwidth + GPU time while it downloads '
                  f'(estimate; Hugging Face caps near {HF_CAP_MBPS // 8} MB/s).'))
    print()
    for index, row in enumerate(rows, 1):
        verified = {'verified': green('✓ Verified'),
                    # Vast revoked this host's verification (failed checks); riskier than never verified.
                    'deverified': paint_text('✗ Deverified', '1;31')}.get(str(row.get('verification')),
                                                                         yellow('! Unverified'))
        cuda = row.get('cuda_max_good', row.get('cuda_vers'))
        sep = dim(' · ')
        header = sep.join([green(f"${row['dph_total']:.4f}/hr"), bold(row.get('geolocation') or 'unknown'),
                           verified, f"{row['reliability']:.1%} reliable"])
        details = [
            ('GPU', sep.join([f"{row['num_gpus']}× {bold(row['gpu_name'])}",
                              f"{row['gpu_ram'] / 1024:.1f} GB VRAM", f'CUDA {cuda}'])),
            ('Host', sep.join([f"{float(row.get('cpu_cores_effective') or 0):.0f} CPU cores",
                               f"{row['cpu_ram'] / 1024:.1f} GB RAM"])),
            ('Storage', sep.join(part for part in [
                f'{bold(f"{disk} GB")} rented',
                ' '.join(part for part in [
                    green(f"${row['storage_total_cost']:.4f}/hr") if finite(row.get('storage_total_cost')) else '',
                    dim(f"(${row['storage_total_cost'] * 730:.2f}/mo)") if finite(row.get('storage_total_cost'))
                    else dim(f"(${row['storage_cost'] * disk:.2f}/mo)") if finite(row.get('storage_cost')) else '',
                ] if part),
            ] if part)),
            ('Disk', sep.join(part for part in [
                cyan(disk_speed(row)),
                dim(str(row.get('disk_name')).replace('_', ' ')) if row.get('disk_name') else '',
            ] if part)),
            ('Net', sep.join([f"↓ {row['inet_down']:.0f} Mbps " + dim(f"(${row['inet_down_cost'] * 1000:.2f}/TB)"),
                              f"↑ {float(row.get('inet_up') or 0):.0f} Mbps "
                              + dim(f"(${row['inet_up_cost'] * 1000:.2f}/TB)")])),
            ('Offer', dim(str(row['id']))),
        ]
        if setup_gb:
            bandwidth, gpu_time, minutes = setup_cost(row, setup_gb)
            details.insert(-1, ('Setup', sep.join([
                bold(green(f'≈ ${bandwidth + gpu_time:.2f}')),
                f'${bandwidth:.2f} download' + dim(f" (${row['inet_down_cost'] * 1000:.2f}/TB)"),
                f'${gpu_time:.2f} GPU' + dim(f' (~{minutes:.0f} min)'),
            ])))
        print(f' {cyan(bold(f"{index:>2}"))}  {header}')
        for n, (label, value) in enumerate(details):
            print(f"     {dim('└' if n == len(details) - 1 else '├')} {field(label, value, 7)}")
        print()


def wait_for_ssh(instance_id: int, timeout: int) -> dict[str, Any] | None:
    started = time.monotonic()
    deadline = started + timeout
    last = ''
    live = sys.stdout.isatty()
    while time.monotonic() < deadline:
        try:
            data = vast('show', 'instance', str(instance_id))
            data = data[0] if isinstance(data, list) and data else data
        except (RuntimeError, ValueError, subprocess.TimeoutExpired):
            data = {}
        status = ' '.join(str(data.get('status_msg') or data.get('actual_status') or 'starting').split())[:120]
        if status != last:
            print(('\n' if live and last else '') + f'  {time.strftime("%H:%M:%S")} {status}',
                  end='' if live else '\n', flush=True)
            last = status
        elif live:  # same status: keep a ticking timer so a slow image download does not look frozen
            hint = ' (first boot downloads the ~10 GB image)' if status == 'starting' else ''
            print(f'\r  {time.strftime("%H:%M:%S")} {status} ' + dim(f'• {clock(time.monotonic() - started)}{hint}'),
                  end='', flush=True)
        if data.get('actual_status') == 'running' and ssh_candidates(data):
            if live:
                print()
            return data
        time.sleep(5)
    if live:
        print()
    return None


def save_state(instance_id: int, data: dict[str, Any]) -> Path:
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = STATE / f'{instance_id}.json'
    path.write_text(json.dumps(data, indent=2) + '\n')
    path.chmod(0o600)
    return path


def image_kind(image: str) -> str:
    """Vast's own images start their web portal; custom images get plain SSH only."""
    if image.startswith('vastai/comfy'):
        return 'comfy'
    return 'base' if image.startswith(('vastai/base-image', 'vastai/pytorch')) else 'custom'


def portal_env(image: str) -> dict[str, str]:
    """Docker env/ports matching Vast's official ComfyUI template (no provisioning downloads)."""
    portals = PORTALS.get(image_kind(image))
    if not portals:
        return {}
    env = {f'-p {port}:{port}': '1' for port, _, _ in portals}
    env.update(OPEN_BUTTON_PORT='1111', OPEN_BUTTON_TOKEN='1', JUPYTER_DIR='/', DATA_DIRECTORY='/workspace/',
               PORTAL_CONFIG='|'.join(f'localhost:{port}:{internal}:/:{name}' for port, internal, name in portals))
    if image_kind(image) == 'comfy':
        # PyTorch attention: the image's xformers build cannot run on Blackwell (RTX 5090); H3 needs this there.
        env['COMFYUI_ARGS'] = '--disable-auto-launch --port 18188 --enable-cors-header --use-pytorch-cross-attention'
    return env


def launch_args(image: str) -> list[str]:
    env = portal_env(image)
    if not env:
        return ['--ssh', '--direct']
    text = ' '.join(key if key.startswith('-p ') else f'-e {key}="{value}"' for key, value in env.items())
    # entrypoint.sh starts Vast's portal, Caddy token auth, Cloudflare tunnels and ComfyUI.
    return ['--jupyter', '--ssh', '--direct', '--onstart-cmd', 'entrypoint.sh', '--env', text]


def instance(instance_id: int) -> dict[str, Any]:
    data = vast('show', 'instance', str(instance_id))
    data = data[0] if isinstance(data, list) and data else data
    if not isinstance(data, dict) or data.get('id') != instance_id:
        raise RuntimeError(f'Instance {instance_id} not found on Vast.')
    return data


def host_port(info: dict[str, Any], port: int) -> str | None:
    ports = info.get('ports') or {}
    mapping = ports.get(f'{port}/tcp') if isinstance(ports, dict) else None
    return str(mapping[0].get('HostPort')) if mapping and isinstance(mapping[0], dict) else None


def ssh_run(info: dict[str, Any], command: str, stdin_text: str | None = None, timeout: int = 25) -> str | None:
    """Run a command over the first working direct/proxy SSH endpoint, optionally feeding it stdin."""
    feed: dict[str, Any] = {'stdin': subprocess.DEVNULL} if stdin_text is None else {'input': stdin_text}
    for host, port in ssh_candidates(info):
        try:
            result = subprocess.run(
                ['ssh', '-i', str(SSH_KEY), '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
                 '-o', 'ConnectTimeout=6', '-o', 'StrictHostKeyChecking=accept-new', '-o', 'LogLevel=ERROR',
                 '-p', str(port), f'root@{host}', command],
                capture_output=True, text=True, timeout=timeout, **feed)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if result.returncode == 0:
            return result.stdout
    return None


def tunnels(info: dict[str, Any]) -> dict[int, str]:
    """Cloudflare quick-tunnel URLs created by Vast's tunnel manager, keyed by portal port."""
    output = ssh_run(info, 'curl -s --max-time 5 http://127.0.0.1:11112/get-all-quick-tunnels')
    start = output.find('[') if output else -1
    if start < 0:
        return {}
    try:
        rows = json.JSONDecoder().raw_decode(output[start:])[0]  # type: ignore[index]
    except ValueError:
        return {}
    result = {}
    for row in rows if isinstance(rows, list) else []:
        target = re.fullmatch(r'http://localhost:(\d+)', str(row.get('targetUrl')))
        url = str(row.get('tunnelUrl'))
        if target and re.fullmatch(r'https://[a-z0-9-]+\.trycloudflare\.com', url):
            result[int(target[1])] = url
    return result


def start_setup(instance_id: int, info: dict[str, Any], preset: str, attempts: int = 12) -> bool:
    """Upload the preset's installer and start it detached (it survives SSH disconnects; rerunning resumes)."""
    script = preset_script(preset).read_text()
    command = (f'mkdir -p {SETUP_DIR} && cat > {SETUP_DIR}/setup.sh && '
               f'{{ nohup setsid bash {SETUP_DIR}/setup.sh >> {SETUP_DIR}/setup.log 2>&1 < /dev/null & }} '
               '&& echo started')
    for attempt in range(attempts):
        if (ssh_run(info, command, stdin_text=script, timeout=40) or '').strip() == 'started':
            return True
        if attempt + 1 < attempts:  # sshd often accepts connections a little after Vast reports "running"
            time.sleep(10)
            try:
                info = instance(instance_id)
            except (RuntimeError, ValueError, OSError, subprocess.SubprocessError):
                pass
    return False


def setup_status(info: dict[str, Any]) -> str | None:
    """'state|message' from the installer; 'missing|' if it never ran; None if SSH failed."""
    output = ssh_run(info, f'cat {SETUP_DIR}/status 2>/dev/null || true')
    if output is None:
        return None
    return output.strip().splitlines()[-1] if output.strip() else 'missing|'


def http_status(url: str) -> int | None:
    context = ssl.create_default_context()
    context.check_hostname, context.verify_mode = False, ssl.CERT_NONE
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(),
                                         urllib.request.HTTPSHandler(context=context))
    try:
        with opener.open(url, timeout=8) as response:
            return int(response.status)
    except urllib.error.HTTPError as error:
        return error.code
    except (OSError, ValueError):
        return None


def web_links(info: dict[str, Any], image: str, tunnel_urls: dict[int, str]) -> list[str]:
    token = info.get('jupyter_token')
    lines = []
    for port, _, name in PORTALS.get(image_kind(image), []):
        if port in tunnel_urls and token:
            lines.append('  ' + field(name, cyan(f'{tunnel_urls[port]}/?token={token}'), 16))
    return lines


def section(title: str) -> str:
    return '\n' + bold(title)


def print_access(instance_id: int, info: dict[str, Any], image: str, preset: str | None = None) -> None:
    key = f'-i "{SSH_KEY}" ' if SSH_KEY.exists() else ''
    title = f' GPU instance {instance_id} '
    print('\n' + dim('━━') + bold(title) + dim('━' * max(4, 62 - len(title))))
    print('  ' + field('Image', image))
    print('  ' + field('Console', cyan('https://cloud.vast.ai/instances/')))
    print('  ' + field('Reopen', f'rent-gpu -m {instance_id}'))
    # Direct host-IP links are omitted: many networks (including this Mac's) cannot reach them.
    print(section('SSH'))
    candidates = ssh_candidates(info)
    for host_name, port in candidates:
        print('  ' + dim('›') + f' ssh {key}-p {port} root@{host_name}')
    if preset and candidates:
        host_name, port = candidates[0]
        print(section(f"{PRESETS[preset]['title']} setup log"))
        print('  ' + dim('›') + f' ssh {key}-p {port} root@{host_name} tail -f {SETUP_DIR}/setup.log')


def enable_web(instance_id: int, image: str) -> None:
    """Explicit `comfy` command: apply portal settings and recycle (recreates the container)."""
    env = portal_env(image)
    if not env:
        raise RuntimeError('Web access is only available for Vast ComfyUI/base images.')
    result = vast('update', 'instance', str(instance_id), '--image', image, '--env', json.dumps(env),
                  '--onstart', 'entrypoint.sh')
    if not isinstance(result, dict) or not result.get('success'):
        raise RuntimeError(f'Vast refused the update: {result}')
    subprocess.run(['vastai', 'recycle', 'instance', str(instance_id)], check=True,
                   stdout=subprocess.DEVNULL, timeout=120)


def is_stopped(info: dict[str, Any]) -> bool:
    return info.get('intended_status') == 'stopped' or info.get('cur_state') == 'stopped'


def set_power(instance_id: int, action: str) -> None:
    """Explicit `stop`/`start`. Stopped keeps the disk (storage still bills); start needs the GPU to be free."""
    result = subprocess.run(['vastai', action, 'instance', str(instance_id), '--raw'],
                            capture_output=True, text=True, timeout=60)
    output = (result.stdout + result.stderr).strip()
    if result.returncode or '"error"' in output or 'failed' in output.lower():
        raise RuntimeError(f'Vast refused `{action}`: {output or f"exit {result.returncode}"}')


def track_pause(instance_id: int, state: dict[str, Any], stopped: bool) -> None:
    """Record stopped periods locally (Vast exposes no stop time) so the cost estimate drops GPU billing."""
    now = time.time()
    if stopped and not finite(state.get('stopped_at')):
        state['stopped_at'] = now
    elif not stopped and finite(state.get('stopped_at')):
        state['paused_seconds'] = float(state.get('paused_seconds') or 0) + now - state.pop('stopped_at')
    else:
        return
    save_state(instance_id, state)


def clock(seconds: float) -> str:
    hours, rest = divmod(int(max(0.0, seconds)), 3600)
    return f'{hours:02d}:{rest // 60:02d}:{rest % 60:02d}'


def destroy(instance_id: int) -> None:
    """Destroy only this tracked rental after an explicit `kill`, then verify it is gone."""
    path = STATE / f'{instance_id}.json'
    state = json.loads(path.read_text())
    live = vast('show', 'instances')
    if not isinstance(live, list):
        raise RuntimeError('Cannot verify live rentals; nothing destroyed.')
    row = next((r for r in live if r.get('id') == instance_id), None)
    if row and row.get('label') != state.get('label'):
        raise RuntimeError('Live label differs from the tracked rental; refusing to destroy.')
    if row:
        print(f'\nDestroying instance {instance_id}…', flush=True)
        subprocess.run(['vastai', 'destroy', 'instance', str(instance_id), '-y', '--raw'],
                       check=True, stdout=subprocess.DEVNULL, timeout=60)
        for _ in range(30):
            if not any(r.get('id') == instance_id for r in vast('show', 'instances')):
                break
            time.sleep(1)
        else:
            raise RuntimeError('Deletion not yet confirmed; check Vast before assuming billing stopped.')
    state.update(status='destroyed', destroyed_at=time.time())
    save_state(instance_id, state)
    print(f'Instance {instance_id} destroyed and deletion verified.', flush=True)
    url = 'https://cloud.vast.ai/instances/'
    try:
        if not webbrowser.open(url):
            print('Open ' + url)
    except (OSError, webbrowser.Error):
        print('Open ' + url)


def monitor(instance_id: int) -> None:
    """Live cost/time/GPU box with ComfyUI links. `stop`/`start` pause/resume; `kill` destroys; `comfy` enables web."""
    state = load_state(instance_id)
    image = state.get('image', '')
    kind = image_kind(image)
    info: dict[str, Any] = {}
    tunnel_urls: dict[int, str] = {}
    comfy = 'checking…'
    setup_line = 'running|checking…' if state.get('setup') else ''
    setup_checked = 0.0
    lock = threading.Lock()
    stop = threading.Event()
    wake = threading.Event()
    first = threading.Event()

    def poll() -> None:
        nonlocal info, tunnel_urls, comfy, setup_line, setup_checked
        last_tunnels = 0.0
        while not stop.is_set():
            try:
                fresh = instance(instance_id)
                stopped = is_stopped(fresh)
                with lock:
                    track_pause(instance_id, state, stopped)
                # Quick tunnels die with the container; a restart creates new URLs.
                found = {} if stopped else tunnel_urls
                if not stopped and kind != 'custom' and host_port(fresh, 1111) and (
                        not found or time.monotonic() - last_tunnels > 60):
                    found = tunnels(fresh) or found
                    last_tunnels = time.monotonic()
                status = comfy
                if kind == 'comfy':
                    if stopped:
                        status = 'stopped • type start + Enter to resume'
                    elif fresh.get('actual_status') != 'running':
                        status = 'instance starting…'
                    elif not host_port(fresh, 8188):
                        status = 'web access off • type comfy + Enter to enable'
                    elif 8188 not in found:
                        status = 'starting • waiting for Cloudflare link…'
                    else:
                        code = http_status(f"{found[8188]}/?token={fresh.get('jupyter_token')}")
                        status = 'ready • open the link above' if code == 200 else f'starting (HTTP {code or "no reply"})'
                with lock:
                    preset, line, checked = state.get('setup'), setup_line, setup_checked
                finished = line.startswith(('done|', 'warn|', 'failed|'))
                if (preset and not stopped and fresh.get('actual_status') == 'running'
                        and time.monotonic() - checked > (120 if finished else 15)):
                    line = setup_status(fresh) or line
                    checked = time.monotonic()
                with lock:
                    info, tunnel_urls, comfy = fresh, found, status
                    if checked > setup_checked:  # a `setup` command meanwhile wins over this older read
                        setup_line, setup_checked = line, checked
            except (RuntimeError, ValueError, OSError, subprocess.SubprocessError):
                with lock:
                    info = {}
            first.set()
            wake.wait(10)
            wake.clear()

    def stopped_now() -> bool:
        with lock:
            return bool(info) and is_stopped(info)

    def header() -> str:
        with lock:
            data, found = dict(info), dict(tunnel_urls)
        links = web_links(data, image, found) if data else []
        if kind == 'custom':
            return ''
        if data and is_stopped(data):
            return section('Web links') + '\n  ' + dim('offline while the instance is stopped')
        if not links:
            return section('Web links') + '\n  ' + yellow('waiting for Vast\'s Cloudflare tunnels…')
        return section('Web links') + ' ' + dim('(Cloudflare, token included)') + '\n' + '\n'.join(links)

    def state_dot(text: str, ok: bool) -> str:
        return (green('●') if ok else yellow('●')) + ' ' + text

    def progress(percent: str, extra: str = '') -> str:
        """'42' → '████░░░░░░ 42% done · 58% left'."""
        done = max(0, min(100, int(percent)))
        bar = green('█' * (done // 10)) + dim('░' * (10 - done // 10))
        return f'{bar} {done}% done · {100 - done}% left' + (dim(f' · {extra}') if extra else '')

    def setup_text(line: str) -> tuple[str, bool]:
        phase, _, rest = line.partition('|')
        message = rest.partition('|')[0]
        if phase == 'missing':
            return 'not installed • type setup + Enter', False
        if phase == 'failed':
            return f'failed: {message} • type setup to retry', False
        if phase == 'warn':
            return message + ' • see the setup log', False
        return message or phase, phase == 'done'

    def rows() -> list[str]:
        with lock:
            data, comfy_status, setup_now = dict(info), comfy, setup_line
            raw_stop = state.get('stopped_at')
            paused = float(state.get('paused_seconds') or 0)
        now = time.time()
        stopped = bool(data) and is_stopped(data)
        starts = [t for t in (data.get('start_date'), state.get('created_at')) if finite(t)]
        raw_rate = data.get('dph_total') if finite(data.get('dph_total')) else state.get('hourly_usd')
        hourly = float(raw_rate) if finite(raw_rate) else None
        storage = float(data['storage_total_cost']) if finite(data.get('storage_total_cost')) else 0.0
        stopped_at = float(raw_stop) if finite(raw_stop) else None
        elapsed = max(0.0, now - min(starts)) if starts else 0.0
        if stopped_at is not None:
            paused += now - stopped_at
        cost = '$unknown'
        if hourly is not None:  # dph_total = GPU + storage; while stopped only storage bills.
            cost = f'${(elapsed * hourly - min(paused, elapsed) * (hourly - storage)) / 3600:.4f}'
        if hourly is None:
            rate = 'rate unknown'
        elif stopped:
            rate = f'${storage:.4f}/h storage only'
        else:
            rate = f'${hourly:.4f}/h'
        uptime = clock(elapsed) + (dim(f' • stopped for {clock(now - stopped_at)}')
                                   if stopped and stopped_at is not None else '')
        lines = [field('Cost', green(cost) + dim('  est., network excluded')), field('Uptime', uptime)]
        if stopped:
            lines += [field('Status', state_dot('stopped', False) + dim(f" • {state.get('gpu')} • {rate}")),
                      field('GPU', dim('off • type start + Enter to resume')),
                      field('RAM', dim('off'))]
        elif data:
            status = str(data.get('actual_status') or 'unknown')
            gpu = (f"{float(data.get('gpu_util') or 0):.0f}% util  {float(data.get('gpu_temp') or 0):.0f}°C  "
                   f"VRAM {float(data.get('vmem_usage') or 0):.1f} GB")
            lines += [field('Status', state_dot(status, status == 'running') + dim(f" • {state.get('gpu')} • {rate}")),
                      field('GPU', gpu),
                      field('RAM', f"{float(data.get('mem_usage') or 0):.1f} / "
                                   f"{float(data.get('mem_limit') or 0):.1f} GB")]
        if data:
            used, total = float(data.get('disk_usage') or 0), float(data.get('disk_space') or 0)
            percent = used / total * 100 if total else 0
            usage = f'{percent:.0f}% used'
            lines.append(field('Disk', f'{used:.1f} / {total:.1f} GB  '
                                       + (yellow(usage) if percent >= 85 else dim(usage))))
        else:
            lines += [field('Status', yellow('unavailable (Vast query failed or pending)')),
                      field('GPU', dim('unavailable')), field('RAM', dim('unavailable')),
                      field('Disk', dim('unavailable'))]
        if kind == 'comfy':
            lines.append(field('ComfyUI', state_dot(comfy_status, comfy_status.startswith('ready'))))
        if setup_now:
            # state|message|ready|step %|step detail|workflow|workflow %|overall % (older installers: first 2-3)
            parts = (setup_now.split('|') + [''] * 8)[:8]
            _, _, ready, step, detail, workflow, workflow_pct, overall_pct = parts
            text, ok = setup_text(setup_now)
            lines.append(field('Setup', state_dot(text, ok)))
            if not ok and parts[0] == 'running':
                if step.isdigit():
                    lines.append(field('Step', progress(step, detail)))
                elif detail:
                    lines.append(field('Step', dim(detail)))
                if workflow and workflow_pct.isdigit():
                    lines.append(field('Workflow', progress(workflow_pct, workflow)))
                if overall_pct.isdigit():
                    lines.append(field('Overall', progress(overall_pct)))
            if ready and not ok:
                lines.append(field('Ready', green(ready)))
        return lines

    worker = threading.Thread(target=poll, daemon=True)
    worker.start()
    first.wait(45)
    if not sys.stdout.isatty() or not sys.stdin.isatty():
        print('\n' + header() + '\n' + '\n'.join(rows()))
        stop.set()
        return
    width = 62
    label = ' Live '
    top_border = dim('╭─') + bold(label) + dim('─' * (width - 1 - len(label)) + '╮')
    bottom_border = dim('╰' + '─' * width + '╯')

    def box() -> str:
        result = []
        for line in rows():
            if text_width(line) > width - 2:
                line = ANSI.sub('', line)
                while text_width(line) > width - 3:
                    line = line[:-1]
                line += '…'
            result.append(dim('│') + ' ' + line + ' ' * (width - 2 - text_width(line)) + ' ' + dim('│'))
        return '\n'.join(result)

    def screen() -> str:
        # The prompt hint depends on stopped state, so a state change forces a full repaint.
        return header() + ('\0stopped' if stopped_now() else '')

    def paint() -> tuple[str, int]:
        top, shown_now = header(), screen()
        display = box()
        print((top + '\n' if top else '') + '\n' + top_border + '\n' + display + '\n' + bottom_border)
        hint = dim(' (type start to resume)') if stopped_now() else ''
        print(bold('›') + ' Command' + hint + ': ', end='', flush=True)
        return shown_now, len(display.splitlines())

    def run_setup() -> None:
        nonlocal setup_line, setup_checked
        if stopped_now():
            print('The instance is stopped. Type start first.')
            return
        with lock:
            data = dict(info)
            preset = state.get('setup') or DEFAULT_SETUP
        if not data or data.get('actual_status') != 'running':
            print('The instance is not running yet. Try again in a minute.')
            return
        title = PRESETS[preset]['title']
        print(f'Starting {title} setup in the background (resumes; already-verified files are kept)…', flush=True)
        try:
            started = start_setup(instance_id, data, preset, attempts=2)
        except (RuntimeError, OSError, subprocess.SubprocessError) as error:
            print(yellow(str(error)))
            return
        if not started:
            print(yellow('Could not reach the instance over SSH. Try again shortly.'))
            return
        with lock:
            if state.get('setup') != preset:
                state['setup'] = preset
                save_state(instance_id, state)
            setup_line, setup_checked = 'running|starting…', time.monotonic()
        print(f'{title} setup started. Progress shows in the Setup row.')
        wake.set()

    def power(action: str) -> None:
        nonlocal tunnel_urls, comfy
        stopped = stopped_now()
        if action == 'stop' and stopped:
            print('Already stopped. Type start to resume.')
            return
        if action == 'start' and info and not stopped:
            print('Already running.')
            return
        print(('Stopping' if action == 'stop' else 'Starting') + f' instance {instance_id}…', flush=True)
        try:
            set_power(instance_id, action)
        except (RuntimeError, OSError, subprocess.SubprocessError) as error:
            print(yellow(str(error)))
            return
        with lock:
            tunnel_urls = {}
            comfy = 'stopping…' if action == 'stop' else 'instance starting…'
        if action == 'stop':
            print('Stop requested. GPU billing ends; disk storage keeps billing until you kill the rental.')
        else:
            print('Start requested. If someone else rented this GPU meanwhile, Vast waits until it frees up.')
        wake.set()

    print(section('Commands'))
    print('  ' + field('stop', 'stop the GPU; keeps files, storage still bills', 7))
    print('  ' + field('start', 'resume a stopped instance', 7))
    print('  ' + field('kill', 'destroy this rental', 7))
    if kind == 'comfy':
        print('  ' + field('comfy', 'enable ComfyUI web access ' + yellow('(recreates the container, erasing its files)'), 7))
        print('  ' + field('setup', f"install or resume {PRESETS[state.get('setup') or DEFAULT_SETUP]['title']} "
                                    'nodes and models', 7))
    print('  ' + field('Ctrl+C', 'close this display; the rental keeps running', 7))
    shown, count = paint()
    try:
        while True:
            readable, _, _ = select.select([sys.stdin], [], [], 1)
            if readable:
                command = sys.stdin.readline()
                if not command:
                    break
                command = command.strip()
                if command == 'kill':
                    stop.set()
                    destroy(instance_id)
                    return
                if command in ('stop', 'start'):
                    power(command)
                elif command == 'setup' and kind == 'comfy':
                    run_setup()
                elif command == 'comfy' and kind == 'comfy' and stopped_now():
                    print('The instance is stopped. Type start first.')
                elif command == 'comfy' and kind == 'comfy':
                    with lock:
                        exposed = bool(info) and bool(host_port(info, 8188))
                    if exposed:
                        print('ComfyUI web access is already enabled.')
                    else:
                        print('Enabling web access: updating settings and recycling the container…', flush=True)
                        enable_web(instance_id, image)
                        with lock:
                            tunnel_urls, comfy = {}, 'recycling • starting ComfyUI…'
                        print('Recycle started. The ComfyUI link appears here in a few minutes.'
                              + (' Then type setup to reinstall the nodes and models.' if state.get('setup') else ''))
                elif command:
                    print('Type stop, start, kill' + (', comfy, setup' if kind == 'comfy' else '')
                          + ', or Ctrl+C to close the display.')
                shown, count = paint()
                continue
            if screen() != shown:
                shown, count = paint()
                continue
            display = box()
            if len(display.splitlines()) == count:
                print(f'\0337\033[{count + 1}A\r' + display + '\0338', end='', flush=True)
            else:
                shown, count = paint()
    except KeyboardInterrupt:
        what = 'stays stopped (storage still bills)' if stopped_now() else 'keeps running and billing'
        print(f'\n\nDisplay closed. Rental {instance_id} {what}. Reopen: rent-gpu -m')
    finally:
        stop.set()
        wake.set()


def tracked_instance(requested: int) -> int:
    live = vast('show', 'instances')
    if not isinstance(live, list):
        raise RuntimeError('Cannot read live rentals.')
    ids = {r.get('id') for r in live}
    tracked = []
    for path in sorted(STATE.glob('*.json')) if STATE.exists() else []:
        try:
            data = json.loads(path.read_text())
        except (OSError, ValueError):
            continue
        if data.get('instance_id') in ids and data.get('status') != 'destroyed':
            tracked.append(data)
    if requested:
        if not any(d['instance_id'] == requested for d in tracked):
            raise RuntimeError(f'Instance {requested} is not a live rental created by this script.')
        return requested
    if not tracked:
        raise RuntimeError('No live rental created by rent-gpu to monitor.')
    if len(tracked) == 1:
        return tracked[0]['instance_id']
    for index, data in enumerate(tracked, 1):
        print(f"{index}. {data['instance_id']} • {data.get('gpu')} • {data.get('label')} • {data.get('image')}")
    choice = ask_number('Monitor which rental?', len(tracked))
    if choice is None:
        raise SystemExit(0)
    return tracked[choice]['instance_id']


def validate(opts: argparse.Namespace) -> None:
    """Checks the values that are set; preset-dependent ones are filled in after the image choice."""
    if (opts.disk is not None and opts.disk < 10) or (opts.min_ram is not None and opts.min_ram < 0) \
            or (opts.min_download is not None and opts.min_download < 0) \
            or (opts.max_setup_cost is not None and opts.max_setup_cost < 0) \
            or (opts.min_disk_speed is not None and opts.min_disk_speed < 0) \
            or opts.gpus < 1 or opts.min_vram < 0 or opts.top < 1:
        raise RuntimeError('Invalid filter values.')
    if opts.label is not None and not re.fullmatch(r'[A-Za-z0-9 _.-]{1,40}', opts.label):
        raise RuntimeError('Label may contain only letters, digits, spaces, _ . -')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true', help='Read-only: list GPU models and offers, never rent')
    parser.add_argument('-m', '--monitor', nargs='?', type=int, const=0, metavar='ID',
                        help='Reopen the live monitor for a rental made by this script')
    parser.add_argument('--image', help='Docker image (skips the image menu)')
    parser.add_argument('--setup', choices=sorted({*PRESETS, *PRESET_ALIASES}),
                        help=f'Skip the image menu and install a setup preset (image defaults to {COMFY_IMAGE})')
    parser.add_argument('--label', help='Vast instance label (default: Genjutsu for image 1, else Qwen)')
    parser.add_argument('--disk', type=int, help='Disk GB (default: 120 for image 1, else 60)')
    parser.add_argument('--min-vram', type=int, default=24, help='Minimum VRAM GB (default: 24)')
    parser.add_argument('--min-ram', type=int, help='Minimum system RAM GB (default: 64 for image 1, else 32)')
    parser.add_argument('--gpus', type=int, default=1, help='GPU count (default: 1)')
    parser.add_argument('--min-cuda', type=float, default=12.9, help='Minimum host CUDA; images need 12.9 (default: 12.9)')
    parser.add_argument('--min-compute', type=float, default=8.0,
                        help='Minimum CUDA compute capability; 8.0 = Ampere+ with bf16 (default: 8.0)')
    parser.add_argument('--max-setup-cost', type=float, metavar='USD',
                        help='Hide offers whose model download (bandwidth + GPU time) is estimated above this '
                             '(default: 0.30 for image 1)')
    parser.add_argument('--min-disk-speed', type=int,
                        help='Minimum disk read speed MB/s (default: 2500 for image 1, else 1000)')
    parser.add_argument('--min-download', type=int, help='Minimum download Mbps (default: 1000 for image 1, else 500)')
    parser.add_argument('--reliability', type=float, default=0.95, help='Minimum reliability 0–1 (default: 0.95)')
    parser.add_argument('--top', type=int, default=5, help='Offers shown for the chosen GPU (default: 5)')
    parser.add_argument('--wait', type=int, default=600, help='Seconds to wait for SSH (default: 600)')
    opts = parser.parse_args()
    opts.setup = PRESET_ALIASES.get(opts.setup, opts.setup)
    if opts.setup and opts.image and image_kind(opts.image) != 'comfy':
        raise RuntimeError('--setup needs a vastai/comfy image.')
    validate(opts)

    if opts.monitor is not None:
        instance_id = tracked_instance(opts.monitor)
        state = load_state(instance_id)
        print_access(instance_id, instance(instance_id), state.get('image', ''), state.get('setup'))
        monitor(instance_id)
        return

    print('\nRent Vast.ai GPU (rent only)')
    image, preset = (None, None) if opts.list else choose_image(opts)
    if not opts.list and image is None:
        return
    apply_defaults(opts, preset)
    gpu, rows = choose_gpu(opts)
    if not gpu:
        return
    show_offers(rows, opts.disk, opts.setup_gb)
    if opts.list or not rows:
        return
    while True:
        choice = ask_number('Rent which offer?', len(rows), refresh=True)
        if choice is None:
            return
        if choice != REFRESH:
            break
        print(f'\nRefreshing {gpu} offers…', flush=True)
        fresh_rows = search(opts, gpu)[:opts.top]
        if not fresh_rows:
            print(f'No {gpu} offers right now; keeping the previous list (press r to retry).')
            continue
        rows = fresh_rows
        show_offers(rows, opts.disk, opts.setup_gb)
    picked = rows[choice]

    # Refresh the exact offer; never substitute another one.
    fresh = [r for r in search(opts, gpu, picked['id']) if r['id'] == picked['id']]
    if not fresh:
        raise RuntimeError(f"Offer {picked['id']} is no longer available. Nothing was rented.")
    offer = fresh[0]
    if offer['dph_total'] > picked['dph_total'] + 1e-6:
        raise RuntimeError(f"Offer {offer['id']} rose from ${picked['dph_total']:.4f} to "
                           f"${offer['dph_total']:.4f}/hour. Nothing was rented; run again.")

    existing = vast('show', 'instances')
    if isinstance(existing, list) and existing:
        print(f'\nNote: you already have {len(existing)} Vast rental(s): '
              + ', '.join(f"{r.get('id')} ({r.get('label') or 'no label'}, {r.get('actual_status')})"
                          for r in existing))

    print(f"\nRenting offer {offer['id']}: {offer['gpu_name']} • ${offer['dph_total']:.4f}/hour • "
          f"{offer.get('geolocation') or 'unknown'}\n  image {image}\n  disk {opts.disk} GB • label {opts.label}"
          + (f"\n  setup {PRESETS[preset]['title']} (starts once SSH is up)" if preset else ''))
    print('Renting now (billing starts)...')

    result = vast('create', 'instance', str(offer['id']), '--image', image, '--disk', str(opts.disk),
                  *launch_args(image), '--cancel-unavail', '--label', opts.label)
    contract = result.get('new_contract') if isinstance(result, dict) else None
    if not (isinstance(contract, int) or str(contract or '').isdigit()) or int(contract) <= 0:
        raise RuntimeError('Vast did not return an instance ID. Check https://cloud.vast.ai/instances/ '
                           'before retrying — a rental may still have been created.')
    instance_id = int(contract)
    path = save_state(instance_id, dict(instance_id=instance_id, offer_id=offer['id'], gpu=offer['gpu_name'],
                                        image=image, disk_gb=opts.disk, label=opts.label,
                                        hourly_usd=offer['dph_total'], created_at=time.time(),
                                        **({'setup': preset} if preset else {})))
    print(f'\nRented instance {instance_id}. Saved to {path}.')
    print(f'Waiting up to {opts.wait // 60} min for the container and SSH (Ctrl+C stops waiting; rental is kept)…')
    try:
        info = wait_for_ssh(instance_id, opts.wait)
    except KeyboardInterrupt:
        info = None
        print()
    if info:
        if preset:
            title = PRESETS[preset]['title']
            print(f'\nStarting {title} setup in the background (nodes first, then ~67 GB of models)…', flush=True)
            if not start_setup(instance_id, info, preset):
                print(yellow(f'Could not start {title} setup over SSH. Type setup in the monitor to retry.'))
        print_access(instance_id, info, image, preset)
        monitor(instance_id)
    else:
        print(f'\nInstance {instance_id} is not ready yet and is still billable. Check https://cloud.vast.ai/instances/'
              f'\nWatch it with: rent-gpu -m {instance_id}'
              + (' (then type setup)' if preset else '') + f' • destroy: vastai destroy instance {instance_id}')


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print('\nCancelled. Any rental already created is kept and may be billable.')
        sys.exit(130)
    except Exception as error:
        print(f'\nStopped: {error}', file=sys.stderr)
        sys.exit(1)

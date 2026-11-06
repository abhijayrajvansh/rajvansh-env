#!/usr/bin/env python3
"""Rent-only Vast.ai GPU launcher (e.g. for Qwen). Standalone: needs only python3 and the `vastai` CLI.

Rents immediately after an explicit numbered offer choice (re-checked for price/availability). Only the monitor's explicit
`kill` destroys a rental, `stop`/`start` pause/resume it, and `comfy` recycles one to enable ComfyUI web access.
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
IMAGES = [
    ('ComfyUI (stock, no models preinstalled)', 'vastai/comfy:v0.15.1-cuda-12.9-py312'),
    ('Ubuntu 24.04 + Python 3.12 (bare; install vLLM / Transformers yourself)',
     'vastai/base-image:stock-ubuntu24.04-py312-2026-10-23'),
]
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


def choose_image(opts: argparse.Namespace) -> str | None:
    if opts.image:
        return opts.image
    print('\nContainer image:')
    for index, (label, image) in enumerate(IMAGES, 1):
        print(f'  {index}) {label}\n     {image}')
    print(f'  {len(IMAGES) + 1}) Custom Docker image')
    choice = ask_number('Choose image', len(IMAGES) + 1)
    if choice is None:
        return None
    if choice < len(IMAGES):
        return IMAGES[choice][1]
    image = input('Docker image (e.g. vllm/vllm-openai:latest): ').strip()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._/:@-]*', image):
        raise RuntimeError('Invalid image name; nothing was rented.')
    return image


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
    print(f'\nGPU models (≥{opts.min_vram} GB VRAM, ≥{opts.min_ram} GB RAM, {opts.disk} GB disk priced in, disk ≥{opts.min_disk_speed:,} MB/s, '
          'cheapest first):\n')
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


def show_offers(rows: list[dict[str, Any]], disk: int) -> None:
    print()
    for index, row in enumerate(rows, 1):
        verified = green('✓ Verified') if row.get('verification') == 'verified' else yellow('! Unverified')
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
        print(f' {cyan(bold(f"{index:>2}"))}  {header}')
        for n, (label, value) in enumerate(details):
            print(f"     {dim('└' if n == len(details) - 1 else '├')} {field(label, value, 7)}")
        print()


def wait_for_ssh(instance_id: int, timeout: int) -> dict[str, Any] | None:
    deadline = time.monotonic() + timeout
    last = ''
    while time.monotonic() < deadline:
        try:
            data = vast('show', 'instance', str(instance_id))
            data = data[0] if isinstance(data, list) and data else data
        except (RuntimeError, ValueError, subprocess.TimeoutExpired):
            data = {}
        status = ' '.join(str(data.get('status_msg') or data.get('actual_status') or 'starting').split())[:120]
        if status != last:
            print(f'  {time.strftime("%H:%M:%S")} {status}', flush=True)
            last = status
        if data.get('actual_status') == 'running' and ssh_candidates(data):
            return data
        time.sleep(5)
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
        env['COMFYUI_ARGS'] = '--disable-auto-launch --port 18188 --enable-cors-header'
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


def ssh_run(info: dict[str, Any], command: str) -> str | None:
    """Run a read-only command over the first working direct/proxy SSH endpoint."""
    for host, port in ssh_candidates(info):
        try:
            result = subprocess.run(
                ['ssh', '-i', str(SSH_KEY), '-o', 'IdentitiesOnly=yes', '-o', 'BatchMode=yes',
                 '-o', 'ConnectTimeout=6', '-o', 'StrictHostKeyChecking=accept-new', '-o', 'LogLevel=ERROR',
                 '-p', str(port), f'root@{host}', command],
                capture_output=True, text=True, timeout=25, stdin=subprocess.DEVNULL)
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


def print_access(instance_id: int, info: dict[str, Any], image: str) -> None:
    key = f'-i "{SSH_KEY}" ' if SSH_KEY.exists() else ''
    title = f' GPU instance {instance_id} '
    print('\n' + dim('━━') + bold(title) + dim('━' * max(4, 62 - len(title))))
    print('  ' + field('Image', image))
    print('  ' + field('Console', cyan('https://cloud.vast.ai/instances/')))
    print('  ' + field('Reopen', f'rent-gpu -m {instance_id}'))
    # Direct host-IP links are omitted: many networks (including this Mac's) cannot reach them.
    print(section('SSH'))
    for host_name, port in ssh_candidates(info):
        print('  ' + dim('›') + f' ssh {key}-p {port} root@{host_name}')


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
    state = json.loads((STATE / f'{instance_id}.json').read_text())
    image = state.get('image', '')
    kind = image_kind(image)
    info: dict[str, Any] = {}
    tunnel_urls: dict[int, str] = {}
    comfy = 'checking…'
    lock = threading.Lock()
    stop = threading.Event()
    wake = threading.Event()
    first = threading.Event()

    def poll() -> None:
        nonlocal info, tunnel_urls, comfy
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
                    info, tunnel_urls, comfy = fresh, found, status
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

    def rows() -> list[str]:
        with lock:
            data, comfy_status = dict(info), comfy
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
                        print('Recycle started. The ComfyUI link appears here in a few minutes.')
                elif command:
                    print('Type stop, start, kill' + (', comfy' if kind == 'comfy' else '')
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true', help='Read-only: list GPU models and offers, never rent')
    parser.add_argument('-m', '--monitor', nargs='?', type=int, const=0, metavar='ID',
                        help='Reopen the live monitor for a rental made by this script')
    parser.add_argument('--image', help='Docker image (skips the image menu)')
    parser.add_argument('--label', default='Qwen', help='Vast instance label (default: Qwen)')
    parser.add_argument('--disk', type=int, default=60, help='Disk GB (default: 60)')
    parser.add_argument('--min-vram', type=int, default=24, help='Minimum VRAM GB (default: 24)')
    parser.add_argument('--min-ram', type=int, default=32, help='Minimum system RAM GB (default: 32)')
    parser.add_argument('--gpus', type=int, default=1, help='GPU count (default: 1)')
    parser.add_argument('--min-cuda', type=float, default=12.9, help='Minimum host CUDA; images need 12.9 (default: 12.9)')
    parser.add_argument('--min-compute', type=float, default=8.0,
                        help='Minimum CUDA compute capability; 8.0 = Ampere+ with bf16 (default: 8.0)')
    parser.add_argument('--min-disk-speed', type=int, default=1000,
                        help='Minimum disk read speed MB/s (default: 1000)')
    parser.add_argument('--min-download', type=int, default=500, help='Minimum download Mbps (default: 500)')
    parser.add_argument('--reliability', type=float, default=0.95, help='Minimum reliability 0–1 (default: 0.95)')
    parser.add_argument('--top', type=int, default=5, help='Offers shown for the chosen GPU (default: 5)')
    parser.add_argument('--wait', type=int, default=600, help='Seconds to wait for SSH (default: 600)')
    opts = parser.parse_args()
    if opts.disk < 10 or opts.gpus < 1 or opts.min_vram < 0 or opts.min_ram < 0 or opts.min_disk_speed < 0 or opts.top < 1:
        raise RuntimeError('Invalid filter values.')
    if not re.fullmatch(r'[A-Za-z0-9 _.-]{1,40}', opts.label):
        raise RuntimeError('Label may contain only letters, digits, spaces, _ . -')

    if opts.monitor is not None:
        instance_id = tracked_instance(opts.monitor)
        state = json.loads((STATE / f'{instance_id}.json').read_text())
        print_access(instance_id, instance(instance_id), state.get('image', ''))
        monitor(instance_id)
        return

    print('\nRent Vast.ai GPU (rent only)')
    image = None if opts.list else choose_image(opts)
    if not opts.list and image is None:
        return
    gpu, rows = choose_gpu(opts)
    if not gpu:
        return
    show_offers(rows, opts.disk)
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
        show_offers(rows, opts.disk)
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
          f"{offer.get('geolocation') or 'unknown'}\n  image {image}\n  disk {opts.disk} GB • label {opts.label}")
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
                                        hourly_usd=offer['dph_total'], created_at=time.time()))
    print(f'\nRented instance {instance_id}. Saved to {path}.')
    print(f'Waiting up to {opts.wait // 60} min for the container and SSH (Ctrl+C stops waiting; rental is kept)…')
    try:
        info = wait_for_ssh(instance_id, opts.wait)
    except KeyboardInterrupt:
        info = None
        print()
    if info:
        print_access(instance_id, info, image)
        monitor(instance_id)
    else:
        print(f'\nInstance {instance_id} is not ready yet and is still billable. Check https://cloud.vast.ai/instances/'
              f'\nWatch it with: rent-gpu -m {instance_id} • destroy: vastai destroy instance {instance_id}')


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print('\nCancelled. Any rental already created is kept and may be billable.')
        sys.exit(130)
    except Exception as error:
        print(f'\nStopped: {error}', file=sys.stderr)
        sys.exit(1)

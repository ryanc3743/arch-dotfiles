#!/usr/bin/env python3
"""Addressed actions for Hyprland's Lua API; special workspace minimize/restore."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

def dispatch(expression):
    result = subprocess.run(['hyprctl', 'dispatch', expression], capture_output=True, text=True, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip())

def main(action, address):
    if not re.fullmatch(r'(0x)?[0-9a-fA-F]+', address):
        raise ValueError('Invalid window address')
    address = '0x' + address.removeprefix('0x')
    selector = 'address:' + address
    clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']))
    window = next((w for w in clients if w['address'] == address), None)
    if window is None:
        return
    state_dir = Path(os.environ['XDG_RUNTIME_DIR']) / 'expander-windows'
    state_dir.mkdir(mode=0o700, exist_ok=True)
    state_path = state_dir / (address + '.json')
    if action == 'minimize':
        if window['workspace']['name'] == 'special:expander-minimized':
            return
        state_path.write_text(json.dumps({'workspace': window['workspace']['name'], 'pid': window['pid']}))
        dispatch(f"hl.dsp.window.move({{window='{selector}', workspace='special:expander-minimized', follow=false}})")
    elif action == 'focus':
        if window['workspace']['name'] == 'special:expander-minimized':
            state = json.loads(state_path.read_text()) if state_path.exists() else {}
            workspace = state.get('workspace', '1') if state.get('pid') == window['pid'] else '1'
            # JSON string quoting also safely quotes these workspace names for Lua.
            dispatch(f'hl.dsp.window.move({{window="{selector}", workspace={json.dumps(workspace)}, follow=true}})')
            state_path.unlink(missing_ok=True)
        dispatch(f"hl.dsp.focus({{window='{selector}'}})")
    elif action == 'close':
        dispatch(f"hl.dsp.window.close({{window='{selector}'}})")
        state_path.unlink(missing_ok=True)
    elif action == 'maximize':
        dispatch(f"hl.dsp.window.fullscreen({{window='{selector}', mode='maximized', action='toggle'}})")
    else:
        raise ValueError('Unknown window action')

if __name__ == '__main__':
    try:
        main(*sys.argv[1:])
    except Exception as error:
        subprocess.run(['notify-send', 'Window action failed', str(error)])
        print(error, file=sys.stderr)
        sys.exit(1)

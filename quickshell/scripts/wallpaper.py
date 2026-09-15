#!/usr/bin/env python3
"""Wallpaper modes and palette extraction; commands use argument lists, never shell text."""
import time
import argparse, colorsys, hashlib, json, os, re, subprocess, tempfile
from pathlib import Path

def run(*args):
    return subprocess.check_output(args, text=True)

def geometry(monitors):
    result = []
    for m in monitors:
        w, h = m["width"], m["height"]
        if m.get("transform", 0) % 2:
            w, h = h, w
        scale = m.get("scale", 1)
        result.append(dict(name=m["name"], x=m["x"], y=m["y"],
                           w=round(w / scale), h=round(h / scale)))
    return result

def span(image, monitors, cache):
    rects = geometry(monitors)
    x0, y0 = min(m["x"] for m in rects), min(m["y"] for m in rects)
    width = max(m["x"] + m["w"] for m in rects) - x0
    height = max(m["y"] + m["h"] for m in rects) - y0
    key = hashlib.sha256((str(image) + str(image.stat().st_mtime_ns) + json.dumps(rects)).encode()).hexdigest()[:20]
    cache.mkdir(parents=True, exist_ok=True)
    canvas = cache / (key + "-canvas.png")
    run("magick", str(image) + "[0]", "-auto-orient", "-resize", f"{width}x{height}^",
        "-gravity", "center", "-extent", f"{width}x{height}", str(canvas))
    paths = {}
    for m in rects:
        dest = cache / (key + "-" + re.sub(r"[^A-Za-z0-9-]", "_", m["name"]) + ".png")
        run("magick", str(canvas), "-crop", f'{m["w"]}x{m["h"]}+{m["x"]-x0}+{m["y"]-y0}', "+repage", str(dest))
        paths[m["name"]] = str(dest)
    canvas.unlink()
    return paths

def palette(image):
    output = run("magick", str(image) + "[0]", "-auto-orient", "-resize", "80x80!", "-alpha", "off",
                 "-colors", "12", "-depth", "8", "-format", "%c", "histogram:info:")
    colors = []
    for line in output.splitlines():
        match = re.search(r"^\s*(\d+):.*#([0-9A-Fa-f]{6})", line)
        if match:
            rgb = tuple(int(match[2][i:i+2], 16)/255 for i in (0,2,4))
            colors.append((int(match[1]), rgb))
    if not colors:
        raise ValueError("Could not extract colors from this image")
    dominant = max(colors)[1]
    energy = max(colors, key=lambda c: colorsys.rgb_to_hsv(*c[1])[1] * .8 + colorsys.rgb_to_hsv(*c[1])[2] * .2)[1]
    def hx(rgb): return "#" + "".join(f"{round(max(0,min(1,v))*255):02x}" for v in rgb)
    hue = colorsys.rgb_to_hsv(*dominant)[0]
    eh, es, ev = colorsys.rgb_to_hsv(*energy)
    return dict(surfaceColor=hx(colorsys.hsv_to_rgb(hue,.35,.13)),
                secondaryColor=hx(colorsys.hsv_to_rgb(hue,.3,.26)),
                accentColor=hx(colorsys.hsv_to_rgb(eh,max(.45,es),max(.8,ev))),
                textColor=hx(colorsys.hls_to_rgb(eh,.90,es*.35)), mutedColor=hx(colorsys.hls_to_rgb(eh,.72,es*.25)))

def catalog(folder):
    cachefile = Path.home()/".cache/linux-config/wallpaper-dimensions.json"
    try: cache = json.loads(cachefile.read_text())
    except (OSError, ValueError): cache = {}
    images = []
    for path in sorted(folder.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {".jpg",".jpeg",".png",".gif",".webp"}:
            continue
        stamp = path.stat().st_mtime_ns
        cached = cache.get(str(path), {})
        if cached.get("stamp") != stamp:
            try:
                result = subprocess.check_output(["magick","identify","-ping","-format","%w %h %[orientation]",str(path)+"[0]"], text=True, stderr=subprocess.DEVNULL, timeout=8).split()
                width,height = int(result[0]),int(result[1])
                if len(result)>2 and result[2] in {"LeftTop","RightTop","RightBottom","LeftBottom"}:
                    width,height=height,width
                cached = dict(stamp=stamp,width=width,height=height)
            except (subprocess.SubprocessError, ValueError, IndexError):
                cached = dict(stamp=stamp,width=0,height=0)
            cache[str(path)] = cached
        images.append(dict(path=str(path),width=cached["width"],height=cached["height"]))
    cachefile.parent.mkdir(parents=True,exist_ok=True)
    cachefile.write_text(json.dumps(cache))
    return images

def fits(image, width, height, tolerance):
    return image["width"] > 0 and image["height"] > 0 and abs(image["width"]-width) <= tolerance and abs(image["height"]-height) <= tolerance

def apply_preset(preset, state, monitors):
    """Validate the entire draft before changing any output; retain source images."""
    if not isinstance(preset, dict) or preset.get("mode") not in {"individual", "span"}:
        raise ValueError("Choose individual wallpapers or a spanning wallpaper")
    available = {m["name"] for m in monitors}
    def image_path(value):
        if not isinstance(value, str) or not value.strip():
            raise ValueError("Choose an image first")
        path = Path(value).expanduser().resolve(strict=True)
        if not path.is_file():
            raise ValueError("Wallpaper must be an image file")
        return str(path)
    slideshow = preset.get("slideshow", {})
    if slideshow.get("enabled"):
        if not slideshow.get("images"):
            raise ValueError("Add slideshow images or turn the slideshow off")
        for path in slideshow["images"]:
            image_path(path)
        if slideshow.get("mode", "selected") == "selected" and slideshow.get("output") not in available:
            raise ValueError("The slideshow monitor is not connected")
    if preset["mode"] == "span":
        source = image_path(preset.get("spanImage"))
        sources = {name: source for name in available}
        paths = span(Path(source), monitors, Path.home()/".cache/linux-config/wallpaper-spans")
    else:
        images = preset.get("images", {})
        if not isinstance(images, dict):
            raise ValueError("Invalid monitor image assignments")
        # Disconnected output assignments remain in the saved preset for later use.
        sources = {name: image_path(path) for name, path in images.items() if name in available and path}
        if not sources:
            raise ValueError("Choose an image for a connected monitor")
        paths = sources
    old_paths = dict(state.get("outputImages", {}))
    keys = {"DP-3":"dp3Wallpaper", "DP-2":"dp2Wallpaper", "HDMI-A-1":"hdmiWallpaper"}
    for output, key in keys.items():
        if state.get(key): old_paths.setdefault(output, state[key])
    changed = []
    try:
        for output, path in paths.items():
            run("awww", "img", "--outputs", output, "--transition-type", "fade", "--transition-duration", "0.4", path)
            changed.append(output)
    except Exception:
        for output in changed:
            old = old_paths.get(output)
            if old and Path(old).is_file():
                try: run("awww", "img", "--outputs", output, old)
                except Exception: pass
        raise
    next_state = json.loads(json.dumps(state))
    next_state.setdefault("outputImages", {}).update(paths)
    next_state.setdefault("sourceImages", {}).update(sources)
    for output, key in keys.items():
        if output in paths: next_state[key] = paths[output]
    next_state["lastMode"] = "span" if preset["mode"] == "span" else "selected"
    return next_state

def write_state(statefile, state):
    statefile.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=statefile.parent, delete=False) as f:
        json.dump(state, f)
        temp = f.name
    os.replace(temp, statefile)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["apply","palette","restore","catalog","apply-preset"])
    ap.add_argument("--image")
    ap.add_argument("--preset-json")
    ap.add_argument("--mode", choices=["selected","all","span"], default="selected")
    ap.add_argument("--output", default="DP-2")
    ap.add_argument("--state", required=True)
    args = ap.parse_args()
    if args.action == "catalog":
        print(json.dumps(catalog(Path.home()/"Pictures/Wallpapers"))); return
    statefile = Path(args.state)
    state = json.loads(statefile.read_text()) if statefile.exists() else {}
    keys = {"DP-3":"dp3Wallpaper","DP-2":"dp2Wallpaper","HDMI-A-1":"hdmiWallpaper"}
    if args.action == "apply-preset":
        next_state = apply_preset(json.loads(args.preset_json), state, json.loads(run("hyprctl", "monitors", "-j")))
        write_state(statefile, next_state)
        print(json.dumps(next_state))
        return
    if args.action == "palette":
        source = args.image or state.get("sourceImages", {}).get(args.output) or state.get(keys.get(args.output,""), "")
        image = Path(source)
        if not source or not image.is_file(): raise ValueError("Choose a wallpaper first")
        print(json.dumps(palette(image))); return
    if args.action == "restore":
        for attempt in range(30):
            ready = subprocess.run(["awww","query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            if ready: break
            time.sleep(1)
        if not ready: raise RuntimeError("Wallpaper daemon did not become ready")
        available = {m["name"] for m in json.loads(run("hyprctl","monitors","-j"))}
        paths = {output: state.get(key) for output, key in keys.items()}
        paths.update(state.get("outputImages", {}))
        for output, path in paths.items():
            if output not in available: continue
            if path and Path(path).is_file():
                run("awww","img","--outputs",output,path)
        return
    image = Path(args.image).expanduser().resolve(strict=True)
    monitors = json.loads(run("hyprctl","monitors","-j"))
    if args.mode == "span":
        paths = span(image, monitors, Path.home()/".cache/linux-config/wallpaper-spans")
    else:
        outputs = [m["name"] for m in monitors] if args.mode == "all" else [args.output]
        paths = {name:str(image) for name in outputs}
    for output,path in paths.items():
        run("awww","img","--outputs",output,"--transition-type","fade","--transition-duration","0.4",path)
    for output,path in paths.items():
        if output in keys: state[keys[output]] = path
    state.setdefault("outputImages", {}).update(paths)
    state.setdefault("sourceImages", {}).update({name:str(image) for name in paths})
    state["lastMode"] = args.mode
    write_state(statefile, state)
    print(json.dumps({"image":str(image),"outputs":list(paths),"mode":args.mode}))
if __name__ == "__main__":
    try: main()
    except Exception as e:
        print(str(e), file=__import__("sys").stderr)
        raise SystemExit(1)

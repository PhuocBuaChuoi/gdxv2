"""
PixelLab Client Utility
Calls PixelLab MCP endpoint to generate pixel art sprites economically.
"""
import urllib.request
import json
import time
import os
import sys
import re

MCP_URL = "https://api.pixellab.ai/mcp"

def get_token():
    config_path = os.path.expanduser("~/.gemini/config/pixellab_key.txt")
    if os.path.exists(config_path):
        with open(config_path, "r", encoding="utf-8") as f:
            return f.read().strip()
    return os.environ.get("PIXELLAB_API_KEY", "")


def call_mcp(method, params, req_id=1):
    token = get_token()
    if not token:
        raise ValueError("Missing PixelLab token in ~/.gemini/config/pixellab_key.txt")
    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream"
    }
    payload = {
        "jsonrpc": "2.0",
        "id": req_id,
        "method": method,
        "params": params
    }
    req = urllib.request.Request(MCP_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    with urllib.request.urlopen(req) as resp:
        body = resp.read().decode("utf-8")
        for line in body.split("\n"):
            if line.startswith("data: "):
                return json.loads(line[6:])
    return None


def get_balance():
    res = call_mcp("tools/call", {"name": "get_balance", "arguments": {}})
    text = ""
    for c in res.get("result", {}).get("content", []):
        text += c.get("text", "")
    return text


def fetch_job(job_id, output_path):
    print(f"[*] Polling job {job_id}...")
    for attempt in range(25):
        poll_res = call_mcp("tools/call", {
            "name": "get_image",
            "arguments": {"job_id": job_id}
        })
        poll_text = ""
        for c in poll_res.get("result", {}).get("content", []):
            poll_text += c.get("text", "")
            
        urls = re.findall(r"https?://[^\s)\]\"\'<>]+", poll_text)
        if urls:
            img_url = urls[0]
            print(f"[+] Image ready: {img_url}")
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            urllib.request.urlretrieve(img_url, output_path)
            print(f"[+] Saved cleanly to {output_path}")
            print(f"[*] Balance after generation:")
            print(get_balance())
            return True
            
        if "error" in poll_text.lower() or "failed" in poll_text.lower():
            print("[!] Job failed:", poll_text)
            return False
            
        print(f"    ... waiting ({attempt+1}/25): {poll_text[:80]}...")
        time.sleep(3)
            
    print("[!] Timeout waiting for image.")
    return False


def generate_sprite(description, width=64, height=64, output_path="assets/sprites/custom_sprite.png", detail="low detail", view="side"):
    print(f"[*] Checking balance before generation...")
    print(get_balance())
    
    print(f"[*] Calling create_image_pixen: '{description}' ({width}x{height}, no_bg=True, view={view}, detail={detail})...")
    res = call_mcp("tools/call", {
        "name": "create_image_pixen",
        "arguments": {
            "description": description,
            "width": width,
            "height": height,
            "no_background": True,
            "view": view,
            "detail": detail
        }
    })
    
    if not res or "result" not in res:
        print("[!] Error creating job:", res)
        return False
    
    content_text = ""
    for c in res.get("result", {}).get("content", []):
        content_text += c.get("text", "")
    
    print(f"[*] Server response: {content_text}")
    
    # Extract UUID job id
    uuids = re.findall(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", content_text)
    if uuids:
        job_id = uuids[0]
    else:
        print("[!] Could not parse job_id UUID from response.")
        return False
        
    return fetch_job(job_id, output_path)


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--poll":
        fetch_job(sys.argv[2], sys.argv[3])
    elif len(sys.argv) > 1:
        prompt = sys.argv[1]
        out = sys.argv[2] if len(sys.argv) > 2 else "assets/sprites/test_gen.png"
        generate_sprite(prompt, output_path=out)
    else:
        print(get_balance())

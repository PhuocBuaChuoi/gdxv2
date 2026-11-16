"""
PixelLab Client Utility
Calls PixelLab MCP endpoint to generate pixel art sprites economically.
"""
import urllib.request
import json
import time
import os
import sys

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
    
    # Extract job id
    content_text = ""
    for c in res.get("result", {}).get("content", []):
        content_text += c.get("text", "")
    
    print(f"[*] Server response: {content_text}")
    
    # Find job_id or image id
    job_id = None
    for token_part in content_text.replace("\n", " ").split(" "):
        if "job_" in token_part or "job:" in token_part or token_part.startswith("job_"):
            job_id = token_part.strip().replace("job:", "").replace("`", "").replace("'", "")
            break
        elif "id:" in token_part:
            job_id = token_part.replace("id:", "").strip().replace("`", "")
    
    if not job_id:
        # Check if json formatted
        try:
            d = json.loads(content_text)
            job_id = d.get("job_id") or d.get("id")
        except:
            pass
            
    if not job_id:
        print("[!] Could not parse job_id from response.")
        return False
        
    print(f"[*] Polling job {job_id}...")
    for attempt in range(25):
        time.sleep(3)
        poll_res = call_mcp("tools/call", {
            "name": "get_image",
            "arguments": {"job_id": job_id}
        })
        poll_text = ""
        for c in poll_res.get("result", {}).get("content", []):
            poll_text += c.get("text", "")
            
        if "http" in poll_text:
            # find url
            for word in poll_text.replace("\n", " ").split(" "):
                if word.startswith("http://") or word.startswith("https://"):
                    img_url = word.strip().rstrip(").,'\"")
                    print(f"[+] Image ready: {img_url}")
                    os.makedirs(os.path.dirname(output_path), exist_ok=True)
                    urllib.request.urlretrieve(img_url, output_path)
                    print(f"[+] Saved cleanly to {output_path}")
                    print(f"[*] Balance after generation:")
                    print(get_balance())
                    return True
        elif "error" in poll_text.lower() or "failed" in poll_text.lower():
            print("[!] Job failed:", poll_text)
            return False
        else:
            print(f"    ... waiting ({attempt+1}/25): {poll_text[:80]}...")
            
    print("[!] Timeout waiting for image.")
    return False


if __name__ == "__main__":
    if len(sys.argv) > 1:
        prompt = sys.argv[1]
        out = sys.argv[2] if len(sys.argv) > 2 else "assets/sprites/test_gen.png"
        generate_sprite(prompt, output_path=out)
    else:
        print(get_balance())

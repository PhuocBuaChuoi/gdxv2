"""
PixelLab MCP Server
Provides tools for generating game sprites, orbs, hazards, and animations directly from PixelLab API.
Transport: stdio JSON-RPC 2.0
"""
import sys
import json
import os
import urllib.request
import urllib.error
import time

API_BASE = "https://api.pixellab.ai"

def get_api_key():
    key = os.environ.get("PIXELLAB_API_KEY")
    if not key:
        config_path = os.path.expanduser("~/.gemini/config/pixellab_key.txt")
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                key = f.read().strip()
    return key


def call_pixellab_api(endpoint, payload):
    key = get_api_key()
    if not key:
        return {"error": "Thiếu PIXELLAB_API_KEY. Vui lòng cấu hình API Key từ https://www.pixellab.ai"}
    url = f"{API_BASE}{endpoint}"
    data = json.dumps(payload).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {key}"
    }
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8")
        return {"error": f"PixelLab API HTTP {e.code}: {err_msg}"}
    except Exception as e:
        return {"error": f"Lỗi kết nối: {str(e)}"}


def handle_generate_sprite(args):
    description = args.get("description", "")
    width = args.get("width", 128)
    height = args.get("height", 128)
    output_path = args.get("output_path", "assets/sprites/generated_sprite.png")
    
    payload = {
        "description": description,
        "image_size": {"width": width, "height": height}
    }
    res = call_pixellab_api("/v2/create-image-pixen", payload)
    if "error" in res:
        # Fallback to v1 if v2 endpoint differs
        res = call_pixellab_api("/v1/generate-image-pixflux", payload)
    
    if "error" in res:
        return {"content": [{"type": "text", "text": res["error"]}]}
    
    # Download image if URL or base64 is returned
    img_url = res.get("image_url") or res.get("url")
    if img_url:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        urllib.request.urlretrieve(img_url, output_path)
        return {"content": [{"type": "text", "text": f"Đã gen thành công sprite và lưu vào {output_path}"}]}
    
    return {"content": [{"type": "text", "text": f"Kết quả từ PixelLab: {json.dumps(res)}"}]}


TOOLS = [
    {
        "name": "pixellab_generate_sprite",
        "description": "Tạo sprite pixel art từ prompt văn bản qua PixelLab AI",
        "inputSchema": {
            "type": "object",
            "properties": {
                "description": {"type": "string", "description": "Mô tả prompt của sprite cần gen"},
                "width": {"type": "integer", "description": "Chiều rộng sprite (ví dụ 64, 128)"},
                "height": {"type": "integer", "description": "Chiều cao sprite (ví dụ 64, 128)"},
                "output_path": {"type": "string", "description": "Đường dẫn file PNG lưu kết quả"}
            },
            "required": ["description"]
        }
    }
]


def send_response(response):
    payload = json.dumps(response)
    sys.stdout.write(f"Content-Length: {len(payload)}\r\n\r\n{payload}")
    sys.stdout.flush()


def main():
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        line = line.strip()
        if line.startswith("Content-Length:"):
            length = int(line.split(":")[1].strip())
            sys.stdin.readline() # blank line
            content = sys.stdin.read(length)
            msg = json.loads(content)
        elif line.startswith("{"):
            msg = json.loads(line)
        else:
            continue
        
        req_id = msg.get("id")
        method = msg.get("method")
        
        if method == "initialize":
            send_response({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "pixellab-mcp", "version": "1.0.0"}
                }
            })
        elif method == "notifications/initialized":
            pass
        elif method == "tools/list":
            send_response({
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"tools": TOOLS}
            })
        elif method == "tools/call":
            params = msg.get("params", {})
            name = params.get("name")
            args = params.get("arguments", {})
            if name == "pixellab_generate_sprite":
                result = handle_generate_sprite(args)
                send_response({"jsonrpc": "2.0", "id": req_id, "result": result})
            else:
                send_response({
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {"code": -32601, "message": f"Method {name} not found"}
                })


if __name__ == "__main__":
    main()

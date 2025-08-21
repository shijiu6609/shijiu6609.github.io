import requests
import base64
import re
import socket
import time
from datetime import datetime

GITHUB_SEARCH_URL = "https://api.github.com/search/repositories"
KEYWORDS = ["free v2ray", "clash subscription", "free node"]

def search_github_repos():
    repos = []
    for keyword in KEYWORDS:
        resp = requests.get(GITHUB_SEARCH_URL, params={
            "q": keyword,
            "sort": "updated",
            "order": "desc",
            "per_page": 5
        })
        data = resp.json()
        for repo in data.get("items", []):
            repos.append(repo["html_url"])
    return list(set(repos))

def extract_sub_links(repo_url):
    html = requests.get(repo_url).text
    subs = re.findall(r'(https?://[^\s\'"]+\.(txt|yaml|yml|list))', html)
    return list(set([s[0] for s in subs]))

def tcp_ping(host, port=443, timeout=1.5):
    try:
        start = time.time()
        sock = socket.create_connection((host, port), timeout=timeout)
        sock.close()
        return round((time.time() - start) * 1000, 2)
    except:
        return 9999

def parse_nodes_from_sub(url):
    try:
        raw = requests.get(url, timeout=5).text.strip()
        if not raw:
            return []
        try:
            decoded = base64.b64decode(raw).decode(errors="ignore")
        except:
            decoded = raw
        nodes = re.findall(r'(vmess://[^\s]+|vless://[^\s]+|trojan://[^\s]+)', decoded)
        return list(set(nodes))
    except:
        return []

if __name__ == "__main__":
    print(f"[{datetime.now()}] 搜索 GitHub 免费节点...")
    repos = search_github_repos()

    all_subs = []
    for repo in repos:
        subs = extract_sub_links(repo)
        all_subs.extend(subs)

    print(f"找到订阅源 {len(all_subs)} 条，解析中...")

    all_nodes = []
    for sub in all_subs:
        nodes = parse_nodes_from_sub(sub)
        all_nodes.extend(nodes)

    print(f"解析出 {len(all_nodes)} 个节点，测速中...")

    latency_list = []
    for node in all_nodes:
        match = re.search(r'@([a-zA-Z0-9\.\-]+):(\d+)', node)
        if match:
            host = match.group(1)
            delay = tcp_ping(host)
            latency_list.append((node, delay))

    latency_list = sorted(latency_list, key=lambda x: x[1])
    top_nodes = [n[0] for n in latency_list[:5]]

    sub_content = base64.b64encode("\n".join(top_nodes).encode()).decode()

    # 直接生成到 GitHub Pages 目录
    with open("karing_sub.txt", "w") as f:
        f.write(sub_content)

    print("✅ 已生成到 karing_sub.txt，可直接推送到 GitHub Pages")

.github/workflows/update_nodes.yml
name: Update Karing Nodes

on:
  schedule:
    - cron: '0 2 * * *'   # 每天北京时间 10:00 运行
  workflow_dispatch:       # 允许手动触发

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repo
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'

      - name: Install Dependencies
        run: pip install requests

      - name: Run Script
        run: python karing_auto_sub.py

      - name: Commit and Push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add karing_sub.txt
          git commit -m "Auto update nodes \$(date)"
          git push

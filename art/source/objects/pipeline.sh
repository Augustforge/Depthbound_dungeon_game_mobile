#!/usr/bin/env bash
# Usage: pipeline.sh <name> <polycount> <prompt>   (run from art/source)
# text-to-image (nano-banana-2) -> image-to-3d (smart topology, textured) -> objects/<name>/model.glb
set -uo pipefail
n=$1; poly=$2; prompt=$3
M=../../tools/meshy.sh
out=objects/$n; mkdir -p $out
style="Single game prop, three-quarter top-down view, painterly dark fantasy style, worn and rusty, readable silhouette, centered, plain light grey background, soft even lighting, no shadows, no text."
if ! python3 -c "import json;json.load(open('$out/t2i.json'))['result']['task']['task_id']" >/dev/null 2>&1; then
	$M text-to-image create --ai-model nano-banana-2 --aspect-ratio 1:1 --prompt "$prompt. $style" > $out/t2i.json 2>$out/log.txt
fi
iid=$(python3 -c "import json;print(json.load(open('$out/t2i.json'))['result']['task']['task_id'])") || { echo "$n t2i failed"; exit 1; }
curl -s -o $out/concept.png "$(python3 -c "import json;print(json.load(open('$out/t2i.json'))['result']['task']['image_urls'][0])")"
$M image-to-3d create --input-task-id $iid --model-type smart-topology --target-polycount $poly --should-texture true --enable-pbr false --texture-resolution 2k --target-formats glb --timeout 1500 > $out/i23d.json 2>>$out/log.txt
mid=$(python3 -c "import json;print(json.load(open('$out/i23d.json'))['result']['task']['task_id'])") || { echo "$n 3d failed"; exit 1; }
curl -s -o $out/thumb.png "$(python3 -c "import json;print(json.load(open('$out/i23d.json'))['result']['task']['thumbnail_url'])")"
curl -s -o $out/model.glb "$(python3 -c "import json;t=json.load(open('$out/i23d.json'))['result']['task'];print(t['model_urls']['glb'])")"
echo "$n done: t2i=$iid model=$mid"

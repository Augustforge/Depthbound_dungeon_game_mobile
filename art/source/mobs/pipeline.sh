#!/usr/bin/env bash
# Usage: pipeline.sh <name> <height_m> <prompt>   (run from art/source)
set -uo pipefail
n=$1; h=$2; prompt=$3
M=../../tools/meshy.sh
out=mobs/$n; mkdir -p $out
[ -s $out/i2i.json ] && python3 -c "import json;json.load(open('$out/i2i.json'))['result']['task']['task_id']" 2>/dev/null || $M image-to-image create --ai-model nano-banana-2 --aspect-ratio 3:4 --reference-image-urls mobs/$n.png --prompt "$prompt" > $out/i2i.json 2>$out/log.txt
iid=$(python3 -c "import json;print(json.load(open('$out/i2i.json'))['result']['task']['task_id'])") || { echo "$n i2i failed"; exit 1; }
curl -s -o $out/apose.png "$(python3 -c "import json;print(json.load(open('$out/i2i.json'))['result']['task']['image_urls'][0])")"
$M image-to-3d create --input-task-id $iid --model-type smart-topology --target-polycount 10000 --should-texture true --enable-pbr false --texture-resolution 2k --pose-mode a-pose --target-formats glb --timeout 1500 > $out/i23d.json 2>>$out/log.txt
mid=$(python3 -c "import json;print(json.load(open('$out/i23d.json'))['result']['task']['task_id'])") || { echo "$n 3d failed"; exit 1; }
curl -s -o $out/thumb.png "$(python3 -c "import json;print(json.load(open('$out/i23d.json'))['result']['task']['thumbnail_url'])")"
$M rigging create --input-task-id $mid --height-meters $h --timeout 1500 > $out/rig.json 2>>$out/log.txt
python3 -c "import json;t=json.load(open('$out/rig.json'))['result']['task'];print(t['task_id'])" > $out/rig_id.txt || { echo "$n rig failed"; exit 1; }
curl -s -o $out/rigged.glb "$(python3 -c "import json;print(json.load(open('$out/rig.json'))['result']['task']['result']['rigged_character_glb_url'])")"
echo "$n done: i2i=$iid model=$mid rig=$(cat $out/rig_id.txt)"

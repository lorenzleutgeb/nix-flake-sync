#! /usr/bin/env bash

ROOT=$(ghq root)

rm flakes-stream.json flakes-updated.json flakes.json flakes.txt

for REPO in $(ghq list)
do
	# Skip repos that don't contain both flake.{nix,lock}
	if ! git -C $ROOT/$REPO ls-files --error-unmatch flake.nix flake.lock 2>&1 >/dev/null
	then
		continue
	fi

	# Skip repos with modifications in flake.lock
	if [ ! -n "$(git -C $ROOT/$REPO status --porcelain=v1 flake.lock)" ]
	then
		echo x
		#continue
	fi

	# Collect list of flakes for future reference.
	echo "$REPO" >> flakes.txt
	# Collect flake.lock
	jq --arg name "$REPO" '{ "\($name)" : . }' < $ROOT/$REPO/flake.lock >> flakes-stream.json
done

# Merge all flake.lock files
jq -s 'add' < flakes-stream.json > flakes.json

jq -f flakes-list.jq < flakes.json

# Update lock files.
jq -f flakes-update.jq < flakes.json > flakes-updated.json

for REPO in $(cat flakes.txt)
do
	jq --arg repo "$REPO" '.[$repo]' < flakes-updated.json > $ROOT/$REPO/flake.lock
	echo $REPO
	git -C $ROOT/$REPO diff flake.lock
done

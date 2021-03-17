def maximal_by_property(f): (map(f) | max) as $mx
  | map(select((f) == $mx))
  | first;

def get_newest(original): to_entries
  | map(select(.value.nodes[original.id].original == original))
  | maximal_by_property(.value.nodes[original.id].locked.lastModified)
  | .value.nodes[original.id];

def update(original): get_newest(original) as $newest
  | (.[].nodes[original.id] | select(.original == original)) |= $newest;

update({id: "nixpkgs", ref: "nixos-unstable", type: "indirect"})

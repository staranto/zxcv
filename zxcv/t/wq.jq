include "_common";

.data
  | map(
      {
        "id": .id,
        "name": .attributes.name
      } +
      . as $item
        | reduce ($ARGS.positional[] / ".") as $p
          ({};
            setpath($p; $item | getpath($p) | out)
          )
    )
    | .[]
      | killAttributes
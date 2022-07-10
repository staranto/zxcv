include "_common";

.data
  | map(
      {"id": .id} +
      . as $item
        | reduce ($ARGS.positional[] / ".") as $p
          ({};
            setpath($p; $item | getpath($p) | out)
          )
    )
    | .[]
      | killAttributes
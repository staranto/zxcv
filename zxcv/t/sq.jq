include "_common";

.resources[]
  | .module as $m | .type as $t | .name as $n | .mode as $md
    | .instances
      | map(
          {"resource": "\($m).\(if $md == "data" then "data." else "" end)\($t).\($n)\(if .index_key == null then "" else [.index_key] end)"     } +
          . as $item
            | reduce ($ARGS.positional[] / ".") as $p
              ({};
                setpath($p; $item | getpath($p) | out)
              )
        )
        | .[]
          | killAttributes

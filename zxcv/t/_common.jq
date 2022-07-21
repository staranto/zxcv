def killAttributes:
  . |= (.attributes = {}) + .attributes
      | del(.attributes)
;

def out:
  if ( $j == "1" ) then
    .
  elif ( . == "" or . == null ) then
    "-"
  elif ( type == "object" or type == "array" ) then
    tostring
  else
    .
  end
;
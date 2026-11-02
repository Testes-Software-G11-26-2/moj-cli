#!/bin/bash
conf_get(){
  local d="$1" k="$2" line

  [[ -f "$d/conf" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$k="* ]]; then
      line="${line#"$k"=}"
      line="${line%\"}"
      printf '%s' "${line#\"}"
      return 0
    fi
  done < "$d/conf"

  return 0
}

sample_normalize(){
  local v
  v="$(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -d '[:space:]')"
  printf '%s' "${v//Ã/ã}"
}

sample_off(){
  local v
  v="$(sample_normalize "$(conf_get "$1" SAMPLE)")"
  [[ "$v" == no || "$v" == n || "$v" == nao ||
     "$v" == não || "$v" == false || "$v" == 0 ]]
}
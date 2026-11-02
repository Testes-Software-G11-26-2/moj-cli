#!/bin/bash
# tdd-driver-fora-da-lista.sh — TDD do M06 (function_conf_gate): AVISAR (sem reprovar) quando existe
# scripts/<lang>/compile.sh de uma linguagem que NÃO está em FUNCTION_LANGS. A validação do servidor
# já avisa isso (docs/PACOTE.md: "avisa driver fora da lista"); a CLI ainda não.
# Cada ciclo adiciona um teste. Uso: bash Test_Leticia/tdd-driver-fora-da-lista.sh
set -u
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"; CLI="$(cd "$HERE/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
MOJ_CLI_LIB_ONLY=1 MOJ_CONFIG_DIR="$T/cfg" source "$CLI/moj" 2>/dev/null
set +e; set +o pipefail
pass=0; fail=0; OUT=""; RC=0

# t <ID> <descrição> <linha do conf> <drivers com compile.sh> <condição>
t(){ local id="$1" desc="$2" conf="$3" drv="$4" cond="$5" p="$T/$1" d
  rm -rf "$p"; mkdir -p "$p/scripts"; for d in $drv; do mkdir -p "$p/scripts/$d"; : > "$p/scripts/$d/compile.sh"; done
  printf '%s\n' "$conf" > "$p/conf"
  OUT="$(function_conf_gate "$p" 2>&1)"; RC=$?
  if eval "$cond"; then echo "  ok:   $id $desc"; ((pass++)); else echo "  FAIL: $id $desc :: rc=$RC out=[$OUT]"; ((fail++)); fi; }


t T02 "apelido: lista py3 com driver py3 (canônico py): sem aviso" 'FUNCTION_LANGS=py3' "py3" \
  '[[ $RC == 0 && -z "$OUT" ]]'

t T03 "lista completa (c,py com drivers c e py3): sem aviso"  'FUNCTION_LANGS=c,py' "c py3" '[[ $RC == 0 && -z "$OUT" ]]'
t T04 "sem FUNCTION_LANGS, drivers existem (ban/OpenMP): sem aviso" 'CALIBRATIONTL=5' "c java" '[[ $RC == 0 && -z "$OUT" ]]'

echo; echo "RESULT: $pass passed, $fail failed"; exit $(( fail > 0 ? 1 : 0 ))
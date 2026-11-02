#!/bin/bash
# function-conf-gate.sh — M06 `function_conf_gate` (moj): valida FUNCTION_LANGS do `conf` de um pacote
# contra identificadores de linguagem e contra os drivers scripts/<lang>/compile.sh.
# Testes de unidade derivados por caixa-preta (classes + limites) e caixa-branca (decisões D1..D6).
# C01..C27 entram no exit code. Sem rede.
# Uso: bash Test_SEUNOME/function-conf-gate.sh [--trace]
#      --trace grava evidencias/traces/<ID>.trace (xtrace de cada caso) e imprime a cobertura de
#      linhas/decisões da função, calculada a partir dos traces (alternativa ao kcov).
set -u
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"; CLI="$(cd "$HERE/.." && pwd)"
TRACE=0; [[ "${1:-}" == --trace ]] && TRACE=1
TRDIR="$HERE/evidencias/traces"; (( TRACE )) && { rm -rf "$TRDIR"; mkdir -p "$TRDIR"; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
MOJ_CLI_LIB_ONLY=1 MOJ_CONFIG_DIR="$T/cfg" source "$CLI/moj" 2>/dev/null
set +e; set +o pipefail
type function_conf_gate >/dev/null 2>&1 || { echo "FAIL: function_conf_gate não carregou"; exit 1; }
pass=0; fail=0; OUT=""; RC=0
N16="$(printf 'a%.0s' {1..16})"; N17="${N16}a"

# t <ID> <descrição> <linha do conf | @sem-conf> <drivers> <condição>
#   drivers: nomes das pastas scripts/<nome> COM compile.sh; "nome!" = pasta SEM compile.sh;
#            "-" = pacote sem a pasta scripts/ ; "" = scripts/ existe e está vazia
t(){ local id="$1" desc="$2" conf="$3" drv="$4" cond="$5" p d fd
  p="$T/$id"; rm -rf "$p"; mkdir -p "$p"
  [[ "$drv" == "-" ]] || { mkdir -p "$p/scripts"; for d in $drv; do
      if [[ "$d" == *'!' ]]; then mkdir -p "$p/scripts/${d%!}"; else mkdir -p "$p/scripts/$d"; : > "$p/scripts/$d/compile.sh"; fi; done; }
  [[ "$conf" == "@sem-conf" ]] || printf '%s\n' "$conf" > "$p/conf"
  if (( TRACE )); then exec {fd}>"$TRDIR/$id.trace"; BASH_XTRACEFD=$fd; PS4='+@${BASH_SOURCE##*/}:${LINENO}@ '; set -x; fi
  OUT="$(function_conf_gate "$p" 2>&1)"; RC=$?
  if (( TRACE )); then set +x; exec {fd}>&-; unset BASH_XTRACEFD; fi
  if eval "$cond"; then echo "  ok:   $id $desc"; ((pass++)); else echo "  FAIL: $id $desc :: rc=$RC out=[$OUT]"; ((fail++)); fi; }

echo "== Caixa-preta: classes válidas (entrada sem nada a conferir) =="
t C01 "pacote sem arquivo conf: passa"                 '@sem-conf'                   "c"       '[[ $RC == 0 && -z $OUT ]]'
t C02 "conf sem a chave FUNCTION_LANGS: passa"         'CALIBRATIONTL=5'             "c"       '[[ $RC == 0 && -z $OUT ]]'
t C03 "valor vazio (FUNCTION_LANGS=): passa"           'FUNCTION_LANGS='             "-"       '[[ $RC == 0 && -z $OUT ]]'
t C04 "só vírgulas e espaços: passa"                   'FUNCTION_LANGS= , , '        "-"       '[[ $RC == 0 && -z $OUT ]]'
t C05 "só comentário (FUNCTION_LANGS=# x): passa"      'FUNCTION_LANGS=# x'          "-"       '[[ $RC == 0 && -z $OUT ]]'
echo "== Caixa-preta: classes válidas (lista com driver) =="
t C06 "c,py com drivers c e py3 (canônico py): passa"  'FUNCTION_LANGS=c,py'         "c py3"   '[[ $RC == 0 && -z $OUT ]]'
t C07 "py3 listado, driver py3: passa"                 'FUNCTION_LANGS=py3'          "py3"     '[[ $RC == 0 ]]'
t C08 "c++ -> cpp, driver cpp: passa"                  'FUNCTION_LANGS=c++'          "cpp"     '[[ $RC == 0 ]]'
t C09 "cc e cxx -> cpp, driver cpp: passa"             'FUNCTION_LANGS=cc,cxx'       "cpp"     '[[ $RC == 0 ]]'
t C10 "py2 -> py, driver py3: passa"                   'FUNCTION_LANGS=py2'          "py3"     '[[ $RC == 0 ]]'
t C11 "aspas duplas, caixa e espaço: passa"            'FUNCTION_LANGS="C, PY3"'     "c py3"   '[[ $RC == 0 ]]'
t C12 "separador só por espaço (c py): passa"          'FUNCTION_LANGS=c py'         "c py3"   '[[ $RC == 0 ]]'
t C13 "comentário depois da lista: passa"              'FUNCTION_LANGS=c # nota'     "c"       '[[ $RC == 0 ]]'
t C14 "elemento vazio no meio (c,,py): passa"          'FUNCTION_LANGS=c,,py'        "c py3"   '[[ $RC == 0 ]]'
t C15 "vírgula no fim (c,): passa"                     'FUNCTION_LANGS=c,'           "c"       '[[ $RC == 0 ]]'
echo "== Caixa-preta: valores limite do identificador (1 a 16 caracteres) =="
t C16 "1 caractere (c): passa"                         'FUNCTION_LANGS=c'            "c"       '[[ $RC == 0 ]]'
t C17 "16 caracteres com driver: passa"                "FUNCTION_LANGS=$N16"         "$N16"    '[[ $RC == 0 ]]'
t C18 "17 caracteres, mesmo com driver: reprova"       "FUNCTION_LANGS=$N17"         "$N17"    '[[ $RC != 0 && "$OUT" == *"não é id de linguagem"* ]]'
echo "== Caixa-preta: classes inválidas, uma por vez =="
t C19 "símbolo no id (x\$y): reprova, cita o id"       'FUNCTION_LANGS=x$y'          "c"       '[[ $RC != 0 && "$OUT" == *"x\$y"*"não é id de linguagem"* ]]'
t C20 "glob (*) não expande: reprova como id"          'FUNCTION_LANGS=*'            "c"       '[[ $RC != 0 && "$OUT" == *"não é id de linguagem"* ]]'
t C21 "linguagem válida sem driver (java): reprova"    'FUNCTION_LANGS=c,java'       "c"       '[[ $RC != 0 && "$OUT" == *"falta scripts/java/compile.sh"* ]]'
echo "== Caixa-branca: decisões D2 (laço de pastas) e D5 (driver) =="
t C22 "sem pasta scripts/ (o glob não casa nada, -f falso): reprova" 'FUNCTION_LANGS=c' "-"     '[[ $RC != 0 && "$OUT" == *"falta scripts/c/compile.sh"* ]]'
t C23 "scripts/c existe mas sem compile.sh (D2 falsa): reprova"   'FUNCTION_LANGS=c' "c!"    '[[ $RC != 0 && "$OUT" == *"falta scripts/c/compile.sh"* ]]'
t C24 "scripts/ vazia: reprova"                        'FUNCTION_LANGS=c'            ""        '[[ $RC != 0 ]]'
echo "== Complemento: dois erros distintos na mesma lista (ok=0 acumula, continue segue) =="
t C25 "x\$y,java: reprova e relata os dois"            'FUNCTION_LANGS=x$y,java'     "c"       '[[ $RC != 0 && "$OUT" == *"não é id"* && "$OUT" == *"falta scripts/java"* ]]'
t C26 "um erro e um acerto (java,c): reprova só por java" 'FUNCTION_LANGS=java,c'     "c"       '[[ $RC != 0 && "$OUT" != *"scripts/c/"* ]]'

# C27: diretório do pacote que não existe (sem conf, nada a conferir)
OUT="$(function_conf_gate "$T/nao-existe" 2>&1)"; RC=$?
if [[ $RC == 0 && -z "$OUT" ]]; then echo "  ok:   C27 diretório inexistente: passa"; ((pass++)); else echo "  FAIL: C27 :: rc=$RC out=[$OUT]"; ((fail++)); fi

if (( TRACE )); then
  echo; echo "== Cobertura da função (a partir dos traces) =="
  a=$(grep -n '^function_conf_gate()' "$CLI/moj" | cut -d: -f1); z=$(awk -v a="$a" 'NR>=a && /^  \[\[ \$ok -eq 1 \]\]; }/ {print NR; exit}' "$CLI/moj")
  exe="$(cat "$TRDIR"/*.trace | grep -o '@moj:[0-9]*@' | tr -d '@' | cut -d: -f2 | sort -un)"
  tot=0; hit=0
  for ((i=a; i<=z; i++)); do
    l="$(sed -n "${i}p" "$CLI/moj")"; [[ "$l" =~ ^[[:space:]]*(#|$) ]] && continue; ((tot++))
    if grep -qx "$i" <<<"$exe"; then ((hit++)); m="✓"; else m="✗"; fi
    printf '  %s %4d  %s\n' "$m" "$i" "${l:0:78}"
  done
  echo "  linhas executadas: $hit de $tot"
fi
echo; echo "RESULT: $pass passed, $fail failed"; exit $(( fail > 0 ? 1 : 0 ))
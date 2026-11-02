#!/bin/bash
# id-arg.sh — M10 `id_arg` (moj): de onde sai o <org>#<prob> do comando. Testes de unidade derivados por
# caixa-preta (partições + limites) e caixa-branca (decisões + MC/DC de D1 = A ∨ B ∨ (C ∧ D ∧ E)).
# Todos os casos (C01..C19, H1..H4, T1..T6) entram no exit code.
# TDD ciclo 1: H4 era XFAIL e virou caso obrigatório; T1..T3 nasceram no Red do ciclo.
# TDD ciclo 2: H1..H3 eram XFAIL e viraram casos obrigatórios; T4..T6 nasceram no Red do ciclo.
# Sem rede. Uso: bash Test_Eduardo/id-arg.sh [--trace]  (--trace grava evidencias/traces/<ID>.trace)
set -u
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"; CLI="$(cd "$HERE/.." && pwd)"
TRACE=0; [[ "${1:-}" == --trace ]] && TRACE=1
TRDIR="$HERE/evidencias/traces"; (( TRACE )) && mkdir -p "$TRDIR"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
T="$(cd "$T" && pwd -P)"    # pkg_root usa pwd -P: a fixture tem de estar no caminho físico
MOJ_CLI_LIB_ONLY=1 MOJ_CONFIG_DIR="$T/cfg" source "$CLI/moj" 2>/dev/null
set +e; set +o pipefail
type id_arg >/dev/null 2>&1 || { echo "FAIL: id_arg não carregou"; exit 1; }
command -v jq >/dev/null || { echo "FAIL: resolve_id precisa do jq"; exit 1; }
pass=0; fail=0; xfail=0; xpass=0

# ---- fixture ----------------------------------------------------------------------------------------
mkdir -p "$T/pkg/sub" "$T/pkg2" "$T/semid" "$T/semrepo" "$T/fora"
printf '{"id":"org#p1","repo":"org"}'   > "$T/pkg/.moj-id"
printf '{"id":"org2#p2","repo":"org2"}' > "$T/pkg2/.moj-id"
printf '{"repo":"org3"}'                > "$T/semid/.moj-id"
printf '{"id":"x#y"}'                   > "$T/semrepo/.moj-id"
mkdir -p "$T/repovazio" "$T/reponull"
printf '{"id":"x#y","repo":""}'       > "$T/repovazio/.moj-id"
printf '{"id":"x#y","repo":null}'     > "$T/reponull/.moj-id"
mkdir -p "$T/idsemorg" "$T/idsemprob"
printf '{"id":"#p","repo":"org"}'     > "$T/idsemorg/.moj-id"
printf '{"id":"org#","repo":"org"}'   > "$T/idsemprob/.moj-id"
( cd "$T/fora" && pkg_root >/dev/null ) && {
  echo "ABORT: pkg_root achou um .moj-id acima de $T/fora — a fixture 'fora' não está fora de um pacote"; exit 1; }

# run_id <ID> <dir_absoluto> <free> [args...] -> OUT (ID|IDSHIFT), ERR, RC. Subshell: id_arg/die dão exit 1.
run_id(){ local cid="$1" dir="$2" free="$3"; shift 3
  ( cd "$dir" || exit 99
    if (( TRACE )); then
      exec 9>"$TRDIR/$cid.trace"; BASH_XTRACEFD=9; PS4='+ ${FUNCNAME[0]:-main}:${LINENO}: '; set -x
    fi
    id_arg "$free" "$@" && { { set +x; } 2>/dev/null; printf '%s|%s' "$ID" "$IDSHIFT"; }
  ) >"$T/out" 2>"$T/err"
  RC=$?; OUT="$(<"$T/out")"; ERR="$(<"$T/err")"; }

obtido(){ if (( RC == 0 )); then printf 'rc0 %s' "$OUT"; else printf 'rc%s stderr="%s"' "$RC" "$ERR"; fi; }

# caso <C|H> <ID> <dir> <free> <rc esperado> <esperado> [args...]
#   rc 0: <esperado> é o "ID|IDSHIFT"; rc 1: <esperado> é um trecho do stderr ('' = só o rc).
caso(){ local k="$1" cid="$2" dir="$3" free="$4" erc="$5" exp="$6"; shift 6
  run_id "$cid" "$T/$dir" "$free" "$@"
  local ok=1
  (( RC == erc )) || ok=0
  if (( ok )); then
    if (( erc == 0 )); then [[ "$OUT" == "$exp" ]] || ok=0
    else [[ -z "$exp" || "$ERR" == *"$exp"* ]] || ok=0; fi
  fi
  local got; got="$(obtido)"
  if [[ "$k" == C ]]; then
    if (( ok )); then echo "  ok: $cid — obtido: $got"; ((pass++))
    else echo "  FAIL: $cid — esperado: rc$erc ${exp} — obtido: $got"; ((fail++)); fi
  else
    if (( ok )); then echo "  XPASS: $cid — obtido: $got"; ((xpass++))
    else echo "  XFAIL: $cid — esperado: rc$erc ${exp} — obtido: $got"; ((xfail++)); fi
  fi; }

R='^(on|off)$'   # a regex do `moj public`

echo "== caixa-preta: sem argumento / opção inicial =="
caso C C01 pkg     ''   0 'org#p1|0'
caso C C02 pkg/sub ''   0 'org#p1|0'
caso C C03 fora    ''   1 'falta o <id>'
caso C C04 pkg     ''   0 'org#p1|0'       -x
caso C C05 pkg     ''   0 'org#p1|0'       -
caso C C06 pkg     ''   0 'org#a-b|1'      a-b

echo "== caixa-preta: id explícito =="
caso C C07 pkg     ''   0 'org#x|1'        x
caso C C08 fora    ''   0 'org#p9|1'       'org#p9'
caso C C09 fora    ''   1 'não diz a org'  x
caso C C10 fora    ''   0 'org2#p2|1'      ../pkg2

echo "== caixa-branca: MC/DC de (C ∧ D ∧ E) e limites da regex =="
caso C C11 pkg     "$R" 0 'org#p1|0'       on
caso C C12 pkg     ''   0 'org#on|1'       on
caso C C13 pkg     "$R" 0 'org#foo|1'      foo
caso C C14 fora    "$R" 1 'não diz a org'  on
caso C C15 pkg     "$R" 0 'org#ON|1'       ON
caso C C16 pkg     "$R" 0 'org#onn|1'      onn
caso C C17 pkg     ''   0 'org#p9|1'       'org#p9' on

echo "== caixa-branca: validação final D4 =="
caso C C18 semid   ''   1 'id inválido'
caso C C19 fora    ''   1 'id inválido'    ../semid


echo "== TDD ciclo 1: nome sem org numa pasta cujo .moj-id não diz a org (ex-XFAIL H4 + T1..T3) =="
caso C H4 semrepo   ''   1 ''               foo      # .moj-id sem "repo": nada de '#foo'
caso C T1 repovazio ''   1 'não diz a org'  foo      # "repo":"" — o resolve_id é quem recusa
caso C T2 reponull  ''   1 'não diz a org'  foo      # "repo":null — idem
caso C T3 semrepo   ''   0 'x#y|0'                   # sem argumento o id implícito (.id) continua valendo

echo "== TDD ciclo 2: o id final tem org E problema não vazios (ex-XFAIL H1..H3 + T4..T6) =="
caso C H1 fora      ''   1 'id inválido'    '#'
caso C H2 fora      ''   1 'id inválido'    'org#'
caso C H3 fora      ''   1 'id inválido'    '#p'
caso C T4 idsemorg  ''   1 'id inválido'             # id IMPLÍCITO (.id da pasta) = '#p'
caso C T5 fora      ''   1 'id inválido'    ../idsemprob   # pasta clonada cujo .id = 'org#'
caso C T6 fora      ''   0 'a#b|1'          'a#b'    # limite: 1 caractere de cada lado ainda vale

(( xpass )) && echo "  ($xpass hipótese(s) XPASS: o defeito não se manifestou)"
echo; echo "RESULT: $pass passed, $fail failed, $xfail xfail"
(( fail == 0 ))

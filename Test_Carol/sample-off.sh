#!/bin/bash
# sample-off.sh — M04 `sample_off` (moj, linhas 842–843): o conf do pacote declara SAMPLE=no (sem exemplos)?
# Testes de unidade derivados por caixa-preta (partições + limites) e caixa-branca (decisão D1 = OR de seis
# comparações, MC/DC). C01..C32 entram no exit code; H1..H2 são defeitos observados (XFAIL: o esperado é
# falharem hoje). Oráculo: o CÓDIGO DE SAÍDA da função (0 = sem exemplos, 1 = com exemplos); ela não imprime nada.
# Sem rede. Uso: bash Test_Carol/sample-off.sh [--trace]  (--trace grava evidencias/traces/<ID>.trace)
set -u
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"; CLI="$(cd "$HERE/.." && pwd)"
TRACE=0; [[ "${1:-}" == --trace ]] && TRACE=1
TRDIR="$HERE/evidencias/traces"; (( TRACE )) && mkdir -p "$TRDIR"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
T="$(cd "$T" && pwd -P)"
command -v jq >/dev/null || { echo "FAIL: o moj precisa do jq para carregar (instale o jq)"; exit 1; }
MOJ_CLI_LIB_ONLY=1 MOJ_CONFIG_DIR="$T/cfg" source "$CLI/moj" 2>/dev/null
set +e; set +o pipefail
type sample_off >/dev/null 2>&1 || { echo "FAIL: sample_off não carregou"; exit 1; }
type gate >/dev/null 2>&1 || { echo "FAIL: gate não carregou"; exit 1; }
pass=0; fail=0; xfail=0; xpass=0

# ---- fixture ----------------------------------------------------------------------------------------
P="$T/p"; G="$T/g"; mkdir -p "$P" "$G/docs" "$G/tests/input" "$G/tests/output" "$G/sols/good"
printf '# x\n\n## Entrada\n\n## Saída\n' > "$G/docs/enunciado.md"
printf 'int main(){}\n' > "$G/sols/good/a.c"
printf '{"id":"o#p","repo":"o","prob":"p","title":"P"}' > "$G/.moj-id"

# executa "$@" num subshell, com xtrace opcional em evidencias/traces/<ID>.trace; deixa OUT, ERR, RC
rodar(){ local cid="$1"; shift
  ( if (( TRACE )); then
      exec 9>"$TRDIR/$cid.trace"; BASH_XTRACEFD=9; PS4='+ ${FUNCNAME[0]:-main}:${LINENO}: '; set -x
    fi
    "$@" ) >"$T/out" 2>"$T/err"
  RC=$?; OUT="$(<"$T/out")"; ERR="$(<"$T/err")"; }

# conteúdo do conf: o 4º argumento passa por printf %b ('@ausente' = sem arquivo conf)
poe_conf(){ if [[ "$1" == @ausente ]]; then rm -f "$2/conf"; else printf '%b' "$1" > "$2/conf"; fi; }

# registra o resultado: reg <C|H> <ID> <ok 0/1> <esperado> <obtido>
reg(){ local k="$1" cid="$2" ok="$3" exp="$4" got="$5"
  if [[ "$k" == C ]]; then
    if (( ok )); then echo "  ok: $cid — obtido: $got"; ((pass++))
    else echo "  FAIL: $cid — esperado: $exp — obtido: $got"; ((fail++)); fi
  else
    if (( ok )); then echo "  XPASS: $cid — obtido: $got"; ((xpass++))
    else echo "  XFAIL: $cid — esperado: $exp — obtido: $got"; ((xfail++)); fi
  fi; }

# caso <C|H> <ID> <rc esperado 0|1> <conf|@ausente>
#   chama sample_off direto; o rc é o oráculo e a função não pode imprimir nada
caso(){ local k="$1" cid="$2" erc="$3" conf="$4"
  poe_conf "$conf" "$P"; rodar "$cid" sample_off "$P"
  local ok=1; (( RC == erc )) || ok=0; [[ -z "$OUT$ERR" ]] || ok=0
  reg "$k" "$cid" "$ok" "rc$erc" "rc$RC conf=\"$conf\"$([[ -n "$OUT$ERR" ]] && printf ' (imprimiu: %s)' "$OUT$ERR")"; }

# caso_gate <C|H> <ID> <rc esperado do gate> <trecho esperado na saída> <conf>
#   integra com o pré-voo: o gate usa sample_off para exigir (ou dispensar) tests/input/sample*
caso_gate(){ local k="$1" cid="$2" erc="$3" trecho="$4" conf="$5"
  poe_conf "$conf" "$G"; rodar "$cid" gate "$G"
  local ok=1; (( (RC == 0) == (erc == 0) )) || ok=0; [[ "$OUT$ERR" == *"$trecho"* ]] || ok=0
  reg "$k" "$cid" "$ok" "rc$([[ $erc == 0 ]] && echo 0 || echo '≠0') com \"$trecho\"" "rc$RC conf=\"$conf\""; }

echo "== caixa-preta P1: os seis sinônimos de falso (forma canônica) — aceitos =="
caso C C01 0 'SAMPLE=no\n'
caso C C02 0 'SAMPLE=n\n'
caso C C03 0 'SAMPLE=nao\n'
caso C C04 0 'SAMPLE=não\n'
caso C C05 0 'SAMPLE=false\n'
caso C C06 0 'SAMPLE=0\n'

echo "== caixa-preta P2: caixa e espaços são ignorados — aceitos =="
caso C C07 0 'SAMPLE=NO\n'
caso C C08 0 'SAMPLE=FaLsE\n'
caso C C09 0 'SAMPLE= No \n'
caso C C10 0 'SAMPLE=n o\n'
caso C C11 0 'SAMPLE=\tfalse\t\n'

echo "== caixa-preta P3: afirmativos e desconhecidos — recusados =="
caso C C12 1 'SAMPLE=yes\n'
caso C C13 1 'SAMPLE=y\n'
caso C C14 1 'SAMPLE=sim\n'
caso C C15 1 'SAMPLE=true\n'
caso C C16 1 'SAMPLE=1\n'
caso C C17 1 'SAMPLE=abc\n'

echo "== caixa-preta P4: chave ausente — recusada =="
caso C C18 1 'CPUNEEDED=4\n'
caso C C19 1 '@ausente'

echo "== caixa-preta: valores-limite =="
caso C C20 1 'SAMPLE=\n'
caso C C21 1 'SAMPLE=   \n'
caso C C22 1 'SAMPLE=00\n'
caso C C23 1 'SAMPLE=-0\n'
caso C C24 1 'SAMPLE=no1\n'
caso C C25 1 'SAMPLE=nop\n'
caso C C26 1 'SAMPLE=fals\n'

echo "== caixa-preta P5: chave só com o mesmo prefixo; chave duplicada =="
caso C C27 1 'SAMPLES=no\n'
caso C C28 1 'SAMPLE=yes\nSAMPLE=no\n'
caso C C29 0 'SAMPLE=no\nSAMPLE=yes\n'

echo "== caixa-branca: MC/DC de D1 = C1 ∨ C2 ∨ C3 ∨ C4 ∨ C5 ∨ C6 (Ci: v == literal i) =="
caso C C30 1 'SAMPLE=xyz\n'     # base: C1..C6 todas F -> D1=F; par de Ci = (C30, C0i) com C0i = literal i

echo "== caixa-branca: integração com o gate (D1 verdadeira e falsa, com assert no efeito) =="
caso_gate C C31 0 'SAMPLE=no'    'SAMPLE=no\n'
caso_gate C C32 1 'sem exemplos' 'SAMPLE=yes\n'

echo "== defeitos observados (XFAIL): requisito 'ignora caixa e espaços' e leitura do conf =="
caso H H1 0 'SAMPLE=NÃO\n'
caso H H2 0 'SAMPLE=no'

(( xpass )) && echo "  ($xpass defeito(s) em XPASS: o defeito não se manifestou — troque H por C)"
echo; echo "RESULT: $pass passed, $fail failed, $xfail xfail"
(( fail == 0 ))
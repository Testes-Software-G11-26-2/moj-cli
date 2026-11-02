# M10 — `id_arg` (moj-cli) · Testes de Software G11 · Eduardo

## 1. Identificação

| Item | Valor |
|---|---|
| Método | M10 `id_arg`. Também exercita as funções que ele chama: `resolve_id` e `pkg_root` |
| Arquivo | `moj`, depois dos 2 ciclos de TDD: `pkg_root` nas linhas 1453–1458, `resolve_id` nas linhas 1462–1473, `id_completo` na linha 1477 (criada no TDD), `id_arg` nas linhas 1481–1486. Antes do TDD: `resolve_id` 1462–1471 e `id_arg` 1475–1480 |
| Commit | `716ce0c` (`master`, sincronizado com `upstream/master`: `git rev-list --count master..upstream/master` = 0) como base dos testes; os 2 ciclos de TDD (seção 7) alteram o `moj` nesta branch |
| Branch | `test/eduardo-m10` |
| Ferramentas | GNU bash 5.3.20(1)-release · jq-1.8.2 · kcov 43 · ImageMagick 7.1.2-34 · Arch Linux, kernel 6.18.57-2-lts |
| Data | 2026-10-23 (testes) · 2026-11-02 (2 ciclos de TDD e evidências regeradas) |
| Script | `Test_Eduardo/id-arg.sh`: teste de unidade, offline, com fixture em `mktemp -d` |

Para reproduzir, rode na raiz do `moj-cli`:

```bash
bash Test_Eduardo/id-arg.sh                                   # execução normal (exit 0 = nenhum caso C falhou)
bash Test_Eduardo/id-arg.sh --trace                           # grava evidencias/traces/<ID>.trace (xtrace)
kcov --include-path="$PWD/moj" Test_Eduardo/evidencias/cobertura ./Test_Eduardo/id-arg.sh   # cobertura de linhas
bash test/push-exit.sh; bash test/translations.sh; bash test/parallel-conf.sh; bash test/portabilidade.sh   # regressão do TDD (testes do upstream, offline)
```

O script carrega o `moj` com `MOJ_CLI_LIB_ONLY=1 source moj` (o mesmo jeito do `test/parallel-conf.sh`). Nesse modo o `moj` só define as funções. `MOJ_CONFIG_DIR` aponta para a fixture, e nenhuma configuração real da máquina é lida.

## 2. Contrato

O contrato vem dos comentários do código, da documentação (`CLAUDE.md` do upstream e cabeçalho do `moj`) e do jeito como os chamadores usam a função.

- **`id_arg`** (comentário acima da linha 1481; era a 1475 antes do TDD): *"id_arg <regex-do-que-NÃO-é-id> "$@" -> define ID e IDSHIFT (1 = o 1º argumento ERA o id; o chamador faz o shift). O id é IMPLÍCITO (vem da pasta) quando não há argumento, quando o 1º é uma opção (-…) ou quando ele casa a regex E estamos numa pasta de problema (ex.: `moj public on`, `moj restore <sha>`)."*
- **`resolve_id`** (comentário acima da linha 1462): *"resolve_id [arg] -> <org>#<prob>. Vazio = o da pasta do problema; com '#' = ele mesmo; pasta clonada = o dela; nome SEM a org = <org da pasta atual>#nome."*
- **`pkg_root`** (comentário acima da linha 1453): devolve a pasta do problema. É a própria pasta ou a primeira acima dela que tem `.moj-id` ("como o git acha o .git").
- **`id_completo`** (criada no ciclo 2 do TDD, comentário acima da linha 1477): *"0 se o id tem a forma <org>#<prob> com org E problema NÃO vazios"*. É a pós-condição abaixo escrita como função.
- **Pós-condição de `id_arg`**: `ID` tem a forma `<org>#<prob>`. Senão, a função chama `die "id inválido: … (esperado <org>#<prob>)"`. O cabeçalho do `moj` diz que *"ORG = quem edita. É o prefixo do id <org>#<prob>"*. Por isso este relatório lê `<org>` e `<prob>` como **não vazios**. As hipóteses H1–H4 se apoiam nessa leitura, e foi ela que os 2 ciclos de TDD implementaram (seção 7).
- **Chamadores** (exemplos): `cmd_public` usa `id_arg '^(on|off)$'`, `cmd_log` usa `id_arg '^[0-9a-f]{7,40}$'`, `cmd_download` usa `id_arg '\.(tar\.gz|tgz|tar)$'`, e `cmd_publish`/`cmd_validate` usam `id_arg ''`. Depois da chamada, todos fazem `shift "$IDSHIFT"`.

## 3. Caixa-preta: partições e limites

Fixture criada em `$T = mktemp -d`, com caminho físico (`pwd -P`, porque `pkg_root` usa `pwd -P`):

| Pasta | `.moj-id` |
|---|---|
| `pkg/` | `{"id":"org#p1","repo":"org"}` |
| `pkg/sub/` | nenhum (subpasta do pacote) |
| `pkg2/` | `{"id":"org2#p2","repo":"org2"}` |
| `semid/` | `{"repo":"org3"}` (sem `id`) |
| `semrepo/` | `{"id":"x#y"}` (sem `repo`) |
| `repovazio/` | `{"id":"x#y","repo":""}` (criada no ciclo 1 do TDD) |
| `reponull/` | `{"id":"x#y","repo":null}` (criada no ciclo 1 do TDD) |
| `idsemorg/` | `{"id":"#p","repo":"org"}` (criada no ciclo 2 do TDD) |
| `idsemprob/` | `{"id":"org#","repo":"org"}` (criada no ciclo 2 do TDD) |
| `fora/` | nenhum, e nenhum acima. O script confere essa pré-condição: aborta se `pkg_root` achar um pacote a partir de `fora/` |

`R` = `^(on|off)$` (a regex do `moj public`). `''` = regex vazia.

| Partição / limite | Classe | Casos |
|---|---|---|
| P1 sem argumento, dentro do pacote | válida | C01 |
| P2 sem argumento, em subpasta do pacote | válida | C02 |
| P3 sem argumento, fora de pacote | inválida | C03 |
| P4 1º argumento é opção (`-…`) | válida | C04 |
| L1 limite de P4: `-` sozinho | limite | C05 |
| L2 limite de P4: hífen fora da 1ª posição (`a-b`) | limite | C06 |
| P5 nome curto, dentro do pacote | válida | C07 |
| P6 id completo `org#prob` (fora do pacote) | válida | C08 |
| P7 nome curto, fora de pacote | inválida | C09 |
| P8 caminho de pasta clonada | válida | C10 |
| P9 palavra livre (casa a regex) dentro do pacote | válida | C11 |
| P10 palavra livre fora de pacote | inválida | C14 |
| L3 limite da regex: caixa (`ON`) | limite | C15 |
| L4 limite da regex: âncora (`onn`) | limite | C16 |
| P11 dois argumentos (só o 1º decide) | válida | C17 |
| P12 `.moj-id` sem `id` (implícito) | inválida | C18 |
| P13 pasta clonada cujo `.moj-id` não tem `id` | inválida | C19 |
| P14 id explícito sem org, sem problema ou sem os dois (`#p`, `org#`, `#`) | inválida | H1, H2, H3 (XFAIL até o ciclo 2 do TDD) |
| P15 nome curto numa pasta cujo `.moj-id` não diz a org: `repo` ausente, `""` ou `null` | inválida | H4 (XFAIL até o ciclo 1), T1, T2 |
| P16 sem argumento numa pasta sem `repo` (o `.id` da pasta continua valendo) | válida | T3 |
| P17 id implícito (`.id` da pasta) sem org | inválida | T4 |
| P18 pasta clonada cujo `.id` não tem problema | inválida | T5 |
| L5 limite de P14: 1 caractere de cada lado (`a#b`) | limite | T6 |

## 4. Caixa-branca

### Decisões e condições

| Decisão | Linha | Expressão |
|---|---|---|
| **D1** | 1482 | `A ∨ B ∨ (C ∧ D ∧ E)`. A = `$# -eq 0`, B = `"$1" == -*`, C = `-n "$free"`, D = `"$1" =~ $free`, E = `pkg_root` ok |
| **D2** | 1483 | `ID="$(resolve_id)" \|\| exit 1`: o `resolve_id` implícito deu certo? |
| **D3** | 1484 | `ID="$(resolve_id "$1")" \|\| exit 1`: o `resolve_id` explícito deu certo? |
| **D4** | 1485 | `id_completo "$ID" \|\| die …`: `ID` tem 1 caractere ou mais antes e depois de um `#` (`?*#?*`)? Antes do ciclo 2 do TDD era `[[ "$ID" == *#* ]]` (só "contém `#`") |
| **D5** | 1471 (`resolve_id`, ciclo 1) | `[[ -n "$o" ]] \|\| die …`: o `.moj-id` da pasta diz a org (`repo` não vazio)? |

Cobertura de decisão (V/F), com resultado real:

| Decisão | V | F |
|---|---|---|
| D1 | C01, C02, C03, C04, C05, C11, C18 | C06–C10, C12–C17, C19 |
| D2 | C01, C02, C04, C05, C11, C18 | C03 |
| D3 | C06–C08, C10, C12, C13, C15–C17, C19 | C09, C14 |
| D4 | todos os casos com rc0 | C18, C19, H1, H2, H3, T4, T5 |
| D5 | C06, C07, C12, C13, C15, C16 (nome curto, explícito, dentro de `pkg/`) | H4, T1, T2 |

**Curto-circuito.** Com A=V, o bash não avalia B, C, D nem E. Com C=F, ele não avalia D nem E. Isso **mascara** D e E nos pares de A e de B. É aceitável no MC/DC com mascaramento: nesses pares, só a condição em estudo muda o resultado.

**Mascaramento novo do TDD.** Depois do ciclo 1, o `#foo` do H4 nunca chega à D4: a D5 o barra antes, no `resolve_id`. Por isso o H4 foi corrigido **antes** do H1–H3 (ciclo 1 × ciclo 2, seção 7). Na ordem contrária, o Red do 2º ciclo não teria falhado.

**O que não é factível.** Em `pkg_root`, o termo `-z "$d"` (linha 1456) nunca fica V. `d` vem de `pwd -P` ou de `dirname`, e nenhum dos dois devolve string vazia. Esse termo não entra nos pares deste método.

### Fluxo de `id_arg` (código depois do TDD)

```mermaid
flowchart TD
  S(["id_arg free args…"]) --> I["IDSHIFT=0"]
  I --> A{"A: nenhum argumento?"}
  A -- V --> IMP
  A -- F --> B{"B: 1º argumento começa com '-'?"}
  B -- V --> IMP
  B -- F --> C{"C: free não vazio?"}
  C -- F --> EXP
  C -- V --> D{"D: 1º argumento casa free?"}
  D -- F --> EXP
  D -- V --> E{"E: pkg_root acha pacote?"}
  E -- V --> IMP
  E -- F --> EXP
  IMP["ID = resolve_id (implícito)"] --> D2{"D2: rc = 0?"}
  D2 -- F --> X1(["exit 1"])
  D2 -- V --> D4
  EXP["ID = resolve_id 1º argumento (explícito)"] --> D3{"D3: rc = 0? (inclui a D5: nome curto numa pasta sem repo = die)"}
  D3 -- F --> X1
  D3 -- V --> SH["IDSHIFT=1"] --> D4{"D4: id_completo — org e prob não vazios?"}
  D4 -- V --> OK(["retorna: ID e IDSHIFT definidos"])
  D4 -- F --> DIE(["die 'id inválido' → exit 1"])
```

### MC/DC de D1

| Par | Condição | A | B | C | D | E | D1 | Ramo (linha, depois do TDD) |
|---|---|---|---|---|---|---|---|---|
| **C01** × C07 | A | **V** | – | – | – | – | V | 1483 |
| C01 × **C07** | A | **F** | F | F | – | – | F | 1484 |
| **C04** × C07 | B | F | **V** | – | – | – | V | 1483 |
| C04 × **C07** | B | F | **F** | F | – | – | F | 1484 |
| **C11** × C12 | C | F | F | **V** | V | V | V | 1483 |
| C11 × **C12** | C | F | F | **F** | – | – | F | 1484 |
| C11 × **C13** | D | F | F | V | **F** | – | F | 1484 |
| C11 × **C14** | E | F | F | V | V | **F** | F | 1484 |

"–" = não avaliado (curto-circuito). Em cada par, só a condição em negrito muda, e o ramo também muda.

O xtrace mostra **cada termo** do `[[ … ]] || [[ … ]] || { … }` numa linha própria (`id_arg:1482`; era 1476 antes do TDD). Assim, a independência aparece direto no trace, e não só no desenho dos dados. Trechos de `evidencias/traces/` (regerados em 2026-11-02, sobre o código depois do TDD):

- **A** (C01 × C07): em C01, `id_arg:1482: [[ 0 -eq 0 ]]` e logo `id_arg:1483: ID=org#p1`. Em C07, `[[ 1 -eq 0 ]]`, `[[ x == -* ]]`, `[[ -n '' ]]` e então `id_arg:1484: ID=org#x`.
- **B** (C04 × C07): em C04, `[[ 1 -eq 0 ]]`, `[[ -x == -* ]]` e então `id_arg:1483`. Em C07, `[[ x == -* ]]` dá F e o fluxo segue como acima.
- **C** (C11 × C12): em C11, `[[ -n ^(on|off)$ ]]`. Em C12, `[[ -n '' ]]` e então `id_arg:1484: ID=org#on`.
- **D** (C11 × C13): em C11, `[[ on =~ ^(on|off)$ ]]` e então `pkg_root`. Em C13, `[[ foo =~ ^(on|off)$ ]]` e então `id_arg:1484` direto, sem chamar `pkg_root`.
- **E** (C11 × C14): em C11, `id_arg:1482: pkg_root` → `pkg_root:1455: return 0` → `id_arg:1483`. Em C14, `pkg_root:1456: return 1` → `id_arg:1484: ID=` → `exit 1`.

## 5. Resultados

**Execução atual, depois dos 2 ciclos de TDD** (2026-11-02, `evidencias/saida-2026-11-02.txt`): **`RESULT: 29 passed, 0 failed, 0 xfail`**, exit 0. A execução com `--trace` (que regerou os 29 traces) e a execução sob kcov deram o mesmo resultado.

**Execução anterior ao TDD**, mantida como histórico (2026-10-23, `evidencias/saida-2026-10-23.txt`): `RESULT: 19 passed, 0 failed, 4 xfail`, exit 0, com H1–H4 em XFAIL. Os casos T1–T6 ainda não existiam.

A coluna "obtido" abaixo é a da execução atual. Para H1–H4, o obtido antes do TDD está entre parênteses. As mensagens de C18 e C19 não mudaram.

| ID | dir | free | args | esperado | obtido | status | critério |
|---|---|---|---|---|---|---|---|
| C01 | pkg | '' | (nenhum) | rc0, `org#p1\|0` | rc0, `org#p1\|0` | ok | P1; MC/DC A=V |
| C02 | pkg/sub | '' | (nenhum) | rc0, `org#p1\|0` | rc0, `org#p1\|0` | ok | P2: sobe 1 nível até o pacote |
| C03 | fora | '' | (nenhum) | rc1, "falta o <id>" | rc1, `moj: falta o <id>: rode dentro da pasta de um problema …` | ok | P3: implícito sem pacote |
| C04 | pkg | '' | `-x` | rc0, `org#p1\|0` | rc0, `org#p1\|0` | ok | P4; MC/DC B=V |
| C05 | pkg | '' | `-` | rc0, `org#p1\|0` | rc0, `org#p1\|0` | ok | L1: `-` sozinho conta como opção |
| C06 | pkg | '' | `a-b` | rc0, `org#a-b\|1` | rc0, `org#a-b\|1` | ok | L2: hífen fora da 1ª posição |
| C07 | pkg | '' | `x` | rc0, `org#x\|1` | rc0, `org#x\|1` | ok | P5; par de A (C01) e de B (C04) |
| C08 | fora | '' | `org#p9` | rc0, `org#p9\|1` | rc0, `org#p9\|1` | ok | P6: id completo não depende da pasta |
| C09 | fora | '' | `x` | rc1, "não diz a org" | rc1, `moj: 'x' não diz a org: use <org>#x …` | ok | P7: nome curto sem pacote |
| C10 | fora | '' | `../pkg2` | rc0, `org2#p2\|1` | rc0, `org2#p2\|1` | ok | P8: caminho de pasta clonada |
| C11 | pkg | R | `on` | rc0, `org#p1\|0` | rc0, `org#p1\|0` | ok | P9; MC/DC base C=D=E=V |
| C12 | pkg | '' | `on` | rc0, `org#on\|1` | rc0, `org#on\|1` | ok | MC/DC C=F (par com C11) |
| C13 | pkg | R | `foo` | rc0, `org#foo\|1` | rc0, `org#foo\|1` | ok | MC/DC D=F (par com C11) |
| C14 | fora | R | `on` | rc1, "não diz a org" | rc1, `moj: 'on' não diz a org: use <org>#on …` | ok | P10; MC/DC E=F (par com C11) |
| C15 | pkg | R | `ON` | rc0, `org#ON\|1` | rc0, `org#ON\|1` | ok | L3: caixa da regex |
| C16 | pkg | R | `onn` | rc0, `org#onn\|1` | rc0, `org#onn\|1` | ok | L4: âncora da regex |
| C17 | pkg | '' | `org#p9 on` | rc0, `org#p9\|1` | rc0, `org#p9\|1` | ok | P11: com 2 argumentos, só o 1º decide |
| C18 | semid | '' | (nenhum) | rc1, "id inválido" | rc1, `moj: id inválido: '' (esperado <org>#<prob>)` | ok | P12; D4=F (implícito) |
| C19 | fora | '' | `../semid` | rc1, "id inválido" | rc1, `moj: id inválido: '' (esperado <org>#<prob>)` | ok | P13; D4=F (explícito) |
| H1 | fora | '' | `#` | rc1, "id inválido" | rc1, `moj: id inválido: '#' …` (antes: rc0, `#\|1`, XFAIL) | ok | P14; corrigido no ciclo 2 |
| H2 | fora | '' | `org#` | rc1, "id inválido" | rc1, `moj: id inválido: 'org#' …` (antes: rc0, `org#\|1`, XFAIL) | ok | P14, prob vazio; ciclo 2 |
| H3 | fora | '' | `#p` | rc1, "id inválido" | rc1, `moj: id inválido: '#p' …` (antes: rc0, `#p\|1`, XFAIL) | ok | P14, org vazia; ciclo 2 |
| H4 | semrepo | '' | `foo` | rc1 | rc1, `moj: 'foo' não diz a org: o .moj-id de …/semrepo não tem "repo" …` (antes: rc0, `#foo\|1`, XFAIL) | ok | P15; D5=F; corrigido no ciclo 1 |
| T1 | repovazio | '' | `foo` | rc1, "não diz a org" | rc1, `moj: 'foo' não diz a org: …` | ok | P15 (`repo: ""`); criado no Red do ciclo 1 |
| T2 | reponull | '' | `foo` | rc1, "não diz a org" | rc1, `moj: 'foo' não diz a org: …` | ok | P15 (`repo: null`); criado no Red do ciclo 1 |
| T3 | semrepo | '' | (nenhum) | rc0, `x#y\|0` | rc0, `x#y\|0` | ok | P16; proteção: a correção do ciclo 1 não pode barrar o id implícito |
| T4 | idsemorg | '' | (nenhum) | rc1, "id inválido" | rc1, `moj: id inválido: '#p' …` | ok | P17; D4=F pelo caminho implícito; criado no Red do ciclo 2 |
| T5 | fora | '' | `../idsemprob` | rc1, "id inválido" | rc1, `moj: id inválido: 'org#' …` | ok | P18; criado no Red do ciclo 2 |
| T6 | fora | '' | `a#b` | rc0, `a#b\|1` | rc0, `a#b\|1` | ok | L5; proteção contra correção estrita demais |

![Execução completa depois do TDD — 29 passed, 0 failed, 0 xfail](evidencias/img/execucao-completa.png)

### Traces dos pares MC/DC

![C01 × C07 — MC/DC da condição A](evidencias/img/mcdc-A.png)

![C04 × C07 — MC/DC da condição B](evidencias/img/mcdc-B.png)

![C11 × C12 — MC/DC da condição C](evidencias/img/mcdc-C.png)

![C11 × C13 — MC/DC da condição D](evidencias/img/mcdc-D.png)

![C11 × C14 — MC/DC da condição E](evidencias/img/mcdc-E.png)

### Cobertura de linhas (kcov)

Comando: `kcov --include-path="$PWD/moj" Test_Eduardo/evidencias/cobertura ./Test_Eduardo/id-arg.sh`. O kcov roda **o script** (executável, com shebang `#!/bin/bash`), e não `bash <script>`. Se rodar `bash <script>`, ele mede o binário `/usr/bin/bash` e o relatório sai vazio. O relatório fica em `evidencias/cobertura/id-arg.sh.7f1210668999291f/` (`coverage.json`, `cobertura.xml`, `index.html`). Abra o `index.html` no navegador para ver o HTML. O symlink que o kcov cria na raiz da pasta (`evidencias/cobertura/id-arg.sh`, com caminho absoluto da máquina) foi removido, porque em outro clone ele aponta para um caminho que não existe.

O kcov foi rodado de novo em 2026-11-02, sobre o código **depois dos 2 ciclos de TDD**. Este relatório considera **só** as linhas de `pkg_root`, `resolve_id`, `id_completo` e `id_arg` (1453–1486). O percentual global do arquivo `moj` não interessa aqui, porque o resto do arquivo não é alvo deste teste.

| Função | Linhas que o kcov instrumentou | Cobertas | Não cobertas |
|---|---|---|---|
| `pkg_root` | 1454, 1455, 1456, 1457, 1458 | 1454–1457 | 1458 (`done; }`) |
| `resolve_id` | 1463, 1464, 1465, 1467, 1468, 1469, 1470, 1471, 1472 | todas | — |
| `id_completo` | nenhuma (função de uma linha, na linha da definição) | — | — |
| `id_arg` | 1482, 1483, 1484, 1485 | todas | — |
| **Total** | **18** | **17** | **1** → 17/18 ≈ 94,4% das linhas instrumentadas do trecho |

Antes do TDD eram 16 linhas instrumentadas, 15 cobertas (93,75%), com a mesma linha `done; }` de fora. As 2 linhas a mais são as do `resolve_id` criadas no ciclo 1 (1470, a leitura do `repo`, com 18 hits, e 1471, a checagem com o `die`, com 12 hits), e as duas foram cobertas. A linha seguinte (1472, o `printf` do id montado) tem 6 hits: só chegam a ela as chamadas em que o `repo` existe.

- **Linha 1458 (`done; }`), 0 hits.** O laço é `while :`, que nunca termina pela condição. Ele só sai por `return 0` (linha 1455) ou `return 1` (linha 1456). Por isso a linha `done` não tem comando que possa executar. Nenhuma entrada a cobre. É artefato da instrumentação, não lacuna dos casos.
- **Linhas 1453, 1462, 1477 e 1481 não foram instrumentadas.** São as linhas `nome(){ …`, e o kcov as trata como definição de função. Mesmo assim, elas têm comandos (`local d; d="$(…)"`, `local a=… r o`, o `[[ "$1" == ?*#?* ]]` do `id_completo`, `local free="$1"; shift; IDSHIFT=0`). O xtrace mostra que esses comandos rodaram, por exemplo `id_arg:1485: id_completo org#p1` e `id_arg:1481: IDSHIFT=0` em `traces/C11.trace`. Essas linhas ficam fora da conta de 18.
- As linhas 1466 (`fi`), 1473 e 1486 (`}`) e os comentários também não são instrumentados.

**Atenção:** o kcov mede **linha executada**, não decisão nem MC/DC. A linha 1482 tem as 5 condições de D1, e ela conta como "coberta" com qualquer um dos casos. A cobertura de decisão e a de MC/DC deste relatório vêm dos traces e dos pares da seção 4, não do kcov.

![Renderização via ImageMagick dos dados do cobertura.xml do kcov (moj, linhas 1453–1486, depois do TDD); não é captura de tela.](evidencias/img/cobertura-kcov.png)

*Renderização via ImageMagick dos dados do `cobertura.xml` do kcov (moj, linhas 1453–1486, depois do TDD); não é captura de tela.*

## 6. Defeitos e hipóteses (XFAIL)

> **Situação atual:** os quatro defeitos foram **corrigidos nos 2 ciclos de TDD** de 2026-11-02 (seção 7): H4 no ciclo 1 e H1–H3 no ciclo 2. Hoje são casos obrigatórios que passam. Esta seção registra os defeitos como foram encontrados: o "obtido" abaixo é o de **antes** do TDD, e as imagens `xfail-H*.png` foram mantidas de propósito, porque mostram o "antes". As linhas citadas abaixo são as de antes do TDD.

O oráculo é o contrato `<org>#<prob>` com `org` e `prob` não vazios (seção 2). Antes do TDD, os quatro casos falhavam, como a hipótese previa, e não entravam no exit code.

### H1, H2 e H3: a validação final só confere se há `#`

- **Obtido (antes do TDD):** `moj … '#'` dá `ID='#'`, `moj … 'org#'` dá `ID='org#'` e `moj … '#p'` dá `ID='#p'`, todos com rc0 e IDSHIFT=1.
- **Por que viola o contrato:** o `die` da linha 1479 promete `(esperado <org>#<prob>)`, mas `[[ "$ID" == *#* ]]` aceita org vazia, prob vazio ou os dois vazios.
- **Como acontece em produção:** um erro de digitação como `moj publish org#` ou `moj public '#p' on`. O `resolve_id` devolve o argumento sem mudança (linha 1467, "com '#' = ele mesmo"), e o `id_arg` aceita. O comando segue para a API com um id malformado. Este teste é offline e não verificou como o servidor responde.
- **Correção sugerida** (aplicada tal qual no Green do ciclo 2 e depois refatorada para o predicado `id_completo`, seção 7):

```diff
--- a/moj
+++ b/moj
@@ id_arg
-  [[ "$ID" == *#* ]] || die "id inválido: '$ID' (esperado <org>#<prob>)"
+  [[ "$ID" == ?*#?* ]] || die "id inválido: '$ID' (esperado <org>#<prob>)"
```

O padrão `?*#?*` exige pelo menos 1 caractere antes e 1 depois de um `#`. Ele ainda aceita ids com mais de um `#` (por exemplo `a#b#c`). O contrato não diz nada sobre esse caso, e ele não foi testado.

![H1 — '#' aceito como id (antes do TDD)](evidencias/img/xfail-H1.png)

![H2 — 'org#' aceito, prob vazio (antes do TDD)](evidencias/img/xfail-H2.png)

![H3 — '#p' aceito, org vazia (antes do TDD)](evidencias/img/xfail-H3.png)

### H4: `resolve_id` monta `#foo` quando o `.moj-id` não tem `repo`

- **Obtido (antes do TDD):** dentro de `semrepo/` (`.moj-id` = `{"id":"x#y"}`), `id_arg '' foo` dá rc0 e `ID='#foo'`. O trace mostra `resolve_id:1470: printf %s#%s '' foo` e depois `id_arg:1479: [[ #foo == *#* ]]`, que dá V.
- **Por que viola o contrato:** "nome SEM a org = <org da pasta atual>#nome". Aqui a pasta não diz a org, e o resultado tem org vazia. Era o caso de chamar o mesmo `die "… não diz a org"` da linha 1469.
- **Como acontece em produção:** um `.moj-id` sem o campo `repo`. Pode ser um `.moj-id` escrito à mão, de versão antiga ou editado. O `jq -r '.repo // empty'` devolve string vazia, e o `printf` monta `#<nome>` sem reclamar.
- **Correção sugerida** (aplicada no Green do ciclo 1, que veio **antes** da de H1–H3, e depois refatorada para usar o helper `mid`, seção 7). A correção de H1–H3 também faria o `id_arg` barrar `#foo`, mas com a mensagem genérica "id inválido". A correção na origem fica em `resolve_id`:

```diff
--- a/moj
+++ b/moj
@@ resolve_id
   r="$(pkg_root)" || die "'$a' não diz a org: use <org>#$a (ou rode dentro da pasta de um problema, que dá a org)."
-  printf '%s#%s' "$(jq -r '.repo // empty' "$r/.moj-id")" "$a"
+  local o; o="$(jq -r '.repo // empty' "$r/.moj-id")"
+  [[ -n "$o" ]] || die "'$a' não diz a org: o .moj-id de $r não tem \"repo\"; use <org>#$a."
+  printf '%s#%s' "$o" "$a"
```

![H4 — '#foo' montado com repo ausente (antes do TDD)](evidencias/img/xfail-H4.png)

## 7. Aplicação de TDD (2 ciclos)

Os dois ciclos corrigem os quatro defeitos da seção 6, com autorização do Eduardo para alterar o `moj` nesta branch. Cada fase tem um commit próprio. Evidências em `evidencias/tdd/`: a saída `.txt` de cada fase, o `.diff` do que mudou nela e a regressão com os testes do upstream.

**Ordem dos ciclos.** O H4 veio **antes** do H1–H3. A correção de H1–H3 (`?*#?*` no `id_arg`) também barra o `#foo` do H4, com a mensagem genérica "id inválido". Se ela viesse primeiro, o Red do ciclo do H4 não teria nada falhando, a menos que o esperado do H4 mudasse. Corrigindo o H4 primeiro, na origem (`resolve_id`), os dois Reds falham de verdade e nenhum esperado muda. A ordem foi decisão do Eduardo.

| Ciclo | Fase | Commit | O que mudou | Resultado real |
|---|---|---|---|---|
| 1 | **Red** | `0e6c0bb` | H4 passou de XFAIL a caso obrigatório; T1, T2 e T3 foram criados | `20 passed, 3 failed, 3 xfail`, exit 1 |
| 1 | **Green** | `f65079a` | `resolve_id`: lê o `repo` numa variável e chama `die` se ele vier vazio | `23 passed, 0 failed, 3 xfail`, exit 0 |
| 1 | **Refactor** | `a3d81b9` | O `repo` passou a ser lido pelo helper `mid`, que o `moj` já tinha; `o` foi para o `local` da função | `23 passed, 0 failed, 3 xfail`, exit 0 |
| 2 | **Red** | `fd2ccd2` | H1, H2 e H3 passaram de XFAIL a casos obrigatórios; T4, T5 e T6 foram criados | `24 passed, 5 failed, 0 xfail`, exit 1 |
| 2 | **Green** | `7d29027` | `id_arg`: `*#*` virou `?*#?*` | `29 passed, 0 failed, 0 xfail`, exit 0 |
| 2 | **Refactor** | `3da7f3e` | A regra virou o predicado `id_completo`, com comentário | `29 passed, 0 failed, 0 xfail`, exit 0 |

Regressão: depois do Green e do Refactor de cada ciclo, os testes do upstream que são offline e tocam o `moj` rodaram **sem alteração** e sem falha: `push-exit.sh` (9 passed), `translations.sh` (15 passed), `parallel-conf.sh` (16 passed) e `portabilidade.sh` (15 ok).

### Ciclo 1: nome sem org numa pasta cujo `.moj-id` não diz a org (H4)

**Evolução dos testes (Red).**
- **H4 mudou de tipo** (`caso H` → `caso C`). O esperado **não mudou**: rc1, com qualquer mensagem.
- **T1 (novo):** `.moj-id` com `"repo":""`, esperado rc1 com "não diz a org". O H4 cobre o campo ausente; o T1 mostra que o defeito também acontece com o campo vazio (no Red: rc0, `#foo`).
- **T2 (novo):** `.moj-id` com `"repo":null`, mesmo esperado (no Red: rc0, `#foo`). Era uma das lacunas da seção 8 ("`null` explícito, string vazia").
- **T3 (novo, proteção):** a mesma pasta `semrepo/`, **sem argumento**. Esperado rc0, `x#y|0`: sem argumento o id vem do `.id` da pasta, que existe, e a correção não pode barrar esse caminho. T3 já passava no Red e continua passando.
- T1 e T2 exigem a mensagem "não diz a org", e não só o rc1. Assim eles provam que quem recusa é o `resolve_id` (a origem), e não a validação final do `id_arg`, que o ciclo 2 também vai apertar.

![TDD ciclo 1 — RED: H4, T1 e T2 falham, 20 passed, 3 failed, 3 xfail, exit 1](evidencias/img/tdd-ciclo1-red.png)

**Evolução da implementação.** Green, a correção mínima:

```diff
@@ resolve_id
   r="$(pkg_root)" || die "'$a' não diz a org: use <org>#$a (ou rode dentro da pasta de um problema, que dá a org)."
-  printf '%s#%s' "$(jq -r '.repo // empty' "$r/.moj-id")" "$a"
+  local o; o="$(jq -r '.repo // empty' "$r/.moj-id")"
+  [[ -n "$o" ]] || die "'$a' não diz a org: o .moj-id de $r não tem \"repo\"; use <org>#$a."
+  printf '%s#%s' "$o" "$a"
```

![TDD ciclo 1 — diff do GREEN](evidencias/img/tdd-ciclo1-green-diff.png)

![TDD ciclo 1 — GREEN: 23 passed, 0 failed, 3 xfail](evidencias/img/tdd-ciclo1-green.png)

Refactor:

```diff
-resolve_id(){ local a="${1:-}" r
+resolve_id(){ local a="${1:-}" r o
@@
-  local o; o="$(jq -r '.repo // empty' "$r/.moj-id")"
+  o="$(mid "$r" repo)"    # a org do nome sem org; "repo" ausente, null ou "" = a pasta NÃO diz a org
```

![TDD ciclo 1 — diff do REFACTOR (acumulado do ciclo)](evidencias/img/tdd-ciclo1-refactor-diff.png)

![TDD ciclo 1 — REFACTOR: 23 passed, 0 failed, 3 xfail](evidencias/img/tdd-ciclo1-refactor.png)

**Refatorações realizadas.**
1. **Reuso de um helper existente.** O `moj` já tem `mid <pasta> <campo>` (linha 1448), que lê um campo do `.moj-id`. O `resolve_id` tinha a leitura escrita à mão.
2. **Declaração junto das outras.** A variável `o` foi para o `local a … r o` do início da função, como `a` e `r`, em vez de um `local` no meio do código.
3. **Comentário com a regra:** `repo` ausente, `null` ou `""` quer dizer que a pasta não diz a org.
4. **Efeito colateral conhecido:** o `mid` descarta o erro do jq (`2>/dev/null`). Com um `.moj-id` de JSON quebrado, antes saía o erro do jq e depois o `die`; agora sai só o `die`. Nenhum caso cobre JSON quebrado (seção 8).

![TDD ciclo 1 — regressão: 4 testes do upstream, 0 falhas](evidencias/img/tdd-ciclo1-regressao.png)

### Ciclo 2: o id final tem org e problema não vazios (H1, H2, H3)

**Evolução dos testes (Red).**
- **H1, H2 e H3 mudaram de tipo** (`caso H` → `caso C`). Os esperados **não mudaram**: rc1 com "id inválido".
- **T4 (novo):** pasta `idsemorg/` com `.id` = `#p`, **sem argumento**. Esperado rc1 "id inválido". H1–H3 testam o id vindo do argumento; T4 mostra que o id implícito, lido da pasta, tinha o mesmo defeito (no Red: rc0, `#p|0`).
- **T5 (novo):** argumento `../idsemprob`, pasta clonada cujo `.id` = `org#`. Esperado rc1 "id inválido" (no Red: rc0, `org#|1`). É o terceiro caminho de entrada do id (argumento, pasta atual, pasta clonada).
- **T6 (novo, proteção):** `a#b`, o limite mínimo válido (1 caractere de cada lado). Esperado rc0, `a#b|1`. Uma correção estrita demais (por exemplo, exigir 2 caracteres) seria pega aqui. T6 já passava no Red e continua passando.

![TDD ciclo 2 — RED: H1, H2, H3, T4 e T5 falham, 24 passed, 5 failed, 0 xfail, exit 1](evidencias/img/tdd-ciclo2-red.png)

**Evolução da implementação.** Green, a correção mínima, de um caractere de cada lado:

```diff
@@ id_arg
-  [[ "$ID" == *#* ]] || die "id inválido: '$ID' (esperado <org>#<prob>)"
+  [[ "$ID" == ?*#?* ]] || die "id inválido: '$ID' (esperado <org>#<prob>)"
```

![TDD ciclo 2 — diff do GREEN](evidencias/img/tdd-ciclo2-green-diff.png)

![TDD ciclo 2 — GREEN: 29 passed, 0 failed, 0 xfail](evidencias/img/tdd-ciclo2-green.png)

Refactor:

```diff
+# id_completo <id> -> 0 se o id tem a forma <org>#<prob> com org E problema NÃO vazios (o contrato do die abaixo).
+# `?*#?*`: pelo menos 1 caractere antes e 1 depois de um '#'. Barra '#', 'org#' e '#p' (vindos do argumento, do
+# .id da pasta ou de uma pasta clonada).
+id_completo(){ [[ "$1" == ?*#?* ]]; }
@@ id_arg
-  [[ "$ID" == ?*#?* ]] || die "id inválido: '$ID' (esperado <org>#<prob>)"
+  id_completo "$ID" || die "id inválido: '$ID' (esperado <org>#<prob>)"
```

![TDD ciclo 2 — diff do REFACTOR (acumulado do ciclo)](evidencias/img/tdd-ciclo2-refactor-diff.png)

![TDD ciclo 2 — REFACTOR: 29 passed, 0 failed, 0 xfail](evidencias/img/tdd-ciclo2-refactor.png)

**Refatorações realizadas.**
1. **A regra ganhou nome.** `?*#?*` é um padrão de glob pouco legível; `id_completo "$ID"` diz o que se quer.
2. **O comentário explica o padrão** e lista os três caminhos de entrada que ele protege.
3. **O que NÃO foi feito:** trocar o `*#*` do próprio `resolve_id` (linha 1467, "com '#' = ele mesmo") pelo `id_completo`. Isso **mudaria o comportamento**: um argumento `#p` deixaria de ser tratado como id e cairia no ramo de nome curto. Mudar comportamento pede um ciclo novo, começando por um teste vermelho.

![TDD ciclo 2 — regressão: 4 testes do upstream, 0 falhas](evidencias/img/tdd-ciclo2-regressao.png)

### Dificuldades

- **A ordem dos ciclos importava.** As duas correções se sobrepõem: a do `id_arg` mascara o defeito do `resolve_id`. Foi preciso perceber isso antes de começar, senão o 2º Red nasceria verde.
- **Casos de proteção que passam no Red.** T3 e T6 nasceram verdes, de propósito. Eles não provam o defeito; eles impedem que a correção vá longe demais (barrar o id implícito válido, ou exigir mais de 1 caractere). Isso ficou explícito nos comentários do script e aqui.
- **Mensagem como parte do esperado.** Para provar **onde** o defeito foi corrigido (na origem ou na validação final), T1 e T2 exigem a mensagem "não diz a org". O esperado do H4 ficou como estava (só o rc1).
- **Regressão limitada.** O teste do upstream que exercita o id implícito de ponta a ponta (`pull-push.sh`) fala com um servidor de verdade e não pôde ser usado.

### Benefícios observados

- **Os XFAIL viraram o Red sem esforço.** H1–H4 já eram testes executáveis; promover cada um a obrigatório foi o primeiro passo de cada ciclo, sem mudar esperado.
- **Escrever o teste antes ampliou o defeito.** T1/T2 (valor vazio e `null`) e T4/T5 (id implícito e pasta clonada) mostraram que cada defeito tinha mais de uma porta de entrada.
- **Refatorar sem medo.** Os refactors trocaram uma leitura por um helper e um padrão por um predicado; os mesmos números antes e depois, mais a regressão do upstream, mostram que o comportamento ficou igual.
- **A refatoração revelou uma fronteira.** Ao procurar onde reusar o `id_completo` apareceu o `*#*` do `resolve_id`, que tem outro papel (reconhecer o id completo) e não pode ser trocado sem mudar comportamento.

## 8. Lacunas e limitações

- **Condições dentro do `jq`.** O xtrace não enxerga o que acontece dentro de `jq -r '.id // empty'` e `jq -r '.repo // empty'`. Os testes cobrem campo presente (C01, C07) e campo ausente (C18, H4). O ciclo 1 do TDD acrescentou `repo` como string vazia (T1) e `null` (T2). Continuam sem caso: tipo errado (ex.: `repo` numérico) e JSON quebrado. Com JSON quebrado, o helper `mid` (ciclo 1) descarta o erro do jq (`2>/dev/null`), e o usuário só vê o "não diz a org".
- **Comandos nas linhas de definição de função.** O kcov não instrumenta as linhas 1453, 1462, 1477 e 1481 (depois do TDD), embora elas tenham comandos. Quem mostra que esses comandos rodaram é o xtrace (seção 5).
- **`pkg_root` com argumento.** O ramo em que `cd "${1:-.}"` falha (`|| return 1` na linha 1453) não foi exercitado. O `id_arg` sempre chama `pkg_root` sem argumento.
- **`-z "$d"` na linha 1456.** Esse termo não fica V (seção 4).
- **Script do repo, não o artefato.** Os testes rodam o `moj` do repo. O `CLAUDE.md` do upstream manda testar também o `dist/moj` gerado pelo `mkdist.sh`. Isso não foi feito aqui, nem depois do TDD. As funções testadas não dependem da `lib/core.sh` embutida, a não ser pelo `die`.
- **Ids com mais de um `#`, espaços ou caracteres especiais.** Não há caso para eles, porque estão fora da análise combinada. O `?*#?*` do ciclo 2 ainda aceita `a#b#c`; o contrato não diz nada sobre esse caso.
- **Regressão do TDD.** Foram rodados os 4 testes do upstream que são offline e tocam o `moj` (`push-exit`, `translations`, `parallel-conf`, `portabilidade`). O `test/pull-push.sh`, que exercita o id implícito de ponta a ponta, **não** foi rodado: ele fala com um servidor MOJ de verdade, e estes testes são offline.
- **Documentação do upstream.** O `CLAUDE.md` do upstream pede README e cabeçalho atualizados quando muda o contrato de um comando. As mensagens de erro novas não foram levadas ao README: este trabalho só altera `Test_Eduardo/` e as funções testadas.
- **Caminhos temporários nos traces.** Os traces trazem caminhos do `mktemp` (`/tmp/tmp.XXXX`), que mudam a cada execução.
- **Cobertura.** O kcov mede só linha (ver a ressalva na seção 5). Não há medida automática de decisão nem de MC/DC.

## 9. Uso de Inteligência Artificial

- **Ferramentas:** Claude (chat) e Claude Code (agente no terminal).
- **Análise e derivação dos casos (Claude, no chat):** a análise do código de `id_arg`, `resolve_id` e `pkg_root` e a derivação dos casos de teste. Isso inclui as partições, os valores limite, os pares MC/DC e as hipóteses de defeito H1–H4.
- **Implementação e evidências (Claude Code):** a escrita e a execução do script `id-arg.sh`. A geração das evidências: saída, traces, imagens e cobertura com o kcov. A redação deste relatório, incluindo as correções sugeridas em diff.
- **Ciclos de TDD (Claude Code, 2026-11-02):** a escrita dos casos do Red (T1–T6), as correções do Green, os Refactors, a regressão e a regeração das evidências, sob pedido e autorização do Eduardo para alterar o `moj` nesta branch. A ordem dos ciclos (H4 antes de H1–H3) foi decisão do Eduardo, a partir de uma pergunta do agente.
- **Revisão e decisões (Eduardo):** a revisão do material e as decisões sobre os oráculos e sobre o que entra neste relatório.
- **Autorização:** a professora da disciplina autorizou o uso de IA neste trabalho.

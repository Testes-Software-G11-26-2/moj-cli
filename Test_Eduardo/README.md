# Test_Eduardo — M10 `id_arg` (moj-cli)

Testes de unidade do método M10 `id_arg` (arquivo `moj`), feitos pelo Eduardo para a disciplina Testes de Software (FGA0314), Grupo 11. Os quatro defeitos encontrados (H1–H4) foram corrigidos em **2 ciclos de TDD** (Red → Green → Refactor).

O relatório completo está em **[testes-eduardo-m10.md](testes-eduardo-m10.md)**: contrato, caixa-preta, caixa-branca (MC/DC), resultados, defeitos, os 2 ciclos de TDD (seção 7) e lacunas. O texto de apoio para o relatório final da equipe está em [subsidios-relatorio-final-m10.md](subsidios-relatorio-final-m10.md).

## Pré-requisitos

- bash 5 e jq (testado com bash 5.3.20 e jq 1.8.2);
- kcov, só para medir a cobertura (testado com kcov 43).

O teste é **offline**: não usa rede nem o MOJ real. A configuração vem de uma fixture em `mktemp -d`, apagada no fim; nenhuma configuração da máquina é lida.

## Como executar

Na raiz do `moj-cli`:

```bash
bash Test_Eduardo/id-arg.sh            # execução normal
bash Test_Eduardo/id-arg.sh --trace    # também grava evidencias/traces/<ID>.trace (xtrace)
kcov --include-path="$PWD/moj" Test_Eduardo/evidencias/cobertura ./Test_Eduardo/id-arg.sh   # cobertura de linhas
bash test/push-exit.sh; bash test/translations.sh; bash test/parallel-conf.sh; bash test/portabilidade.sh   # regressão do TDD (upstream, offline)
```

Resultado esperado: `RESULT: 29 passed, 0 failed, 0 xfail` e exit 0. Antes do TDD eram `19 passed, 0 failed, 4 xfail`: os 4 XFAIL eram os defeitos H1–H4 (seção 6 do relatório), que viraram casos obrigatórios nos Reds e foram corrigidos nos Greens. O exit é 1 só se um caso obrigatório falhar.

Para o kcov, rode o **script executável** (`./Test_Eduardo/id-arg.sh`), não `bash <script>`: no segundo caso o kcov mede o próprio bash e o relatório sai vazio.

## Ver os ciclos de TDD

Cada fase tem um commit próprio nesta branch:

| Ciclo | Fase | Commit | Resultado |
|---|---|---|---|
| 1 (H4, `resolve_id`) | Red | `0e6c0bb` | `20 passed, 3 failed, 3 xfail` (exit 1) |
| 1 | Green | `f65079a` | `23 passed, 0 failed, 3 xfail` |
| 1 | Refactor | `a3d81b9` | `23 passed, 0 failed, 3 xfail` |
| 2 (H1–H3, `id_arg`) | Red | `fd2ccd2` | `24 passed, 5 failed, 0 xfail` (exit 1) |
| 2 | Green | `7d29027` | `29 passed, 0 failed, 0 xfail` |
| 2 | Refactor | `3da7f3e` | `29 passed, 0 failed, 0 xfail` |

Para ver um teste falhar no Red: `git checkout 0e6c0bb && bash Test_Eduardo/id-arg.sh` (volte com `git checkout test/eduardo-m10`). As saídas e os diffs de cada fase estão em `evidencias/tdd/`.

## Onde estão as evidências

| Caminho | Conteúdo |
|---|---|
| `id-arg.sh` | o script de teste |
| `evidencias/saida-2026-11-02.txt` | saída completa da execução atual (depois do TDD) |
| `evidencias/saida-2026-10-23.txt` | saída de antes do TDD (histórico) |
| `evidencias/traces/` | xtrace de cada caso (código depois do TDD) |
| `evidencias/cobertura/index.html` | relatório de cobertura do kcov, depois do TDD (abrir no navegador); dados em `id-arg.sh.7f1210668999291f/cobertura.xml` |
| `evidencias/tdd/` | saída e diff de cada fase dos 2 ciclos de TDD, e a regressão com os testes do upstream |
| `evidencias/img/` | imagens usadas no relatório |

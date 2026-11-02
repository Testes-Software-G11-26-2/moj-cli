# Subsídios para o relatório final — M10 `id_arg` (Eduardo)

Rascunho para ajudar a montar o **relatório técnico da equipe** (atividade 3). Segue a ordem de seções que o enunciado pede. Os números vêm das execuções reais registradas em `testes-eduardo-m10.md` (o relatório de testes deste método), e cada item aponta a seção onde está a evidência. As partes gerais (projeto, técnicas) são iguais às das branches do M14 e do M15 e só precisam entrar uma vez no relatório final.

## Introdução (contribuição)

O M10 é o método do Eduardo no `moj-cli` (os outros dois, M14 e M15, estão no `cdmoj`). O `id_arg` decide **sobre qual problema** um comando da CLI vai agir: o id `<org>#<prob>` pode vir do argumento ou ser deduzido da pasta onde o usuário está. Quase todo comando que mexe em problema passa por ele (`publish`, `public`, `log`, `download`, `validate`…). Um erro aqui manda a ação para o problema errado ou deixa passar um id malformado.

## Descrição do projeto (parte do moj-cli)

O MOJ é o juiz online da UnB. O `moj-cli` é a ferramenta de linha de comando em bash usada por autores de problemas e organizadores (`moj`, `moj-contest`, `moj-comp`). O script `moj` é um arquivo único grande; com `MOJ_CLI_LIB_ONLY=1` ele só define as funções, sem executar comando — é o "modo biblioteca" que os testes do upstream também usam. O M10 usa duas auxiliares: `resolve_id` (monta o id) e `pkg_root` (acha a pasta do problema subindo até um `.moj-id`, como o git acha o `.git`).

## Planejamento dos testes

- **Escopo:** teste de unidade, offline, do `id_arg` junto com `resolve_id` e `pkg_root` reais. `MOJ_CONFIG_DIR` aponta para a fixture; nenhuma configuração da máquina é lida.
- **Fixture:** árvore de pastas em `mktemp -d` com `.moj-id` de vários formatos (pacote, subpasta, pasta clonada, `.moj-id` sem `repo`, pasta fora de pacote).
- **Oráculo:** o comentário das três funções, a mensagem do `die` (*"esperado <org>#<prob>"*), o cabeçalho do `moj` (*"ORG = quem edita"*) e o uso pelos chamadores (todos fazem `shift "$IDSHIFT"`).
- **Critério de saída:** todo caso obrigatório passa; hipótese de defeito vira XFAIL; nenhum esperado é alterado para fazer passar.

## Descrição das técnicas utilizadas

- **Caixa-preta:** partições da pasta atual (pacote, subpasta, fora de pacote, `.moj-id` sem campos), do 1º argumento (ausente, opção `-x`, id completo, nome sem org, palavra que casa a regex do chamador) e da regex `free` (vazia ou não). Uma partição inválida por caso (seção 3).
- **Caixa-branca:** quatro decisões; a D1 tem **cinco condições** (`A ∨ B ∨ (C ∧ D ∧ E)`), cobertas por **MC/DC** com cinco pares (seção 4). Curto-circuito e mascaramento documentados.
- **Evidência de caminho:** xtrace por caso — aqui o trace mostra **cada termo** da D1 numa linha própria, então a independência de cada condição aparece direto no trace.
- **Cobertura de linhas:** kcov (seção 5).
- **TDD:** os defeitos ficaram registrados como XFAIL e depois foram corrigidos em **2 ciclos** Red/Green/Refactor nesta branch (seção 7 do relatório).

## Testes desenvolvidos

- Script `id-arg.sh`, no estilo dos testes do upstream: 29 casos — `29 passed, 0 failed, 0 xfail` depois do TDD (antes: 23 casos, `19 passed, 0 failed, 4 xfail`).
- **Defeitos encontrados** (seção 6):
  - H1, H2, H3: a validação final só confere se **existe um `#`**, então `#`, `org#` e `#p` são aceitos como id (org ou problema vazio), contra a promessa do próprio `die`;
  - H4: com um `.moj-id` sem o campo `repo`, o `resolve_id` monta `#foo` (org vazia) em vez de reclamar.
- Correções sugeridas em diff (`?*#?*` no `id_arg`; checagem de org vazia no `resolve_id`). **Aplicadas nos 2 ciclos de TDD** (com autorização do Eduardo) e depois refatoradas (helper `mid` e predicado `id_completo`).

## Métricas de cobertura

| Métrica | Valor medido | Como |
|---|---|---|
| Linhas das funções (1453–1486, depois do TDD) | 17 de 18 instrumentadas cobertas (≈ 94,4%) | `cobertura.xml` do kcov, regerado em 2026-11-02 (antes do TDD: 15 de 16, 93,75%) |
| Linha não coberta | 1458 (`done; }` de um `while :`) | **inatingível**: o laço só sai por `return` |
| Decisões (V e F) | D1–D4 com os dois lados exercitados | tabela da seção 4 |
| MC/DC de D1 | 5 de 5 condições com par independente | pares da seção 4 + imagens `mcdc-*.png` |

Ressalvas: a porcentagem vale **só** para o trecho das três funções, não para o arquivo `moj` inteiro. As linhas de definição de função (1453, 1462, 1477, 1481) têm comandos que o kcov não instrumenta; o xtrace mostra que eles rodaram.

## Descrição do processo de TDD

Dois ciclos completos nesta branch (seção 7 do relatório; evidências em `evidencias/tdd/`), um commit por fase:

| Ciclo | Fase | O que mudou | Resultado |
|---|---|---|---|
| 1 (H4) | Red | H4 de XFAIL a obrigatório; T1 (`repo:""`), T2 (`repo:null`), T3 (proteção: id implícito) | `20 passed, 3 failed, 3 xfail`, exit 1 |
| 1 | Green | `resolve_id` chama `die` se o `repo` vier vazio | `23 passed, 0 failed, 3 xfail` |
| 1 | Refactor | leitura pelo helper `mid`, que já existia | `23 passed, 0 failed, 3 xfail` |
| 2 (H1–H3) | Red | H1–H3 de XFAIL a obrigatórios; T4 (id implícito `#p`), T5 (pasta clonada `org#`), T6 (proteção: `a#b`) | `24 passed, 5 failed, 0 xfail`, exit 1 |
| 2 | Green | `id_arg`: `*#*` → `?*#?*` | `29 passed, 0 failed, 0 xfail` |
| 2 | Refactor | predicado `id_completo` | `29 passed, 0 failed, 0 xfail` |

Regressão sem falhas nos testes do upstream offline que tocam o `moj` (push-exit 9, translations 15, parallel-conf 16, portabilidade 15). Ponto de destaque: a **ordem** dos ciclos. A correção do `id_arg` também barraria o defeito do `resolve_id`; corrigindo o H4 primeiro, os dois Reds falharam de verdade e nenhum esperado mudou.

## Análise crítica (contribuição do M10)

**Complementaridade entre caixa-preta e caixa-branca.**
- A caixa-preta, a partir do contrato `<org>#<prob>`, gerou as entradas `#`, `org#` e `#p` (H1–H3), que o código aceita.
- A caixa-branca mostrou que a D1 tem cinco condições e que o curto-circuito **mascara** D e E na maioria dos casos — sem os pares de MC/DC, a condição E (`pkg_root` falhar) poderia nunca ser exercitada isoladamente.
- O H4 só apareceu combinando as duas: a partição "`.moj-id` sem `repo`" (caixa-preta) e o trace do `printf '%s#%s' '' foo` (caixa-branca).

**Qualidade da testabilidade.**
- *Ajuda:* o modo biblioteca (`MOJ_CLI_LIB_ONLY=1`) e a configuração por variável de ambiente (`MOJ_CONFIG_DIR`) permitem testar funções isoladas sem rede.
- *Atrapalha:* o resultado sai em **variáveis globais** (`ID`, `IDSHIFT`), não em retorno; o erro sai com `exit` (o `die` encerra o processo), então cada caso precisa de um subshell.
- *Atrapalha:* a função depende da **pasta atual** (`pwd -P`); a fixture teve de criar árvores reais e fazer `cd` em cada caso.

**Dificuldades de testar um sistema real.**
- Arquivo único com milhares de linhas: as linhas do roteiro já tinham mudado; foi preciso localizar as funções pelo nome.
- Interpretar o contrato: "org vazia é inválida?" não está escrito com todas as letras — foi deduzido da mensagem do `die` e do cabeçalho. A hipótese depende dessa leitura, e isso ficou registrado.
- O artefato distribuído (`dist/moj`, gerado pelo `mkdist.sh`) não foi testado — só o script do repositório.

**Limitações das técnicas aplicadas.**
- Condições dentro do `jq` (`.id // empty`, `.repo // empty`) não são vistas pelo xtrace; `null` explícito, tipo errado e JSON quebrado ficaram fora.
- kcov mede linha: a linha da D1 conta como coberta com qualquer caso; o MC/DC vem dos traces.
- Ids com mais de um `#` ou caracteres especiais não foram particionados.

**Impacto do TDD no design e na manutenção.**
- Escrever H1–H4 como teste antes de pensar na correção expôs que o problema é **um só** (a validação final é fraca demais), e que H4 tem também uma causa na origem (`resolve_id`). A correção sugerida ataca os dois pontos.
- Os XFAIL deixaram o defeito executável: nos ciclos de TDD, promovê-los a obrigatórios foi o Red, sem mudar nenhum esperado.
- Escrever T1–T6 antes da correção mostrou que cada defeito tinha mais de uma porta de entrada (valor vazio e `null`; id implícito e pasta clonada), e os casos de proteção (T3, T6) impediram correções largas ou estritas demais.

**Lições aprendidas.**
- Validação por "contém `#`" é um exemplo clássico de pós-condição fraca; o teste de limite (strings mínimas `#`, `org#`, `#p`) é o que a pega.
- kcov precisa rodar o **script executável**; com `bash <script>` ele mede o binário do bash e o relatório sai vazio.
- O xtrace é uma ferramenta de MC/DC barata quando cada condição fica num `[[ ]]` próprio.

## Conclusão (contribuição)

O M10 foi testado com 23 casos (19 obrigatórios e 4 hipóteses de defeito), 15 de 16 linhas instrumentadas cobertas (a restante é inatingível) e MC/DC completo das cinco condições da decisão principal. Os quatro defeitos encontrados permitiam que um id sem org ou sem problema chegasse à API. Eles foram corrigidos em 2 ciclos de TDD, que acrescentaram seis casos (T1–T6): hoje são 29 casos, todos obrigatórios e passando, com 17 de 18 linhas instrumentadas cobertas e sem regressão nos testes do upstream.

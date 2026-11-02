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
- **TDD:** os defeitos ficaram registrados como XFAIL (o "vermelho"); o ciclo completo Red/Green/Refactor foi feito no M15 (branch `test/eduardo-m15` do cdmoj).

## Testes desenvolvidos

- Script `id-arg.sh`, no estilo dos testes do upstream: 23 casos — `19 passed, 0 failed, 4 xfail`.
- **Defeitos encontrados** (seção 6):
  - H1, H2, H3: a validação final só confere se **existe um `#`**, então `#`, `org#` e `#p` são aceitos como id (org ou problema vazio), contra a promessa do próprio `die`;
  - H4: com um `.moj-id` sem o campo `repo`, o `resolve_id` monta `#foo` (org vazia) em vez de reclamar.
- Correções sugeridas em diff (`?*#?*` no `id_arg`; checagem de org vazia no `resolve_id`). **Não aplicadas.**

## Métricas de cobertura

| Métrica | Valor medido | Como |
|---|---|---|
| Linhas das três funções (1453–1480) | 15 de 16 instrumentadas cobertas (93,75%) | relatório do kcov |
| Linha não coberta | 1458 (`done; }` de um `while :`) | **inatingível**: o laço só sai por `return` |
| Decisões (V e F) | D1–D4 com os dois lados exercitados | tabela da seção 4 |
| MC/DC de D1 | 5 de 5 condições com par independente | pares da seção 4 + imagens `mcdc-*.png` |

Ressalvas: a porcentagem vale **só** para o trecho das três funções, não para o arquivo `moj` inteiro. As linhas de definição de função (1453, 1462, 1475) têm comandos que o kcov não instrumenta; o xtrace mostra que eles rodaram.

## Descrição do processo de TDD

No M10 o TDD ficou na primeira etapa: cada hipótese de defeito foi escrita como teste **antes** de qualquer correção e registrada falhando (XFAIL H1–H4). A correção não foi aplicada. O ciclo completo (Red → Green → Refactor, um commit por fase) está documentado na branch do M15.

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
- Os XFAIL deixam o defeito executável: aplicada a correção, o teste vira XPASS e pode ser promovido a caso obrigatório.

**Lições aprendidas.**
- Validação por "contém `#`" é um exemplo clássico de pós-condição fraca; o teste de limite (strings mínimas `#`, `org#`, `#p`) é o que a pega.
- kcov precisa rodar o **script executável**; com `bash <script>` ele mede o binário do bash e o relatório sai vazio.
- O xtrace é uma ferramenta de MC/DC barata quando cada condição fica num `[[ ]]` próprio.

## Conclusão (contribuição)

O M10 foi testado com 23 casos (19 obrigatórios e 4 hipóteses de defeito), 15 de 16 linhas instrumentadas cobertas (a restante é inatingível) e MC/DC completo das cinco condições da decisão principal. Os quatro defeitos encontrados permitem que um id sem org ou sem problema chegue à API. As correções estão propostas em diff e não foram aplicadas.

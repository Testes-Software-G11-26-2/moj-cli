# Test_Eduardo — M10 `id_arg` (moj-cli)

Testes de unidade do método M10 `id_arg` (arquivo `moj`), feitos pelo Eduardo para a disciplina Testes de Software (FGA0314), Grupo 11.

O relatório completo está em **[testes-eduardo-m10.md](testes-eduardo-m10.md)**: contrato, caixa-preta, caixa-branca (MC/DC), resultados, defeitos e lacunas. O texto de apoio para o relatório final da equipe está em [subsidios-relatorio-final-m10.md](subsidios-relatorio-final-m10.md).

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
```

Resultado esperado: `RESULT: 19 passed, 0 failed, 4 xfail` e exit 0. Os 4 XFAIL são defeitos encontrados e documentados (seção 6 do relatório); eles não quebram o exit code. O exit é 1 só se um caso obrigatório falhar.

Para o kcov, rode o **script executável** (`./Test_Eduardo/id-arg.sh`), não `bash <script>`: no segundo caso o kcov mede o próprio bash e o relatório sai vazio.

## Onde estão as evidências

| Caminho | Conteúdo |
|---|---|
| `id-arg.sh` | o script de teste |
| `evidencias/saida-2026-10-23.txt` | saída completa da execução |
| `evidencias/traces/` | xtrace de cada caso |
| `evidencias/cobertura/index.html` | relatório de cobertura do kcov (abrir no navegador); dados em `id-arg.sh.7f1210668999291f/cobertura.xml` |
| `evidencias/img/` | imagens usadas no relatório |

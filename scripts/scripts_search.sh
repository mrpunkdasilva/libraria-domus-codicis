#!/bin/bash

# Script para buscar arquivos no projeto por palavras-chave no nome.

# Garante que o script funcione a partir da raiz do projeto, não importa de onde seja chamado.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT" || exit

# Verifica se algum termo de busca foi fornecido
if [ $# -eq 0 ]; then
  echo "Uso: $0 <termo1> [termo2] ..."
  echo "Exemplo: $0 \"java\" \"network\""
  exit 1
fi

echo "Buscando por arquivos que contenham todos os termos: $@"
echo "---------------------------------"

# Constrói o comando de busca dinamicamente.
# Começa com 'find' para listar todos os arquivos no diretório raiz.
SEARCH_CMD="find . -type f"

# Adiciona um 'grep -i' para cada termo de busca fornecido como argumento.
for term in "$@"; do
  # Adiciona a pipe e o grep. A busca é case-insensitive (-i).
  # O termo é colocado entre aspas simples para evitar problemas com caracteres especiais.
  SEARCH_CMD+=" | grep -i -- '$term'"
done

# Executa o comando construído usando 'eval'.
# 'eval' é necessário para que as pipes (|) na string do comando sejam interpretadas corretamente pelo shell.
RESULT_COUNT=$(eval "$SEARCH_CMD" | wc -l)

if [ "$RESULT_COUNT" -gt 0 ]; then
  eval "$SEARCH_CMD"
else
  echo "Nenhum arquivo encontrado."
fi

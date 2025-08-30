#!/bin/bash

# Script para atualizar uma seção de estatísticas no arquivo README.md.

# Garante que o script funcione a partir da raiz do projeto
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT" || exit

STATS_GENERATOR_SCRIPT="./scripts/generate_book_stats.sh"
STATS_FILE="./data/book_stats.json"
README_FILE="./README.md"
START_MARKER="<!-- STATS:START -->"
END_MARKER="<!-- STATS:END -->"

# Passo 1: Gera as estatísticas mais recentes.
echo "Passo 1/4: Gerando estatísticas atualizadas..."
if ! bash "$STATS_GENERATOR_SCRIPT"; then
  echo "Erro: Falha ao gerar o arquivo de estatísticas."
  exit 1
fi

if [ ! -f "$STATS_FILE" ]; then
  echo "Arquivo de estatísticas ($STATS_FILE) não encontrado após a execução do script."
  exit 1
fi
echo "Estatísticas geradas com sucesso."

# Passo 2: Prepara o README.md.
echo "Passo 2/4: Verificando o arquivo README.md..."
if [ ! -f "$README_FILE" ]; then
  echo "# Libraria Domus Codicis" > "$README_FILE"
  echo -e "\n$START_MARKER\n$END_MARKER" >> "$README_FILE"
  echo "Arquivo README.md criado com os marcadores."
elif ! grep -q "$START_MARKER" "$README_FILE"; then
  echo -e "\n$START_MARKER\n$END_MARKER" >> "$README_FILE"
  echo "Marcadores de estatísticas adicionados ao README.md."
fi

# Passo 3: Lê os dados do JSON e formata o conteúdo Markdown.
echo "Passo 3/4: Lendo dados do JSON e formatando a saída..."
TOTAL_BOOKS=$(grep 'total_books' "$STATS_FILE" | sed 's/[^0-9]*//g')
LAST_UPDATED=$(grep 'last_updated_utc' "$STATS_FILE" | cut -d '"' -f 4)

STATS_TABLE="| Formato | Quantidade |\n|:---|---:|\n"
FORMAT_LINES=$(grep -A 1000 '"count_by_format"' "$STATS_FILE" | grep -B 1000 '}' | tail -n +2 | head -n -1 | sed 's/[ \",]//g')
while read -r line; do
  if [ -n "$line" ]; then
    format=$(echo "$line" | cut -d ':' -f 1)
    count=$(echo "$line" | cut -d ':' -f 2)
    STATS_TABLE+="| $format | $count |\n"
  fi
done <<< "$FORMAT_LINES"

CONTENT="\n## Estatísticas da Biblioteca\n\n"
CONTENT+="**Total de Livros:** $TOTAL_BOOKS\n\n"
CONTENT+="$STATS_TABLE"
CONTENT+="\nÚltima atualização: $LAST_UPDATED\n"

# Passo 4: Substitui o conteúdo entre os marcadores no README.md.
echo "Passo 4/4: Atualizando o README.md..."
TEMP_README=$(mktemp)
trap 'rm -f -- "$TEMP_README"' EXIT

awk -v content="$CONTENT" '
  BEGIN { in_block=0 }
  /<!-- STATS:END -->/ { print; in_block=0; next }
  /<!-- STATS:START -->/ { print; print content; in_block=1; next }
  !in_block { print }
' "$README_FILE" > "$TEMP_README"

mv "$TEMP_README" "$README_FILE"

echo "README.md atualizado com sucesso!"

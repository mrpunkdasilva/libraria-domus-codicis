#!/bin/bash

# Script para contar livros em diversos formatos e gerar um arquivo JSON com as estatísticas.

# Determina o diretório raiz do projeto (um nível acima do diretório do script)
# para garantir que os caminhos funcionem independentemente de onde o script é chamado.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Garante que o diretório de saída exista na raiz do projeto
mkdir -p "$PROJECT_ROOT/data"

# Define os formatos de arquivo a serem contados
FORMATS="pdf epub mobi azw azw3 lit cbr cbz djvu doc docx odt rtf txt md mp3 m4a m4b ogg flac"
OUTPUT_FILE="$PROJECT_ROOT/data/book_stats.json"
TOTAL_COUNT=0
# Usamos um array associativo para armazenar a contagem por formato
declare -A COUNT_BY_FORMAT

echo "Iniciando contagem de livros a partir de: $PROJECT_ROOT"

# Itera sobre cada formato e conta os arquivos correspondentes
for ext in $FORMATS; do
  # O comando find procura no diretório raiz do projeto por arquivos (-type f)
  # com nomes que correspondem ao padrão "*.$ext" (insensível a maiúsculas/minúsculas com -iname).
  count=$(find "$PROJECT_ROOT" -type f -iname "*.$ext" | wc -l)

  # Adiciona à contagem apenas se arquivos daquele formato forem encontrados
  if [ "$count" -gt 0 ]; then
    COUNT_BY_FORMAT[$ext]=$count
    TOTAL_COUNT=$((TOTAL_COUNT + count))
    echo " - Encontrados $count arquivos .$ext"
  fi
done

echo "Total de livros encontrados: $TOTAL_COUNT"
echo "Gerando arquivo JSON em $OUTPUT_FILE..."

# --- Geração do JSON ---
json_output="{
"
json_output+="  \"total_books\": $TOTAL_COUNT,\n"
json_output+="  \"count_by_format\": {\n"

keys=("${!COUNT_BY_FORMAT[@]}")
num_keys=${#keys[@]}
i=0

for ext in "${keys[@]}"; do
  count=${COUNT_BY_FORMAT[$ext]}
  json_output+="    \"$ext\": $count"
  if [ $i -lt $((num_keys - 1)) ]; then
    json_output+=","
  fi
  json_output+="\n"
  i=$((i + 1))
done

json_output+="  },\n"
json_output+="  \"last_updated_utc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"\n"
json_output+="}\n"

echo -e "$json_output" > "$OUTPUT_FILE"

echo "Arquivo $OUTPUT_FILE gerado com sucesso."
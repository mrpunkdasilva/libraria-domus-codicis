#!/bin/bash

# Script para normalizar nomes de arquivos: remove acentos, padroniza para minúsculas,
# substitui espaços por underscores e adiciona o nome da pasta imediata como prefixo.

# Garante que o script funcione a partir da raiz do projeto
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT" || exit

echo "Iniciando normalização de nomes de arquivos..."

# Função para normalizar uma string: remove acentos, minúsculas, espaços para underscore, remove caracteres inválidos.
normalize_string() {
  local input="$1"
  # 1. Translitera para ASCII (removes acentos)
  # 2. Converte para minúsculas
  # 3. Substitui espaços por underscores
  # 4. Remove caracteres que não são letras, números, underscore ou hífen (mantém ponto para extensões)
  # 5. Remove múltiplos underscores seguidos
  # 6. Remove underscores no início ou fim
  echo "$input" | \
  iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/[[:space:]]/_/g' | \
  sed 's/[^a-z0-9_.-]//g' | \
  sed 's/__*/_/g' | \
  sed 's/^_//;s/_$//'
}

# Itera sobre todos os arquivos no repositório Git (excluindo .git e _trash)
# Usamos -z e read -d '' para lidar com nomes de arquivo com espaços/caracteres especiais.
git ls-files -z | while IFS= read -r -d '' original_path; do
  # Ignora diretórios .git e _trash
  if [[ "$original_path" == .git/* ]] || [[ "$original_path" == _trash/* ]]; then
    continue
  fi

  # Extrai o diretório e o nome base do arquivo
  dir_name=$(dirname "$original_path")
  base_name=$(basename "$original_path")
  
  # Extrai a extensão do arquivo
  extension="${base_name##*.}"
  filename_without_ext="${base_name%.*}"

  # Normaliza o nome do arquivo sem extensão
  normalized_filename_without_ext=$(normalize_string "$filename_without_ext")

  # Normaliza o nome da pasta imediata (se não for a raiz do projeto)
  normalized_dir_prefix=""
  if [[ "$dir_name" != "." ]]; then # Se não estiver na raiz
    # Pega apenas o último componente do diretório
    last_dir_component=$(basename "$dir_name")
    normalized_dir_prefix=$(normalize_string "$last_dir_component")
    # Adiciona um underscore se houver um prefixo de diretório
    if [ -n "$normalized_dir_prefix" ]; then
      normalized_dir_prefix="${normalized_dir_prefix}_"
    fi
  fi

  # Constrói o novo nome base do arquivo (com prefixo da pasta, se houver)
  new_base_name="${normalized_dir_prefix}${normalized_filename_without_ext}"
  
  # Adiciona a extensão de volta, se houver
  if [ -n "$extension" ] && [[ "$base_name" == *.* ]]; then # Garante que só adicione extensão se o original tinha
    new_base_name="${new_base_name}.${extension}"
  fi

  # Constrói o novo caminho completo
  new_path="$dir_name/$new_base_name"

  # Compara o caminho original com o novo caminho
  if [[ "$original_path" != "$new_path" ]]; then
    echo "Renomeando: '$original_path' -> '$new_path'"
    # Usa git mv para renomear o arquivo
    if ! git mv "$original_path" "$new_path"; then
      echo "ERRO: Falha ao renomear '$original_path'. Abortando."
      exit 1
    fi
  fi
done

echo "Normalização de nomes de arquivos concluída."
echo "As alterações foram adicionadas ao staging do Git. Por favor, revise e commite."

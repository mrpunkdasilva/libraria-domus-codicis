#!/bin/bash

# Script to commit and push each new or modified PDF file individually.

# Determina o diretório raiz do projeto para garantir a execução correta.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Muda para o diretório raiz do projeto antes de executar qualquer coisa
cd "$PROJECT_ROOT" || exit

echo "Buscando por arquivos PDF novos ou modificados na raiz do projeto..."

# Get a list of new (untracked) and modified PDF files.
MODIFIED_FILES=$(git ls-files --modified --others --exclude-standard '*.pdf')

if [ -z "$MODIFIED_FILES" ]; then
  echo "Nenhum arquivo PDF novo ou modificado encontrado."
  exit 0
fi

# Use a while loop to read each line, which handles filenames with spaces correctly.
while IFS= read -r file; do
  echo "---------------------------------"
  echo "Processando arquivo: $file"

  # Stage the file
  git add "$file"
  if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao adicionar o arquivo '$file' ao stage. Abortando."
    exit 1
  fi

  # Commit the file
  git commit -m "feat: Update book '$file'"
  if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao commitar o arquivo '$file'. Abortando."
    # Unstage the file before exiting
    git reset HEAD "$file"
    exit 1
  fi

  # Push the commit
  echo "Enviando arquivo para o repositório remoto..."
  git push
  if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao enviar o arquivo '$file'. Abortando."
    echo "Por favor, tente fazer o push manualmente para resolver o problema."
    exit 1
  fi

  echo "Arquivo '$file' enviado com sucesso."
done <<< "$MODIFIED_FILES"

echo "---------------------------------"
echo "Todos os arquivos PDF foram processados e enviados com sucesso."
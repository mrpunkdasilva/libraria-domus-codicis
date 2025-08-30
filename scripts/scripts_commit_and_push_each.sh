#!/bin/bash

# Script to commit and push each new or modified PDF file individually.

# Determina o diretório raiz do projeto para garantir a execução correta.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Muda para o diretório raiz do projeto antes de executar qualquer coisa
cd "$PROJECT_ROOT" || exit

echo "Buscando por arquivos PDF novos ou modificados na raiz do projeto..."

# Usa `git ls-files -z` para obter uma lista de arquivos terminada em NUL, que é a forma mais robusta
# de lidar com nomes de arquivos que contêm espaços, acentos ou outros caracteres especiais.
# A saída é passada para um loop `while`, que lê até o delimitador NUL (`-d ''`).
git ls-files --modified --others --exclude-standard -z '*.pdf' | while IFS= read -r -d '' file; do
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
done

# Verifica o código de saída do `git ls-files` para ver se algum arquivo foi encontrado.
# Se a saída for vazia, o `while` loop não executa. Precisamos de uma verificação separada.
if ! git ls-files --modified --others --exclude-standard '*.pdf' | read -r; then
    echo "Nenhum arquivo PDF novo ou modificado encontrado."
fi

echo "---------------------------------"
echo "Processo concluído."

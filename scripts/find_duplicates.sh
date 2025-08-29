#!/bin/bash

# Script para encontrar e, opcionalmente, limpar arquivos duplicados ou falhar para uso em CI.

# Garante que o script funcione a partir da raiz do projeto
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT" || exit

# --- Análise dos Parâmetros ---
MODE="list" # Modo padrão: apenas listar
if [ "$1" == "--interactive-delete" ]; then
  MODE="interactive"
elif [ "$1" == "-y" ]; then
  MODE="auto_delete"
elif [ "$1" == "--fail" ]; then
  MODE="fail"
fi

# --- Configuração do Diretório da Lixeira ---
if [ "$MODE" == "interactive" ] || [ "$MODE" == "auto_delete" ]; then
  TRASH_DIR="$PROJECT_ROOT/_trash"
  echo "MODO DE LIMPEZA ATIVADO."
  if ! mkdir -p "$TRASH_DIR"; then
    echo "Erro: Não foi possível criar o diretório da lixeira em $TRASH_DIR."
    exit 1
  fi
  echo "Arquivos selecionados serão movidos para: $TRASH_DIR"
  echo ""
fi

echo "Iniciando verificação de arquivos duplicados..."

# Cria um arquivo temporário de forma segura
TEMP_FILE=$(mktemp)
# Garante que o arquivo temporário seja removido ao final da execução
trap 'rm -f -- "$TEMP_FILE"' EXIT

echo "Passo 1/2: Calculando assinaturas digitais (MD5)..."
find . -path ./.git -prune -o -type f -print0 | xargs -0 md5sum > "$TEMP_FILE"

echo "Passo 2/2: Analisando e agrupando os resultados..."
echo "---------------------------------"

# --- LÓGICA PRINCIPAL ---
AWK_SCRIPT='
  function print_if_duplicate() { if (count > 1) { printf "Os %d arquivos a seguir são idênticos (hash: %s):\n", count, previous_hash; print file_list; printf "\n"; found_duplicates = 1; } }
  { current_hash = $1; current_file = ""; for (i = 2; i <= NF; i++) { current_file = current_file (i == 2 ? "" : " ") $i; } if (NR > 1 && current_hash != previous_hash) { print_if_duplicate(); count = 0; file_list = ""; } previous_hash = current_hash; count++; file_list = file_list (file_list == "" ? "" : "\n") "  - " current_file; }
  END { print_if_duplicate(); exit !found_duplicates; }'

case "$MODE" in
  "fail")
    echo "Modo CI: Verificando se existem duplicatas..."
    DUPLICATES_LIST=$(sort "$TEMP_FILE" | awk "$AWK_SCRIPT")
    AWK_EXIT_CODE=$?
    if [ $AWK_EXIT_CODE -eq 0 ]; then
      echo "ERRO: Arquivos duplicados foram encontrados! A verificação falhou."
      echo "---------------------------------"
      echo "$DUPLICATES_LIST"
      exit 1
    else
      echo "Nenhum arquivo duplicado encontrado. Verificação passou."
      exit 0
    fi
    ;;

  "auto_delete")
    echo "Iniciando limpeza automática (modo -y)..."
    cut -c -32 "$TEMP_FILE" | sort | uniq -d | while read -r hash; do
      echo "Processando grupo de duplicatas (hash: $hash):"
      mapfile -t files < <(grep "^$hash" "$TEMP_FILE" | cut -c 35-)
      shortest_file="${files[0]}"
      for file in "${files[@]}"; do if [ ${#file} -lt ${#shortest_file} ]; then shortest_file="$file"; fi; done
      echo "  - Mantendo: '$shortest_file'"
      for file in "${files[@]}"; do if [ "$file" != "$shortest_file" ]; then echo "  - Movendo para lixeira: '$file'"; mv -- "$file" "$TRASH_DIR/$(basename -- "$file").$(date +%s)"; fi; done
    done
    echo "---------------------------------"
    echo "Limpeza automática concluída."
    ;;

  "interactive")
    cut -c -32 "$TEMP_FILE" | sort | uniq -d | while read -r hash; do
      echo "Grupo de duplicatas encontrado (hash: $hash):"
      mapfile -t files < <(grep "^$hash" "$TEMP_FILE" | cut -c 35-)
      PS3="Qual arquivo mover para a lixeira? (Digite o número ou 's' para pular): "
      select file_to_trash in "${files[@]}"; do
        if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ "$REPLY" -ge 1 ] && [ "$REPLY" -le "${#files[@]}" ]; then
          echo "Movendo '$file_to_trash' para a lixeira..."
          mv -- "$file_to_trash" "$TRASH_DIR/$(basename -- "$file_to_trash").$(date +%s)"
          break
        elif [[ "$REPLY" == "s" || "$REPLY" == "S" ]]; then
          echo "Pulando este grupo."
          break
        else
          echo "Opção inválida. Tente novamente."
        fi
      done
      echo "---------------------------------"
    done
    echo "Limpeza interativa concluída."
    ;;

  *) 
    # Modo padrão: apenas listar
    DUPLICATES_LIST=$(sort "$TEMP_FILE" | awk "$AWK_SCRIPT")
    AWK_EXIT_CODE=$?
    if [ $AWK_EXIT_CODE -eq 0 ]; then
      echo "Arquivos duplicados encontrados:"
      echo "---------------------------------"
      echo "$DUPLICATES_LIST"
      echo "Para limpar, rode o script com a opção --interactive-delete ou -y"
    else
      echo "Nenhum arquivo duplicado encontrado."
    fi
    ;;
esac
import subprocess
import os
import sys

# Define the 50MB limit in bytes (50 * 1024 * 1024)
MAX_PUSH_SIZE_BYTES = 52428800

def run_git_command(command, cwd, error_message):
    """Helper function to run git commands and handle errors."""
    try:
        result = subprocess.run(command, cwd=cwd, check=True, capture_output=True, text=True)
        print(result.stdout)
        if result.stderr:
            print(f"Stderr: {result.stderr}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERRO: {error_message}")
        print(f"Comando: {' '.join(e.cmd)}")
        print(f"Stdout: {e.stdout}")
        print(f"Stderr: {e.stderr}")
        return False
    except FileNotFoundError:
        print("ERRO: Comando 'git' não encontrado. Certifique-se de que o Git está instalado e no PATH.")
        return False

def process_batch(batch_files, project_root):
    """Adds, commits, and pushes a batch of files."""
    if not batch_files:
        return True

    print("---------------------------------")
    print(f"Processando lote de arquivos ({len(batch_files)} arquivos)...")

    # 1. Add files to stage
    add_command = ["git", "add"] + batch_files
    if not run_git_command(add_command, project_root, "Falha ao adicionar arquivos ao stage."):
        return False

    # 2. Create commit message
    if len(batch_files) == 1:
        commit_message = f"feat: Update book '{os.path.basename(batch_files[0])}'"
    else:
        # For multiple files, list up to 3 for brevity, then generalize
        file_names = [os.path.basename(f) for f in batch_files[:3]]
        if len(batch_files) > 3:
            commit_message = f"feat: Update multiple PDF books ({', '.join(file_names)} e outros)"
        else:
            commit_message = f"feat: Update PDF books ({', '.join(file_names)})"

    # 3. Commit files
    commit_command = ["git", "commit", "-m", commit_message]
    if not run_git_command(commit_command, project_root, "Falha ao commitar arquivos."):
        # If commit fails, unstage files to allow retry
        run_git_command(["git", "reset", "HEAD", "--"] + batch_files, project_root, "Falha ao resetar stage após erro de commit.")
        return False

    # 4. Push commit
    print("Enviando lote para o repositório remoto...")
    push_command = ["git", "push"]
    if not run_git_command(push_command, project_root, "Falha ao enviar lote para o repositório remoto."):
        print("Por favor, tente fazer o push manualmente para resolver o problema.")
        return False

    print(f"Lote de arquivos enviado com sucesso.")
    return True

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))

    os.chdir(project_root) # Ensure we are in the project root

    print("Buscando por arquivos PDF novos ou modificados na raiz do projeto...")

    # Get new or modified PDF files
    try:
        git_ls_files_command = ["git", "ls-files", "--modified", "--others", "--exclude-standard", "-z", "*.pdf"]
        result = subprocess.run(git_ls_files_command, cwd=project_root, check=True, capture_output=True, text=True)
        # Split by null character and filter out empty strings
        files = [f for f in result.stdout.split('\0') if f]
    except subprocess.CalledProcessError as e:
        print("ERRO: Falha ao listar arquivos Git.")
        print(f"Comando: {' '.join(e.cmd)}")
        print(f"Stdout: {e.stdout}")
        print(f"Stderr: {e.stderr}")
        sys.exit(1)
    except FileNotFoundError:
        print("ERRO: Comando 'git' não encontrado. Certifique-se de que o Git está instalado e no PATH.")
        sys.exit(1)

    if not files:
        print("Nenhum arquivo PDF novo ou modificado encontrado.")
        print("---------------------------------")
        print("Processo concluído.")
        sys.exit(0)

    current_batch = []
    current_batch_size = 0

    for file_path in files:
        full_file_path = os.path.join(project_root, file_path)
        try:
            file_size = os.path.getsize(full_file_path)
        except FileNotFoundError:
            print(f"AVISO: Arquivo '{file_path}' não encontrado, pulando.")
            continue

        if file_size >= MAX_PUSH_SIZE_BYTES:
            print(f"AVISO: Arquivo '{file_path}' ({file_size / (1024*1024):.2f} MB) excede o limite de 50MB para um único push. Ele não será processado.")
            # If there's a current batch, process it before skipping this large file
            if current_batch:
                if not process_batch(current_batch, project_root):
                    sys.exit(1)
                current_batch = []
                current_batch_size = 0
            continue

        if current_batch_size + file_size > MAX_PUSH_SIZE_BYTES:
            # Process the current batch before starting a new one
            if not process_batch(current_batch, project_root):
                sys.exit(1)
            current_batch = []
            current_batch_size = 0

        current_batch.append(file_path)
        current_batch_size += file_size

    # Process any remaining files in the last batch
    if current_batch:
        if not process_batch(current_batch, project_root):
            sys.exit(1)

    print("---------------------------------")
    print("Processo concluído.")

if __name__ == "__main__":
    main()

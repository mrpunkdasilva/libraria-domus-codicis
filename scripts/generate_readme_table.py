import json
import os
import re

def generate_markdown_table(books_data):
    """
    Generates a Markdown table string from book data.
    Uses only 'title_clean' for the 'Book Title' column.
    Other columns (Description, Language, Tags) will be empty.
    """
    header = "| Book Title | Description | Language | Tags |\n"
    separator = "| :--- | :--- | :--- | :--- |\n"
    
    table_rows = []
    for book in books_data:
        title = book.get("title_clean", book.get("name", "N/A")) # Fallback to 'name' if 'title_clean' is missing
        # Ensure title is properly escaped for Markdown if it contains pipes
        title = title.replace("|", "\\|")
        
        # All other fields are empty as per user's instruction
        description = ""
        language = ""
        tags = ""
        
        table_rows.append(f"| [{title}](./{book.get('path', '')}) | {description} | {language} | {tags} |")
    
    # Sort rows alphabetically by title
    table_rows.sort()

    return header + separator + "\n".join(table_rows)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    books_json_path = os.path.join(project_root, "books.json")
    readme_path = os.path.join(project_root, "README.md")

    print(f"Lendo o arquivo: {books_json_path}")

    books_data = []
    try:
        with open(books_json_path, "r", encoding="utf-8") as f:
            books_data = json.load(f)
    except FileNotFoundError:
        print(f"ERRO: O arquivo {books_json_path} não foi encontrado.")
        return
    except json.JSONDecodeError:
        print(f"ERRO: O arquivo {books_json_path} não é um JSON válido.")
        return

    print("Gerando conteúdo da tabela do README.md...")
    new_table_content = generate_markdown_table(books_data)

    print(f"Lendo o arquivo: {readme_path}")
    readme_content = ""
    try:
        with open(readme_path, "r", encoding="utf-8") as f:
            readme_content = f.read()
    except FileNotFoundError:
        print(f"ERRO: O arquivo {readme_path} não foi encontrado.")
        return

    # Define markers for the table section
    start_marker = "## Library Catalog\n\n| Book Title | Description | Language | Tags |\n| :--- | :--- | :--- | :--- |\n"
    end_marker = "\n## Scripts de Automação"

    # Find the start and end of the existing table
    start_index = readme_content.find(start_marker)
    end_index = readme_content.find(end_marker, start_index)

    if start_index == -1 or end_index == -1:
        print("ERRO: Não foi possível encontrar os marcadores da tabela 'Library Catalog' no README.md.")
        print("Certifique-se de que o README.md contém a estrutura esperada.")
        return

    # Extract content before and after the table
    before_table = readme_content[:start_index + len(start_marker)]
    after_table = readme_content[end_index:]

    # Construct the new README content
    updated_readme_content = before_table + new_table_content + after_table

    print(f"Atualizando o arquivo: {readme_path}")
    try:
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(updated_readme_content)
        print("README.md atualizado com sucesso!")
    except IOError as e:
        print(f"ERRO: Falha ao escrever no arquivo {readme_path}: {e}")

if __name__ == "__main__":
    main()

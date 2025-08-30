import json
import os
import re

def clean_title(filename):
    """
    Cleans a filename to create a readable title.
    Removes .pdf extension, replaces underscores with spaces,
    and normalizes spaces.
    """
    # Remove .pdf extension
    if filename.lower().endswith(".pdf"):
        title = filename[:-4]
    else:
        title = filename

    # Replace underscores with spaces
    title = title.replace("_", " ")

    # Normalize spaces (replace multiple spaces with single, strip leading/trailing)
    title = re.sub(r'\s+', ' ', title).strip()

    return title

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, "../data/"))
    books_json_path = os.path.join(project_root, "books.json")

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

    print("Processando títulos dos livros...")
    updated_count = 0
    for book in books_data:
        if "name" in book:
            cleaned_title = clean_title(book["name"])
            if "title_clean" not in book or book["title_clean"] != cleaned_title:
                book["title_clean"] = cleaned_title
                updated_count += 1
        else:
            print(f"AVISO: Entrada de livro sem a chave 'name': {book}")

    if updated_count > 0:
        print(f"Atualizando {updated_count} títulos no books.json...")
        try:
            with open(books_json_path, "w", encoding="utf-8") as f:
                json.dump(books_data, f, indent=2, ensure_ascii=False)
            print("books.json atualizado com sucesso!")
        except IOError as e:
            print(f"ERRO: Falha ao escrever no arquivo {books_json_path}: {e}")
    else:
        print("Nenhum título precisou ser atualizado no books.json.")

if __name__ == "__main__":
    main()

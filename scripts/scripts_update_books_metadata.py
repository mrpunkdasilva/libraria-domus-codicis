import json
import os
import re
import threading
import queue
from pypdf import PdfReader

# Constants
BOOKS_JSON_PATH = "books.json"
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
NUM_THREADS = os.cpu_count() * 2 if os.cpu_count() else 4 # Use more threads for I/O bound tasks

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

def extract_pdf_metadata(pdf_absolute_path):
    """
    Extracts metadata from a PDF file.
    Returns a dictionary with extracted metadata.
    """
    metadata = {
        "description": "",
        "language": "",
        "tags": []
    }
    try:
        reader = PdfReader(pdf_absolute_path)
        info = reader.metadata
        if info:
            if info.title:
                metadata["description"] = info.title.strip()
            if info.author:
                # Could add author as a separate field if needed
                pass
            if info.subject:
                metadata["tags"].extend([tag.strip() for tag in info.subject.split(',') if tag.strip()])
            if info.keywords:
                metadata["tags"].extend([tag.strip() for tag in info.keywords.split(',') if tag.strip()])
            # Deduplicate tags
            metadata["tags"] = sorted(list(set(metadata["tags"])))

            # Language is not commonly in standard PDF metadata,
            # but if it were, it might be in /Lang entry in PDF catalog
            # pypdf.PdfReader.metadata doesn't expose it directly.
            # For now, we'll leave it empty or infer later if needed.

    except Exception as e:
        print(f"AVISO: Não foi possível extrair metadados de '{pdf_absolute_path}': {e}")
    return metadata

def worker_thread(pdf_queue, results_queue):
    """Worker thread to extract metadata from PDFs."""
    while True:
        pdf_absolute_path = pdf_queue.get()
        if pdf_absolute_path is None: # Sentinel to stop the thread
            pdf_queue.task_done()
            break

        metadata = extract_pdf_metadata(pdf_absolute_path)
        results_queue.put((pdf_absolute_path, metadata))
        pdf_queue.task_done()

def main():
    print("Iniciando atualização de metadados dos livros...")

    # 1. Load existing books.json
    books_data = []
    books_map = {} # Map original_name to book object for quick updates
    try:
        with open(os.path.join(PROJECT_ROOT, BOOKS_JSON_PATH), "r", encoding="utf-8") as f:
            books_data = json.load(f)
            for book in books_data:
                if "name" in book:
                    books_map[book["name"]] = book
    except FileNotFoundError:
        print(f"AVISO: O arquivo {BOOKS_JSON_PATH} não foi encontrado. Será criado um novo.")
    except json.JSONDecodeError:
        print(f"ERRO: O arquivo {BOOKS_JSON_PATH} não é um JSON válido. Verifique o conteúdo.")
        return

    # 2. Find all PDF files in the repository (excluding _trash)
    all_pdf_files = []
    for root, dirs, files in os.walk(PROJECT_ROOT):
        # Exclude _trash directory from os.walk
        if '_trash' in dirs:
            dirs.remove('_trash')
        # Exclude .git directory
        if '.git' in dirs:
            dirs.remove('.git')

        for file in files:
            if file.lower().endswith(".pdf"):
                absolute_path = os.path.join(root, file)
                relative_path = os.path.relpath(absolute_path, PROJECT_ROOT)
                all_pdf_files.append((absolute_path, relative_path))

    if not all_pdf_files:
        print("Nenhum arquivo PDF encontrado no repositório (excluindo _trash).")
        return

    # Prepare queues for threading
    pdf_queue = queue.Queue()
    results_queue = queue.Queue()

    # Start worker threads
    threads = []
    for _ in range(NUM_THREADS):
        thread = threading.Thread(target=worker_thread, args=(pdf_queue, results_queue))
        thread.daemon = True # Allow main program to exit even if threads are still running
        threads.append(thread)
        thread.start()

    # Populate the queue with PDF paths
    for absolute_path, _ in all_pdf_files:
        pdf_queue.put(absolute_path)

    # Wait for all tasks to be done
    pdf_queue.join()

    # Add sentinels to stop worker threads
    for _ in range(NUM_THREADS):
        pdf_queue.put(None)
    for thread in threads:
        thread.join() # Ensure all threads have finished

    print("Extração de metadados concluída. Atualizando books.json...")

    # Process results and update books_data
    new_books_data = []
    processed_original_names = set() # To track books already processed from file system

    while not results_queue.empty():
        pdf_absolute_path, metadata = results_queue.get()
        relative_path = os.path.relpath(pdf_absolute_path, PROJECT_ROOT)
        original_filename = os.path.basename(pdf_absolute_path)

        book_entry = books_map.get(original_filename)

        if book_entry:
            # Update existing entry
            book_entry["path"] = relative_path
            book_entry["title_clean"] = clean_title(original_filename)
            book_entry["description"] = metadata["description"]
            book_entry["language"] = metadata["language"]
            book_entry["tags"] = metadata["tags"]
            # Ensure coverSvg exists, if not, add a placeholder
            if "coverSvg" not in book_entry:
                book_entry["coverSvg"] = "<svg>...</svg>" # Placeholder SVG
            processed_original_names.add(original_filename)
        else:
            # Create new entry for books found in file system but not in books.json
            new_entry = {
                "name": original_filename,
                "path": relative_path,
                "title_clean": clean_title(original_filename),
                "description": metadata["description"],
                "language": metadata["language"],
                "tags": metadata["tags"],
                "coverSvg": "<svg>...</svg>" # Placeholder SVG
            }
            books_data.append(new_entry) # Add to the main list
            processed_original_names.add(original_filename)

    # Remove books from books_data that are no longer in the file system
    # This requires iterating through the original books_data and checking if they were processed
    final_books_data = []
    for book in books_data:
        if book["name"] in processed_original_names:
            final_books_data.append(book)
        else:
            print(f"AVISO: Livro '{book['name']}' encontrado em books.json mas não no sistema de arquivos. Removendo da lista.")

    # Sort the final list by title_clean for consistency
    final_books_data.sort(key=lambda x: x.get("title_clean", x.get("name", "")).lower())

    # Save updated books.json
    try:
        with open(os.path.join(PROJECT_ROOT, BOOKS_JSON_PATH), "w", encoding="utf-8") as f:
            json.dump(final_books_data, f, indent=2, ensure_ascii=False)
        print(f"books.json atualizado com sucesso! Total de {len(final_books_data)} livros.")
    except IOError as e:
        print(f"ERRO: Falha ao escrever no arquivo {BOOKS_JSON_PATH}: {e}")

if __name__ == "__main__":
    main()

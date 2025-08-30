#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import unicodedata

def normalize_filename(filename):
    """
    Normalizes a string to be used as a safe filename in SCREAMING_SNAKE_CASE.
    - Converts to uppercase.
    - Removes accents and special characters.
    - Replaces spaces and other separators with a single underscore.
    """
    # Separate base name and extension
    base, extension = os.path.splitext(filename)

    # Convert to uppercase
    s = base.upper()

    # Remove accents (decompose and keep non-spacing marks)
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode('utf-8')

    # Remove emojis (this regex covers most common emoji ranges)
    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"  # emoticons
        "\U0001F300-\U0001F5FF"  # symbols & pictographs
        "\U0001F680-\U0001F6FF"  # transport & map symbols
        "\U0001F1E0-\U0001F1FF"  # flags (iOS)
        "\U00002702-\U000027B0"
        "\U000024C2-\U0001F251"
        "]+",
        flags=re.UNICODE,
    )
    s = emoji_pattern.sub(r'', s)

    # Replace any non-alphanumeric characters with a space
    s = re.sub(r'[^A-Z0-9]+', ' ', s)

    # Replace multiple spaces with a single space and trim
    s = re.sub(r'\s+', ' ', s).strip()

    # Replace spaces with underscores
    s = s.replace(' ', '_')

    # Handle cases where the name becomes empty or just underscores
    if not s or all(c == '_' for c in s):
        return None # Or a default name if you prefer

    # Return with the original extension, ensuring it's lowercase
    return f"{s}{extension.lower()}"

def main():
    """
    Main function to walk through directories and rename PDF files.
    """
    # The root directory of your library
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    print(f"Iniciando a limpeza de nomes de arquivos no diretório: {root_dir}\n")

    # Directories to ignore
    ignored_dirs = ['.git', '.idea', 'scripts']

    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Remove ignored directories from traversal
        dirnames[:] = [d for d in dirnames if d not in ignored_dirs]

        for filename in filenames:
            if filename.lower().endswith('.pdf'):
                old_full_path = os.path.join(dirpath, filename)
                new_filename = normalize_filename(filename)

                if new_filename and new_filename != filename:
                    new_full_path = os.path.join(dirpath, new_filename)

                    # Safety check: only rename if the new path doesn't already exist
                    if not os.path.exists(new_full_path):
                        try:
                            os.rename(old_full_path, new_full_path)
                            print(f"  Renomeado: '{filename}' -> '{new_filename}'")
                        except OSError as e:
                            print(f"  ERRO ao renomear '{filename}': {e}")
                    else:
                        print(f"  AVISO: O arquivo '{new_filename}' já existe. '{filename}' não foi renomeado.")
    
    print("\nLimpeza de nomes de arquivos concluída!")

if __name__ == "__main__":
    main()
import os
import re

CONTENT_DIR = "./"

# 1. Поиск блоков формул $$ ... $$
pattern_block = re.compile(r'(?<!\\)\$\$\s*([\s\S]*?)\s*\$\$')

# 2. Поиск "плохого" синтаксиса внутри формул
# Ищет нижнее (_) или верхнее (^) подчеркивание,
# за которым сразу идет слэш (\) и команда (например \vec{v} или \alpha),
# НО только если перед командой НЕТ открывающей скобки {.
# Группа 1: символ _ или ^
# Группа 2: сама команда (например \vec{v} или \mu)
pattern_fix_braces = re.compile(r'([_^])(?!(?:\{))(\\[a-zA-Z]+(?:\{[^}]*\})?)')

def fix_content(text):
    # Вспомогательная функция для обработки самой формулы
    def process_formula(match):
        formula = match.group(1).strip()
        
        # --- ИСПРАВЛЕНИЕ СИНТАКСИСА ---
        # Заменяем _\vec{v} на _{\vec{v}}
        # Заменяем ^\alpha на ^{\alpha}
        # re.sub запустится столько раз, сколько нужно внутри формулы
        formula = pattern_fix_braces.sub(r'\1{\2}', formula)
        
        # --- ИСПРАВЛЕНИЕ ОФОРМЛЕНИЯ ---
        return f'\n$$\n{formula}\n$$\n'

    # Запускаем поиск и замену во всем тексте
    return pattern_block.sub(process_formula, text)

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = fix_content(content)

        # Убираем лишние пустые строки (3+ подряд заменяем на 2)
        new_content = re.sub(r'\n{3,}', '\n\n', new_content)

        if content != new_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Исправлено: {filepath}")
            
    except Exception as e:
        print(f"Ошибка в файле {filepath}: {e}")

def main():
    print("Запуск скрипта исправления формул (структура + скобки)...")
    if not os.path.exists(CONTENT_DIR):
        print(f"Папка {CONTENT_DIR} не найдена!")
        return

    for root, dirs, files in os.walk(CONTENT_DIR):
        for file in files:
            if file.endswith(".md"):
                process_file(os.path.join(root, file))
    
    print("Готово!")

if __name__ == "__main__":
    main()
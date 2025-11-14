#!/bin/bash

set -e  

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SELF_DELETE=false
AUTO_MODE=false

error_exit() {
    echo -e "${RED}❌ ОШИБКА: $1${NC}" >&2
    exit 1
}

check_dependencies() {
    echo -e "${YELLOW}🔍 Проверка зависимостей...${NC}"
    
    if ! command -v git &> /dev/null; then
        error_exit "Git не установлен. Установите git сначала."
    fi
    
    if ! command -v gh &> /dev/null; then
        error_exit "GitHub CLI не установлен. Установить:\n  sudo apt install gh\nИли: https://cli.github.com/"
    fi
    
    if ! gh auth status &> /dev/null; then
        error_exit "GitHub CLI не авторизован. Выполнить:\n  gh auth login"
    fi
    
    echo -e "${GREEN}✅ Все зависимости есть${NC}"
}

get_user_input() {
    echo -e "${BLUE}🎯 Настройка нового проекта${NC}"
    
    if [ "$AUTO_MODE" = true ]; then
        repo_name="krax-plc-project"
        repo_description="Создано автоматически"
        default_branch="main"
        repo_visibility="private"
        clone_deps="y"
        
        if [[ "$(pwd)" == "$SCRIPT_DIR" ]]; then
            SELF_DELETE=true
        fi
        
        echo -e "${GREEN}📊 Автоматические настройки:${NC}"
        echo -e "  Название: ${GREEN}$repo_name${NC}"
        echo -e "  Описание: ${GREEN}$repo_description${NC}"
        echo -e "  Ветка: ${GREEN}$default_branch${NC}"
        echo -e "  Видимость: ${GREEN}$repo_visibility${NC}"
        echo -e "  Клонировать зависимости: ${GREEN}$clone_deps${NC}"
        if [[ "$(pwd)" == "$SCRIPT_DIR" ]]; then
            echo -e "  Удалить скрипт: ${GREEN}да${NC}"
        fi
        return
    fi

    read -p "$(echo -e "${YELLOW}📝 Название репозитория (по умолчанию: krax-plc-project): ${NC}")" repo_name
    repo_name=${repo_name:-"krax-plc-project"}
    
    read -p "$(echo -e "${YELLOW}📋 Описание репозитория (по умолчанию: Создано автоматически): ${NC}")" repo_description
    repo_description=${repo_description:-"Создано автоматически"}
    
    read -p "$(echo -e "${YELLOW}🌿 Основная ветка (по умолчанию: main): ${NC}")" default_branch
    default_branch=${default_branch:-"main"}
    
    read -p "$(echo -e "${YELLOW}👁️  Видимость репозитория (public/private, по умолчанию: private): ${NC}")" repo_visibility
    repo_visibility=${repo_visibility:-"private"}
    
    read -p "$(echo -e "${YELLOW}📦 Клонировать зависимости pyplc, pysca? (y/n, по умолчанию: y): ${NC}")" clone_deps
    clone_deps=${clone_deps:-"y"}
    
    if [[ "$(pwd)" == "$SCRIPT_DIR" ]]; then
        read -p "$(echo -e "${YELLOW}🗑️  Удалить этот скрипт после создания проекта? (y/n, по умолчанию: y): ${NC}")" delete_self
        delete_self=${delete_self:-"y"}
        if [[ $delete_self =~ ^[Yy]$ ]]; then
            SELF_DELETE=true
        fi
    fi
    
    echo -e "${GREEN}📊 Сводка:${NC}"
    echo -e "  Название: ${GREEN}$repo_name${NC}"
    echo -e "  Описание: ${GREEN}$repo_description${NC}"
    echo -e "  Ветка: ${GREEN}$default_branch${NC}"
    echo -e "  Видимость: ${GREEN}$repo_visibility${NC}"
    echo -e "  Клонировать зависимости: ${GREEN}$clone_deps${NC}"
    if [[ "$(pwd)" == "$SCRIPT_DIR" ]]; then
        echo -e "  Удалить скрипт: ${GREEN}$delete_self${NC}"
    fi
    
    read -p "$(echo -e "${YELLOW}🚀 Продолжить? (y/n, по умолчанию: y): ${NC}")" confirm
    confirm=${confirm:-"y"}
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Настройка отменена${NC}"
        exit 0
    fi
}

create_project_structure() {
    echo -e "${YELLOW}📁 Создание структуры проекта...${NC}"
    cd ../
    mkdir -p .vscode gui resources ui src
    
    cat > .vscode/launch.json << 'EOF'
{
    "version": "0.0.1",
    "configurations": [

        {
            "name": "Runtime",
            "type": "debugpy",
            "request": "launch",
            "module": "gui",
            "env": {"PYTHONPYCACHEPREFIX": "${workspaceFolder}/__pycache__"},
            "args": ["--device","192.168.2.10"]
        },
        {
            "name": "Simulator",
            "type": "debugpy",
            "request": "launch",
            "module": "gui",
            "env": {"PYTHONPYCACHEPREFIX": "${workspaceFolder}/__pycache__"},
            "args": ["--simulator"]
        },
        {
            "name": "Run Python File",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "env" : {"PYTHONPYCACHEPREFIX":"${workspaceFolder}/__pycache__"}
        }
    ]
}
EOF

    cat > src/krax.py << 'EOF'
"""
Main application module

Ниже идёт ваша программа
"""

from pyplc.platform import plc
from sys import platform
from collections import namedtuple

if platform=='vscode':
    PLC = namedtuple('PLC', (''))
    plc = PLC()

instances = ()

if platform=='linux':
    instances += ()
    
plc.run( instances=instances, ctx=globals() )
EOF

    cat > src/krax.csv << 'EOF'
Name;XT;Module;Channel;Description (Рекомендуется называть сигналы следующим образом: CONV_ON_1)
EOF

    cat > src/krax.json << 'EOF'
{
    // количество модулей (Аналоговый - 8, дискретный - 1. Удалить комментарий после прочтенияя)
    "slots": [ 
        8,
        1
    ],
    "node_id": 1,
    "init": {
        "hostname": "krax",
        "flags": 0,
        "iface": 0,
        "channel": 1,
        "rate": 9
    },
    "layout": [
        "08:d1:f9:27:ff:00",
        "94:b5:55:26:2d:7c",
        "b4:8a:0a:8f:06:a0",
        "b4:8a:0a:8e:fb:c0",
        "94:b5:55:f9:05:70",
        "5c:01:3b:33:22:c8",
        "b4:8a:0a:8e:ff:8c",
        "94:b5:55:2c:d6:30"
    ],
    "devs": [
        "KRAX AI-455",
        "KRAX DO-530"
    ],
    "via": "0.0.0.0"
}
EOF

    cat > gui/__main__.py << 'EOF'
import sys
from pysca import app
import pysca
from pysca.device import PYPLC
import pygui.navbar as navbar
# from concrete6 import concrete6 # для бетонного 

def main():
    import argparse
    args = argparse.ArgumentParser(sys.argv)
    args.add_argument('--device', action='store', type=str, default='192.168.2.10', help='IP address of the device')
    args.add_argument('--simulator', action='store_true', default=False, help='Same as --device 127.0.0.1')
    ns = args.parse_known_args()[0]
    if ns.simulator:
        ns.device = '127.0.0.1'
        import subprocess
        logic = subprocess.Popen(["python3", "src/krax.py"])
    
    dev = PYPLC(ns.device)
    app.devices['PLC'] = dev
    
    Home = app.window('ui/Home.ui')
    # с использованием navbar
    navbar.append(Home)       
    navbar.instance.show( )
    # concrete6.setMainWindow(navbar.instance)
    # или 

    # Home.show()               
    
    dev.start(100)
    app.start( ctx = globals() )
    dev.stop( )

    if ns.simulator:
        logic.terminate( )
        pass

if __name__=='__main__':
    main( )
EOF

    cat > gui/_version.py << 'EOF'
# file generated by setuptools_scm
# don't change, don't track in version control
TYPE_CHECKING = False
if TYPE_CHECKING:
    from typing import Tuple, Union
    VERSION_TUPLE = Tuple[Union[int, str], ...]
else:
    VERSION_TUPLE = object

version: str
__version__: str
__version_tuple__: VERSION_TUPLE
version_tuple: VERSION_TUPLE

__version__ = version = '0.0.post1+g204e31f.d20250625'
__version_tuple__ = version_tuple = (0, 0, 'g204e31f.d20250625')
EOF

    cat > docker-compose.yaml << 'EOF'
services:
  opentsdb:
    image: petergrace/opentsdb-docker
    container_name: opentsdb-trepel
    ports:
      - "4242:4242"
    networks:
      - monitoring
    environment:
      - TSD_HTTP_ENABLED=true
      - TSD_HTTP_PORT=4242 (УСТАНОВИТЬ)
      - TSD_STORAGE_HBASE=true
      - TSD_STORAGE_HBASE_ZK_QUORUM=zookeeper:2181
  grafana:
    image: grafana/grafana-oss:10.2.1
    container_name: УСТАНОВИТЬ НАЗВАНИЕ
    ports:
      - "3000:3000"
    depends_on:
      - opentsdb
    volumes:
      - ./provisioning:/etc/grafana/provisioning
      - ./dashboards:/var/lib/grafana/dashboards
    networks:
      - monitoring
    environment:
      - GF_SECURITY_ADMIN_USER=ИМЯ
      - GF_SECURITY_ADMIN_PASSWORD=ПАРОЛЬ
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_NAME=Main Org.
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
      - GF_USERS_DEFAULT_THEME=light      
networks:
  monitoring:
    driver: bridge
EOF

    cat > requirements.txt << 'EOF'
debugpy>=1.6.0
pathlib2>=2.3.0
EOF

    cat > .gitignore << 'EOF'
__pycache__/
*.pyc
*.pyo
*.pyd
.pybuild
build
debhelper-build-stamp
python3-*
.Python
env/
venv/
.venv/
.env
.idea/
.vscode/
*.swp
*.swo
*~
*.egg-info
upydev_.config
*.ex
debian
.env.local
.env*.local
*.log .env
EOF

    cat > README.md << EOF
# $repo_name

$repo_description

## Project Structure

\`\`\`
.
├── src/           # Source code
├── gui/           # GUI application
├── resources/     # Resource files
├── ui/            # UI definitions
├── .vscode/       # VS Code configuration
└── docker-compose.yaml
\`\`\`

## Quick Start

\`\`\`bash
# Run main application
python src/krax.py

# Run in simulator mode
F5 in src/krax.py
\`\`\`

## Development

This project was automatically generated using Krax setup script https://github.com/chkrain/setup-project-krax.git
EOF

    echo -e "${GREEN}✅ Структура проекта создана${NC}"
}


clone_dependencies() {
    if [[ $clone_deps =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}📦 Клонирование зависимостей...${NC}"
        
        if [ ! -d "pyplc" ]; then
            git clone https://github.com/vlinnik/pyplc.git 2>/dev/null && \
            echo -e "${GREEN}✅ pyplc склонирован${NC}" || \
            echo -e "${RED}❌ Не удалось клонировать pyplc${NC}"
        fi
        
        if [ ! -d "pysca" ]; then
            git clone https://github.com/vlinnik/pysca.git 2>/dev/null && \
            echo -e "${GREEN}✅ pysca склонирован${NC}" || \
            echo -e "${RED}❌ Не удалось клонировать pysca${NC}"
        fi
    fi
}

create_github_repo() {
    echo -e "${YELLOW}🚀 Создание репозитория на GitHub...${NC}"
    
    if [ "$SELF_DELETE" = true ]; then
        SCRIPT_DIR_TO_DELETE="$SCRIPT_DIR"
        WORK_DIR="."
    else
        WORK_DIR="."
    fi
    
    cd "$WORK_DIR"
    echo -e "${YELLOW}🔍 Проверяем созданные файлы...${NC}"
    
    # Проверяем, есть ли созданные файлы проекта
    if [ ! -f "src/krax.py" ] && [ ! -f ".vscode/launch.json" ]; then
        echo -e "${RED}❌ Файлы проекта не найдены! Возможно, проблема с созданием структуры.${NC}"
        echo -e "${YELLOW}📁 Текущая директория: $(pwd)${NC}"
        echo -e "${YELLOW}📁 Содержимое:${NC}"
        ls -la
        return 1
    fi
    
    # Проверяем только файлы, которые НЕ относятся к проекту
    existing_non_project_files=$(find . -maxdepth 1 -type f -name "*" ! -name ".git" ! -name ".gitignore" ! -name "docker-compose.yaml" ! -name "requirements.txt" ! -name "README.md" | wc -l)
    existing_non_project_dirs=$(find . -maxdepth 1 -type d ! -name "." ! -name ".git" ! -name ".vscode" ! -name "src" ! -name "gui" ! -name "resources" ! -name "ui" | wc -l)
    
    if [ "$existing_non_project_files" -gt 0 ] || [ "$existing_non_project_dirs" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  В директории есть посторонние файлы/папки:${NC}"
        # Показываем только посторонние файлы
        find . -maxdepth 1 -type f ! -name ".git" ! -name ".gitignore" ! -name "docker-compose.yaml" ! -name "requirements.txt" ! -name "README.md" 2>/dev/null || true
        find . -maxdepth 1 -type d ! -name "." ! -name ".git" ! -name ".vscode" ! -name "src" ! -name "gui" ! -name "resources" ! -name "ui" 2>/dev/null || true
        
        read -p "$(echo -e "${YELLOW}🗑️  Удалить посторонние файлы и продолжить? (y/n, по умолчанию: n): ${NC}")" delete_existing
        delete_existing=${delete_existing:-"n"}
        
        if [[ $delete_existing =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑️  Удаление посторонних файлов...${NC}"
            # Удаляем только посторонние файлы, сохраняя структуру проекта
            find . -maxdepth 1 -type f ! -name ".git" ! -name ".gitignore" ! -name "docker-compose.yaml" ! -name "requirements.txt" ! -name "README.md" -delete 2>/dev/null || true
            find . -maxdepth 1 -type d ! -name "." ! -name ".git" ! -name ".vscode" ! -name "src" ! -name "gui" ! -name "resources" ! -name "ui" -exec rm -rf {} + 2>/dev/null || true
            echo -e "${GREEN}✅ Посторонние файлы удалены${NC}"
        else
            echo -e "${YELLOW}ℹ️  Продолжаем с существующими файлами${NC}"
        fi
    fi
    
    if [ -d ".git" ]; then
        echo -e "${YELLOW}⚠️  Git репозиторий уже существует${NC}"
        read -p "$(echo -e "${YELLOW}🔄 Использовать существующий репозиторий? (y/n, по умолчанию: y): ${NC}")" use_existing_git
        use_existing_git=${use_existing_git:-"y"}
        
        if [[ ! $use_existing_git =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑️  Очищаем существующий git...${NC}"
            rm -rf .git
            git init
            git config --global init.defaultBranch "$default_branch"
        else
            echo -e "${YELLOW}🔄 Используем существующий git репозиторий${NC}"
            if git remote get-url origin &>/dev/null; then
                echo -e "${YELLOW}📥 Обновляем из remote...${NC}"
                git pull origin "$default_branch" || echo -e "${YELLOW}⚠️  Не удалось обновить из remote${NC}"
            fi
        fi
    else
        git init
        git config --global init.defaultBranch "$default_branch"
    fi
    
    if [ "$SELF_DELETE" = true ]; then
        if ! grep -q "setup-project-krax.sh" .gitignore 2>/dev/null; then
            echo "setup-project-krax.sh" >> .gitignore
        fi
        if ! grep -q "README.md" .gitignore 2>/dev/null; then
            echo "README.md" >> .gitignore
        fi
    fi
    
    echo -e "${YELLOW}📦 Добавление файлов в git...${NC}"
    
    echo -e "${YELLOW}📁 Содержимое директории:${NC}"
    ls -la
    
    # Просто добавляем все файлы, кроме явно исключенных
    if [ "$SELF_DELETE" = true ]; then
        # Добавляем все, кроме скрипта и README.md
        find . -type f -not -name "setup-project-krax.sh" -not -name "README.md" -not -path "./.git/*" | while read file; do
            git add -f "$file" 2>/dev/null || true
        done
    else
        git add .
    fi
    
    echo -e "${YELLOW}📊 Статус git:${NC}"
    git status --short
    
    if git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  Нет изменений для коммита. Проверяем неотслеживаемые файлы...${NC}"
        UNTRACKED=$(git status --porcelain | grep "^??" | wc -l)
        if [ "$UNTRACKED" -gt 0 ]; then
            echo -e "${YELLOW}📁 Найдены неотслеживаемые файлы:${NC}"
            git status --porcelain
            read -p "$(echo -e "${YELLOW}📦 Добавить все файлы в git? (y/n, по умолчанию: y): ${NC}")" add_all
            add_all=${add_all:-"y"}
            if [[ $add_all =~ ^[Yy]$ ]]; then
                git add .
                echo -e "${YELLOW}📊 Статус после добавления:${NC}"
                git status --short
            fi
        fi
    fi
    
    if git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  Все еще нет изменений для коммита${NC}"
        echo -e "${YELLOW}📁 Попробуем принудительно добавить ключевые файлы:${NC}"
        # Принудительно добавляем ключевые файлы проекта
        git add -f .vscode/ src/ gui/ resources/ ui/ docker-compose.yaml requirements.txt .gitignore README.md 2>/dev/null || true
        git status --short
    fi
    
    if ! git diff --cached --quiet; then
        git commit -m "Создано с помощью скрипта setup-project-krax.sh https://github.com/chkrain/setup-project-krax | First Commit: $repo_description"
        echo -e "${GREEN}✅ Коммит создан${NC}"
    else
        echo -e "${YELLOW}⚠️  Пропускаем коммит - нет изменений${NC}"
    fi
    
    echo -e "${YELLOW}🔍 Проверка существования репозитория на GitHub...${NC}"
    if gh repo view "$repo_name" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Репозиторий '$repo_name' уже существует на GitHub${NC}"
        read -p "$(echo -e "${YELLOW}🔄 Использовать существующий репозиторий? (y/n/rename, по умолчанию: y): ${NC}")" use_existing_repo
        use_existing_repo=${use_existing_repo:-"y"}
        
        if [[ $use_existing_repo =~ ^[Rr] ]]; then
            read -p "$(echo -e "${YELLOW}📝 Введите новое название репозитория: ${NC}")" new_repo_name
            repo_name="$new_repo_name"
            echo -e "${YELLOW}🔄 Создаем репозиторий с новым именем '$repo_name'...${NC}"
            gh repo create "$repo_name" --description "$repo_description" --"$repo_visibility" --push
        elif [[ $use_existing_repo =~ ^[Yy] ]]; then
            echo -e "${YELLOW}🔄 Подключаемся к существующему репозиторию...${NC}"
            git remote remove origin 2>/dev/null || true
            git remote add origin "https://github.com/$(gh api user --jq '.login')/$repo_name.git"
            
            echo -e "${YELLOW}📥 Получаем изменения...${NC}"
            git pull origin "$default_branch" --allow-unrelated-histories --no-edit 2>/dev/null || \
            echo -e "${YELLOW}⚠️  Не удалось объединить истории, пробуем форсировать...${NC}"
            
            echo -e "${YELLOW}📤 Отправляем изменения...${NC}"
            git push -u origin "$default_branch" --force-with-lease 2>/dev/null || \
            git push -u origin "$default_branch" --force
        else
            echo -e "${YELLOW}❌ Пропускаем создание репозитория на GitHub${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}🆕 Создаем новый репозиторий на GitHub...${NC}"
        if gh repo create "$repo_name" --description "$repo_description" --"$repo_visibility" --push; then
            echo -e "${GREEN}✅ Репозиторий создан и отправлен на GitHub${NC}"
        else
            echo -e "${RED}❌ Не удалось создать репозиторий${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}🔗 URL: https://github.com/$(gh api user --jq '.login')/$repo_name${NC}"
}

self_cleanup() {
    if [ "$SELF_DELETE" = true ]; then
        echo -e "${YELLOW}🗑️  Автоудаление скрипта...${NC}"
        
        PROJECT_PATH="$(pwd)"
        
        cd "$SCRIPT_DIR"
        cd ..
        
        if [ -d "$SCRIPT_DIR" ]; then
            rm -rf "$SCRIPT_DIR"
            echo -e "${GREEN}✅ Скрипт и временные файлы удалены${NC}"
        fi
        if [ -d "$SCRIPT_DIR_TO_DELETE" ]; then
            rm -rf "$SCRIPT_DIR_TO_DELETE"
            echo -e "${GREEN}✅ Лишняя директория ушла${NC}"
        fi
        
        cd "$PROJECT_PATH"
    fi
}

main() {
    echo -e "${BLUE}🚀 Автоматическая настройка проекта Krax${NC}"
    echo -e "${BLUE}=========================================${NC}"
    
    read -p "$(echo -e "${YELLOW}Запустить в автоматическом режиме? (y/n, по умолчанию: y): ${NC}")" auto_mode
    auto_mode=${auto_mode:-"y"}
    if [[ $auto_mode =~ ^[Yy]$ ]]; then
        AUTO_MODE=true
        echo -e "${GREEN}✅ Автоматический режим активирован${NC}"
    else
        echo -e "${YELLOW}ℹ️  Интерактивный режим${NC}"
    fi
    
    check_dependencies
    get_user_input
    
    if [ "$SELF_DELETE" = true ]; then
        echo -e "${YELLOW}📁 Подготовка директории проекта...${NC}"
        cd ..
        mkdir -p "$repo_name"
        cd "$repo_name"
    fi
    
    create_project_structure
    clone_dependencies
    create_github_repo
    self_cleanup
    
    echo -e "\n${GREEN}🎉 Настройка проекта успешно завершена!${NC}"
    echo -e "\n${YELLOW}📋 Следующие шаги:${NC}"
    echo -e "  ${GREEN}1.${NC} Перейдите: https://github.com/$(gh api user --jq '.login')/$repo_name"
    echo -e "  ${GREEN}2.${NC} Перейдите в DIY: ${GREEN}и создайте defaul.scada${NC}"
    echo -e "  ${GREEN}3.${NC} Протестируйте проект: ${GREEN}python src/krax.py${NC}"
    echo -e "  ${GREEN}4.${NC} Протестируйте симулятор: ${GREEN}F5${NC}"
    echo -e "  ${GREEN}5.${NC} KRAX создатель: ${GREEN}https://github.com/vlinnik${NC}"
    echo -e "  ${GREEN}6.${NC} Ошибка?: ${GREEN}TG @raincher${NC}"
    
    if [ "$SELF_DELETE" = false ]; then
        echo -e "  ${GREEN}7.${RED} Удалите ${NC}капс-текст или ${GREEN}выполните .${NC}сказанное им"
    fi
}

main "$@"
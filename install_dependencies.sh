#!/bin/bash

# Скрипт для проверки и установки необходимых зависимостей
# Проверяет наличие git, maven, openjdk-21-jdk и устанавливает их при необходимости

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Проверка установленных зависимостей..."
echo "========================================"

# Функция для проверки установлен ли пакет
check_installed() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 уже установлен"
        return 0
    else
        echo -e "${RED}✗${NC} $1 не установлен"
        return 1
    fi
}

# Функция для проверки Java версии
check_java_version() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [ "$JAVA_VERSION" = "21" ]; then
            echo -e "${GREEN}✓${NC} OpenJDK 21 уже установлен"
            return 0
        else
            echo -e "${YELLOW}!${NC} Установлена Java версии $JAVA_VERSION, требуется версия 21"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} Java не установлен"
        return 1
    fi
}

# Проверка прав sudo
if [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}Для установки пакетов требуются права sudo${NC}"
    fi
fi

# Массив для хранения пакетов, которые нужно установить
PACKAGES_TO_INSTALL=()

# Проверка git
if ! check_installed git; then
    PACKAGES_TO_INSTALL+=("git")
fi

# Проверка maven
if ! check_installed mvn; then
    PACKAGES_TO_INSTALL+=("maven")
fi

# Проверка Java 21
if ! check_java_version; then
    PACKAGES_TO_INSTALL+=("openjdk-21-jdk")
fi

# Если есть пакеты для установки
if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo ""
    echo "========================================"
    echo -e "${YELLOW}Необходимо установить следующие пакеты:${NC}"
    printf '%s\n' "${PACKAGES_TO_INSTALL[@]}"
    echo "========================================"
    echo ""

    read -p "Продолжить установку? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[YyДд]$ ]]; then
        echo "Обновление списка пакетов..."
        sudo apt-get update

        echo "Установка пакетов..."
        sudo apt-get install -y "${PACKAGES_TO_INSTALL[@]}"

        echo ""
        echo -e "${GREEN}========================================"
        echo "Установка завершена успешно!"
        echo "========================================${NC}"

        # Проверка установки
        echo ""
        echo "Проверка установленных версий:"
        echo "========================================"

        if [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " git " ]]; then
            git --version
        fi

        if [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " maven " ]]; then
            mvn --version
        fi

        if [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " openjdk-21-jdk " ]]; then
            java -version
        fi
    else
        echo -e "${RED}Установка отменена пользователем${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${GREEN}========================================"
    echo "Все необходимые зависимости уже установлены!"
    echo "========================================${NC}"
fi

#!/bin/bash

ROOT="$(pwd)"

find "$ROOT" -type d -name ".git" -prune | while read -r gitdir; do
    repo="$(dirname "$gitdir")"

    echo "=================================="
    echo "Обновление: $repo"
    echo "=================================="

    git -C "$repo" fetch origin

    branch=$(git -C "$repo" branch --show-current)

    if [ -n "$branch" ]; then
        git -C "$repo" reset --hard "origin/$branch"
        git -C "$repo" clean -fd
    else
        echo "Ошибка: не удалось определить ветку"
    fi

    echo
done

echo "Готово."
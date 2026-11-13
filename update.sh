#!/bin/bash

ROOT="$(pwd)"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

echo "Поиск git-репозиториев (потоков: $JOBS)..."

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

[ -d "$ROOT/.git" ] && printf '%s\0' "$ROOT/.git" > "$tmpdir/_root.out"

find "$ROOT" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null |
xargs -0 -r -P "$JOBS" -I{} bash -c '
    d="$1"; out="$2/$(printf %s "$d" | cksum | cut -d" " -f1).out"
    find "$d" \
        \( -type d \( -name node_modules -o -name .venv -o -name venv \
                       -o -name target -o -name build -o -name dist \
                       -o -name __pycache__ -o -name .cache \) -prune \) -o \
        \( -type d -name .git -prune -print0 \) \
        > "$out" 2>/dev/null
' _ "{}" "$tmpdir"


mapfile -d '' -t gitdirs < <(cat "$tmpdir"/*.out 2>/dev/null)

repos=()
for g in "${gitdirs[@]}"; do
    repos+=("${g%/.git}")
done

total=${#repos[@]}
echo "Найдено репозиториев: $total."
echo

if [ "$total" -eq 0 ]; then
    echo "Готово."
    exit 0
fi

printf '%s\0' "${repos[@]}" |
xargs -0 -r -P "$JOBS" -n 1 bash -c '
    repo="$1"
    out=$(
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
        echo
        echo "=================================="
        echo "Завершено: $repo"
        echo "=================================="
        echo
        echo
    ) 2>&1
    printf "%s\n" "$out"
' _

echo "Готово."
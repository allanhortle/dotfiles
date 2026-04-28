#!/usr/bin/env bash
# Build tree-sitter parsers into ~/.config/nvim/parser/.
# Replaces nvim-treesitter's :TSUpdate. Each entry: lang|repo|ref|location|files
# - location is "" for the repo root, or a subdir like "tsx".
# - files is a space-separated list of source files relative to <location>/src/.

set -euo pipefail

PARSER_DIR="$HOME/.config/nvim/parser"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$PARSER_DIR"

GRAMMARS=(
  "bash|https://github.com/tree-sitter/tree-sitter-bash|master||parser.c scanner.c"
  "css|https://github.com/tree-sitter/tree-sitter-css|master||parser.c scanner.c"
  "csv|https://github.com/amaanq/tree-sitter-csv|master|csv|parser.c"
  "diff|https://github.com/the-mikedavis/tree-sitter-diff|main||parser.c"
  "dockerfile|https://github.com/camdencheek/tree-sitter-dockerfile|main||parser.c"
  "gdscript|https://github.com/PrestonKnopp/tree-sitter-gdscript|master||parser.c scanner.c"
  "git_config|https://github.com/the-mikedavis/tree-sitter-git-config|main||parser.c"
  "git_rebase|https://github.com/the-mikedavis/tree-sitter-git-rebase|main||parser.c"
  "gitattributes|https://github.com/ObserverOfTime/tree-sitter-gitattributes|master||parser.c"
  "graphql|https://github.com/bkegley/tree-sitter-graphql|master||parser.c"
  "html|https://github.com/tree-sitter/tree-sitter-html|master||parser.c scanner.c"
  "javascript|https://github.com/tree-sitter/tree-sitter-javascript|master||parser.c scanner.c"
  "json|https://github.com/tree-sitter/tree-sitter-json|master||parser.c"
  "jsonc|https://gitlab.com/WhyNotHugo/tree-sitter-jsonc.git|master||parser.c"
  "prisma|https://github.com/victorhqc/tree-sitter-prisma|master||parser.c"
  "python|https://github.com/tree-sitter/tree-sitter-python|master||parser.c scanner.c"
  "sql|https://github.com/derekstride/tree-sitter-sql|gh-pages||parser.c scanner.c"
  "tsx|https://github.com/tree-sitter/tree-sitter-typescript|master|tsx|parser.c scanner.c"
  "typescript|https://github.com/tree-sitter/tree-sitter-typescript|master|typescript|parser.c scanner.c"
  "yaml|https://github.com/ikatyang/tree-sitter-yaml|master||parser.c scanner.cc"
)

build_one() {
  local entry=$1
  IFS='|' read -r lang url ref location files <<<"$entry"
  local out="$PARSER_DIR/$lang.so"
  local repo_dir="$TMP_DIR/$lang"

  echo "==> $lang"
  git clone --depth 1 --branch "$ref" "$url" "$repo_dir" >/dev/null 2>&1

  local src_dir="$repo_dir"
  [[ -n "$location" ]] && src_dir="$repo_dir/$location"
  src_dir="$src_dir/src"

  local has_cpp=0
  local src_files=()
  for f in $files; do
    src_files+=("$src_dir/$f")
    [[ "$f" == *.cc || "$f" == *.cpp ]] && has_cpp=1
  done

  local cc=cc
  [[ $has_cpp -eq 1 ]] && cc=c++

  "$cc" -shared -fPIC -O2 -I "$src_dir" "${src_files[@]}" -o "$out"
}

for entry in "${GRAMMARS[@]}"; do
  build_one "$entry"
done

echo
echo "Built $(ls "$PARSER_DIR"/*.so | wc -l | tr -d ' ') parsers in $PARSER_DIR"

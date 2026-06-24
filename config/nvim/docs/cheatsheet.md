# Neovim Cheat Sheet

## Basic Movement
- `h` `j` `k` `l` → Left, Down, Up, Right.
- `w` / `b`     → Jump to the start of the next / previous word.
- `e`           → Jump to the end of the word.
- `0` / `$`     → Go to the start / end of the line.
- `gg` / `G`    → Go to the start / end of the file.
- `ctrl + u/d`  → Move up / down half a page.

## Editing
- `i` / `a`     → Insert mode / Insert after cursor.
- `o` / `O`     → New line below / above.
- `x`           → Delete character under cursor.
- `dw`          → Delete to the end of the word.
- `dd`          → Delete (cut) current line.
- `yy`          → Copy (yank) current line.
- `p`           → Paste after cursor.
- `u` / `ctrl+r` → Undo / Redo.

## Search and Replace
- `/text`       → Search "text" forward.
- `?text`       → Search "text" backward.
- `n` / `N`     → Next / Previous result.
- `:%s/a/b/g`   → Replace all 'a' with 'b' in the file.

## Window Management
- `:vsplit`     → Vertical split.
- `:split`      → Horizontal split.
- `ctrl + w + h/j/k/l` → Move between windows.
- `ctrl + w + q` → Close current window.

## Essential Commands
- `:w`          → Save.
- `:q`          → Quit.
- `:wq`         → Save and quit.
- `:q!`         → Quit without saving.
- `:Lazy`       → Open plugin manager (Lazy.nvim).
- `:checkhealth`→ Check Nvim health status.
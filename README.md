# Dired Global Script Runner 🛒

A lightweight, Yazi-inspired global marking system for Emacs `dired`.

This package allows you to navigate through multiple directories, collect files into a global "shopping cart" and seamlessly pass them as arguments to any external Bash, Python, or Lua script via the `eat` terminal emulator.

Originally built to bypass Termux/Android PTY argument-parsing bugs, it copies the final execution command directly to your clipboard for a foolproof, manual paste execution.

## 📋 Prerequisites

To use this script exactly as documented, you need:

-   [**Eat (Emulate A Terminal)**](https://codeberg.org/akib/emacs-eat "null")**:** Required. The script uses Eat to launch a fast, full-screen terminal.
    
-   [**Doom Emacs**](https://github.com/doomemacs/doomemacs "null") **& Evil Mode:** The keybindings provided below use Doom's `map!` macro and rely on Evil mode for the bulk-marking workflow.
    
-   *(Note for Vanilla Emacs users: The core Elisp functions are completely vanilla and will work anywhere. You just need to bind the `mythings/script/*` functions using standard `define-key` instead of `map!`.)*
    

## ✨ Features

-   **Global Selection:** Mark files across entirely different directories (unlike standard `dired` marks).
    
-   **Persistent State:** Save your marked lists as plain text `.org` files and load them later.
    
-   **Auto-Cleanup:** Automatically trims your saved lists history to keep the 10 most recent (while ignoring manually renamed lists).
    
-   **Multi-Language Support:** Automatically detects `.sh`, `.py`, and `.lua` scripts and uses the correct interpreter.
    
-   **Foolproof Execution:** Avoids terminal argument bugs by copying the generated command to your clipboard and opening a fresh `eat` terminal for you to paste and run.
    

## ⚡ The Power of Visual Selection

Most file managers force you to press an "add" key on every single file. This package integrates perfectly with Dired's native marks and Evil mode visual selection, allowing for massive bulk operations.

**The Workflow Advantage:**

1.  Press `V` (capital V) to enter Evil line-wise visual mode.
    
2.  Use `j`/`k` to highlight a block of files.
    
3.  Press `m` to natively Dired-mark them all instantly.
    
4.  Press `SPC m m` to push that entire batch into your global shopping cart in one shot!
    

Made a mistake? Visually select the wrong files, press `m`, and hit `SPC m u` to instantly yank that batch out of your global cart.

## 📦 Installation

1.  Download `run-script-in-terminal.el` and place it in your `~/.config/doom/` directory (or wherever you keep local packages).
    
2.  Load it in your `config.el`:
    
    ```
    (load! "run-script-in-terminal.el")
    ```
    

## ⌨️ Doom Emacs Keybindings & Usage

Add these mappings directly to your `config.el` file:

```
(map! :leader
      "m m" #'mythings/script/add-mark      ; Add point/marks to global list safely
      "m u" #'mythings/script/remove-mark   ; Remove point/marks from global list
      "m s" #'mythings/script/show-marks    ; Show marks (use SPC h e if list is long)
      "m v" #'mythings/script/save-marks    ; Save current list manually
      "m l" #'mythings/script/load-marks    ; Load a previous/renamed list
      "m d" #'mythings/script/trim-marks    ; Manually clear old lists > 10
      "m c" #'mythings/script/clear-marks   ; Just clear memory without saving
      "m r" #'mythings/script/run-script-in-eat) ; Run! (Saves, clears, copies cmd, opens eat)
```

### What Each Key Does

| Keybind | Function | Detailed Description |
| --- | --- | --- |
| `SPC m m` | **Add Marks** | Adds the file at your cursor to the global cart. **Pro-tip:** If you have files marked with Dired's standard `m`, it adds *all* of them at once. It safely ignores duplicates. |
| `SPC m u` | **Remove Marks** | Removes the file at your cursor from the global cart. If you have files marked with standard `m`, it removes all of them from the cart. |
| `SPC m s` | **Show Marks** | Peeks at your currently collected files in the bottom echo area. **Pro-tip:** If your list is very long, press `SPC h e` (Help -> Echo) to open the `*Messages*` buffer and view the full list. |
| `SPC m r` | **Run Script** | **The Magic Button.** Prompts you to select a script. It builds the shell command, saves your list to an `.org` file, clears your memory, copies the command to your clipboard, and drops you into a full-screen `eat` terminal. Just press paste (`p` or `C-y`) and Enter! |
| `SPC m v` | **Save Marks** | Manually saves your current cart to `~/.config/doom/markings-for-script/markings-for-script-TIMESTAMP.org`. |
| `SPC m l` | **Load Marks** | Opens a finder to let you select a previously saved `.org` list and loads its contents back into your active global cart. |
| `SPC m d` | **Trim Old Marks** | Looks at your save directory and deletes old auto-generated timestamp files, keeping only the 10 most recent. If you rename a file (e.g., `markings-audio-files.org`), it is ignored and kept safe! |
| `SPC m c` | **Clear Marks** | Instantly empties your active cart from memory without saving. |

## 🚀 Full Example

1.  Open `dired` in `~/downloads`. Press `m` on `audio1.mp3` and `audio2.mp3`.
    
2.  Press `SPC m m`. (2 files added to cart).
    
3.  Navigate to `~/music`. Visually select 5 files with `V` and `j`, press `m`, then `SPC m m`. (Global cart now has 7 files).
    
4.  Press `SPC m r` and select `~/bin/convert-to-opus.sh`.
    
5.  Emacs opens a fresh full-screen terminal and says: *"Command copied!"*
    
6.  Paste the clipboard contents into the terminal and press Enter.

---

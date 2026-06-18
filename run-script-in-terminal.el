;;; run-script-in-terminal.el -*- lexical-binding: t; -*-

(require 'eat nil t)

;; --- Configurations ---

(defvar mythings/script/save-dir (expand-file-name "~/.config/doom/markings-for-script/")
  "Directory where timestamped lists are saved.")

(defvar mythings/script/global-marked-files nil
  "List of globally marked files across different Dired buffers.")

;; --- Core Actions ---

(defun mythings/script/add-mark ()
  "Add the file at point, or all standard Dired marks, to the global list safely."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (user-error "Must be in a Dired buffer!"))
  (let ((files (dired-get-marked-files nil nil nil t)) ; Gets point OR standard marks
        (added-count 0))
    (dolist (f files)
      (unless (member f mythings/script/global-marked-files)
        ;; Push new items, maintaining a unique set
        (push f mythings/script/global-marked-files)
        (cl-incf added-count)))
    (message "Added %d file(s). Global Total: %d"
             added-count
             (length mythings/script/global-marked-files))
    ;; Move down if it was just a single file selection
    (when (= (length files) 1) (dired-next-line 1))))

(defun mythings/script/remove-mark ()
  "Remove the file at point, or all standard Dired marks, from the global list."
  (interactive)
  (unless (derived-mode-p 'dired-mode)
    (user-error "Must be in a Dired buffer!"))
  (let ((files (dired-get-marked-files nil nil nil t))
        (removed-count 0))
    (dolist (f files)
      (when (member f mythings/script/global-marked-files)
        (setq mythings/script/global-marked-files (delete f mythings/script/global-marked-files))
        (cl-incf removed-count)))
    (message "Removed %d file(s). Global Total: %d"
             removed-count
             (length mythings/script/global-marked-files))
    (when (= (length files) 1) (dired-next-line 1))))

(defun mythings/script/show-marks ()
  "Display currently marked files in the echo area."
  (interactive)
  (if mythings/script/global-marked-files
      ;; Reverse so it shows them in the order you selected them
      (message "Marked files:\n%s" (mapconcat #'file-name-nondirectory (reverse mythings/script/global-marked-files) "\n"))
    (message "No files currently marked.")))

(defun mythings/script/clear-marks ()
  "Clear all globally marked files from memory manually."
  (interactive)
  (setq mythings/script/global-marked-files nil)
  (message "Global marks cleared from memory."))

;; --- State Management (Save/Load/Trim) ---

(defun mythings/script/save-marks (&optional quiet)
  "Save the current global list to a timestamped file."
  (interactive)
  (if (null mythings/script/global-marked-files)
      (unless quiet (message "No marks to save."))
    (unless (file-exists-p mythings/script/save-dir)
      (make-directory mythings/script/save-dir t))
    (let* ((filename (format-time-string "markings-for-script-%Y-%m-%dT%H%M%S.org"))
           (filepath (expand-file-name filename mythings/script/save-dir))
           ;; Reverse so the files are listed in the order you selected them
           (content (mapconcat #'identity (reverse mythings/script/global-marked-files) "\n")))
      (with-temp-file filepath
        (insert content))
      (unless quiet
        (message "Saved %d marks to %s" (length mythings/script/global-marked-files) filename)))))

(defun mythings/script/load-marks ()
  "Select a saved marking file and load its contents into memory."
  (interactive)
  (unless (file-exists-p mythings/script/save-dir)
    (make-directory mythings/script/save-dir t))
  (let ((filepath (read-file-name "Load marks from: " mythings/script/save-dir)))
    (when (file-readable-p filepath)
      (with-temp-buffer
        (insert-file-contents filepath)
        ;; Split string by newline, omitting empty strings
        (setq mythings/script/global-marked-files (split-string (buffer-string) "\n" t)))
      (message "Loaded %d marks from %s"
               (length mythings/script/global-marked-files)
               (file-name-nondirectory filepath)))))

(defun mythings/script/trim-marks (&optional quiet)
  "Keep only the 10 most recent unmodified marking files; delete the rest."
  (interactive)
  (when (file-exists-p mythings/script/save-dir)
    (let* (;; Regex looks exactly for files matching the unmodified format
           (regex "^markings-for-script-[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}T[0-9]\\{6\\}\\.org$")
           ;; Get list of matching files
           (files (directory-files mythings/script/save-dir t regex))
           ;; Sort descending (newest first, since timestamps sort alphabetically perfectly)
           (sorted-files (sort files #'string>))
           (deleted-count 0))

      ;; If more than 10, delete everything from the 11th item onwards
      (when (> (length sorted-files) 10)
        (dolist (f (nthcdr 10 sorted-files))
          (delete-file f)
          (cl-incf deleted-count)))

      (unless quiet
        (message "Trimmed %d old marking lists." deleted-count)))))

;; --- Execution ---

(defun mythings/script/run-script-in-eat (script-path)
  "Generate command, copy to clipboard, save/clear list, and open Eat."
  (interactive (list (read-file-name "Select script to run: " "~/bin/")))

  (if (null mythings/script/global-marked-files)
      (message "No files marked globally! Use `SPC m m` first.")

    ;; 1. Determine interpreter based on extension (Fallback to bash)
    (let* ((ext (file-name-extension script-path))
           (interpreter (cond ((string= ext "py") "python")
                              ((string= ext "sh") "bash")
                              ((string= ext "lua") "lua")
                              (t "bash"))) ; default execution
           ;; 2. Format variables
           ;; Using reverse so they pass into the script in the order you marked them
           (escaped-files (mapcar #'shell-quote-argument (reverse mythings/script/global-marked-files)))
           (escaped-script (shell-quote-argument (expand-file-name script-path)))
           (files-string (mapconcat #'identity escaped-files " "))
           (cmd (format "%s %s %s" interpreter escaped-script files-string)))

      ;; 3. State Management Tasks
      (mythings/script/save-marks t)        ; Save list to .org file silently
      (setq mythings/script/global-marked-files nil) ; Clear from memory
      (mythings/script/trim-marks t)        ; Trim old files silently

      ;; 4. Execution Tasks
      (kill-new cmd)                        ; Copy to clipboard
      (delete-other-windows)                ; Clear screen
      (eat)                                 ; Open fresh terminal
      (message "[%s] Command copied! Marks saved & cleared. Ready to paste!" interpreter))))


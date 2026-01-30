;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
(setq doom-font (font-spec :family "Hasklug Nerd Font" :size 16)
      doom-variable-pitch-font (font-spec :family "MesloLGL Nerd Font" :size 14)
      doom-symbol-font (font-spec :family "Noto Sans Symbols 2"))

(custom-set-faces!
  '(italic :slant italic :family "Hasklug Nerd Font")
  '(bold-italic :slant italic :weight bold :family "Hasklug Nerd Font"))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-rose-pine)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/personalGit/orgFiles/")
(setq org-roam-directory (file-truename "/Users/lbastidas/personalGit/orgFiles/"))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(after! modus-themes
  (setq modus-themes-org-blocks 'gray-background))

;; Change terminal cusor for org-mode vi-mode
(use-package! evil-terminal-cursor-changer
  :hook (tty-setup . evil-terminal-cursor-changer-activate)
  :config
  (setq evil-motion-state-cursor 'box)  ; █
  (setq evil-visual-state-cursor 'box)  ; █
  (setq evil-normal-state-cursor 'box)  ; █
  (setq evil-insert-state-cursor 'bar)  ; ⎸
  (setq evil-emacs-state-cursor 'hbar)) ; _

(unless (display-graphic-p)
  (require 'evil-terminal-cursor-changer)
  (evil-terminal-cursor-changer-activate))

;; org-modern config
;; (use-package! org-modern
;;   :hook (org-mode . org-modern-mode)
;;   :config
;;   (setq org-modern-star ["⬢" "⬡" "▶" "▷" "◉"]))

;; Ensure GUI Emacs inherits shell PATH (hardcoded to avoid shell startup delays)
(when (memq window-system '(mac ns x))
  (setenv "PATH" (concat "/opt/homebrew/bin:/usr/local/bin:" (getenv "PATH")))
  (add-to-list 'exec-path "/opt/homebrew/bin")
  (add-to-list 'exec-path "/usr/local/bin"))

;; Prevent network timeout hangs on startup
(setq url-queue-timeout 5)

;; Defer git-commit loading
(setq doom-incremental-idle-timer 1.5)  ; wait longer before background loading

;; Don't let magit pre-load on startup
(after! magit
  (setq magit-auto-revert-mode nil)
  (setq magit-refresh-status-buffer nil))

;; Prevent git-commit from loading eagerly
;;(setq-default global-git-commit-mode nil)
;; Or more surgical - remove it from first-file-hook
(remove-hook 'doom-first-file-hook #'global-git-commit-mode)

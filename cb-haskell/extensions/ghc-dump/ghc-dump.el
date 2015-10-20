;;; ghc-dump.el --- Commands for dumping intermediate GHC output.  -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Chris Barrett

;; Author: Chris Barrett <chris.d.barrett@me.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Utilities for dumping GHC output at various stages, using Stack for stack
;; projects.

;;; Code:

(require 'f nil t)
(require 'dash nil t)
(require 'ghc-core nil t)
(require 'evil nil t)

(autoload 'asm-mode "asm-mode")
(autoload 'llvm-mode "llvm-mode")

(defun ghc-dump--command-with-buffer-setup (buffer-init-fn bufname &rest dump-flags)
  (save-buffer)
  (let* ((buf (generate-new-buffer bufname))
         (neh (lambda () (kill-buffer buf)))
         (ghc-args
          (-flatten (list dump-flags "-c" (buffer-file-name) ghc-core-program-args))))
    (add-hook 'next-error-hook neh)
    (if (ghc-dump--stack-project?)
        (apply #'call-process "stack" nil buf nil "ghc" "--" ghc-args)
      (apply #'call-process "ghc" nil buf nil ghc-args))

    (pop-to-buffer buf)
    (with-current-buffer buf
      (goto-char (point-min))
      (funcall buffer-init-fn)
      (whitespace-cleanup))
    (remove-hook 'next-error-hook neh)))

(defun ghc-dump--stack-project? ()
  (f-traverse-upwards
   (lambda (dir)
     (--any? (s-matches? (rx "stack." (or "yaml" "yml")) it)
             (f-files dir)))))

;;;###autoload
(defun ghc-dump-core ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'ghc-core-mode "*ghc-core*" "-ddump-simpl"))

;;;###autoload
(defun ghc-dump-desugared ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'ghc-core-mode "*ghc-desugared*" "-ddump-ds"))

;;;###autoload
(defun ghc-dump-opt-cmm ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'ignore "*ghc-opt-cmm*" "-ddump-opt-cmm"))

;;;###autoload
(defun ghc-dump-llvm ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'llvm-mode "*ghc-llvm*" "-ddump-llvm"))

;;;###autoload
(defun ghc-dump-asm ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'asm-mode "*ghc-asm*" "-ddump-asm"))

;;;###autoload
(defun ghc-dump-types ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'ignore "*ghc-types*" "-ddump-types"))

;;;###autoload
(defun ghc-dump-splices ()
  (interactive)
  (ghc-dump--command-with-buffer-setup (lambda () (ghc-core-mode) (compilation-minor-mode))
                                       "*ghc-splices*"
                                       "-ddump-splices" "-dsuppress-all"))

;;;###autoload
(define-derived-mode ghc-stg-mode ghc-core-mode "GHC-STG")

;;;###autoload
(defun ghc-dump-stg ()
  (interactive)
  (ghc-dump--command-with-buffer-setup 'ghc-stg-mode "*ghc-stg*" "-ddump-stg"))


(provide 'ghc-dump)

;;; ghc-dump.el ends here

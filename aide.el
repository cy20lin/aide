;;; aide.el --- integrating your own development environment

;; Copyright (C) 2017 ChienYu Lin

;; Author: ChienYu Lin <cy20lin@gmail.com>

;; This file is part of Aide.

;; Aide is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; Aide is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Aide. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Aide is a framework that help you to integrate and configure
;; developing tools with easier manners.

;; Aide provide a project based configurating method, for all buffers
;; within the same project. By registering a project-type, with proper
;; configurations and properties. Aide will load these configurations
;; whenever current buffer match the condition of that project-type.
;; All buffers with same project-type will share the same configurations
;; in the end.

;; Aide utilizes those feature provided by `projectile' to help Aide
;; to deal with project related operations. Also, Aide extends features
;; to `projectile' to provide project based properties and configurations.

;; For those files and buffers that are not inside a porject, Aide also
;; provided a way to configure them. That is to register a non-project
;; type to Aide type system, these registered non-project types work almost
;; the same as those project types, with the exception that the configurations
;; are loaded on a per-file basis. If the current buffer is not in a project
;; or is in a project but cannot found a proper project-type to handle the
;; configurating of this project (i.e. generic project-type), Aide will
;; fall back to apply the non-project-type configurations to that buffer.

;; Aide provide hooks so that you can add your custom operations before or
;; after the project or non-project configurating operations. It it also
;; possible to add hooks for certain major modes.

;; Enjoy :D

;;; Code:

(defvar aide-mode-initialization-hooks-for-major-modes
  (make-hash-table)
  "A hash table holding set of major-mode corresponding initialization-hooks, \
which are run at the beginning of aide-mode.")

(defvar aide-mode-finalization-hooks-for-major-modes
  (make-hash-table)
  "A hash table holding set of major-mode corresponding finalization-hooks, \
which are run at the end of aide-mode.")

(defvar aide-mode-initialization-hooks nil
  "Initialization hooks, which are run at the very beginning of aide-mode.")

(defvaralias 'aide-mode-finalization-hooks 'aide-mode-hook
  "Finalization hooks, which are run at the very end of aide-mode.")

(define-minor-mode aide-mode
  "Aide minor mode."
  :init-value nil
  (run-hooks aide-mode-initialization-hooks)
  (run-hooks (gethash major-mode aide-mode-initialization-hooks-for-major-modes))
  (cond
   (aide-mode
    ;; setup configs
    (aide-buffer-run '(configs setup)))
   (t
    ;; teardown configs
    (aide-buffer-run '(configs teardown))
    ))
  (run-hooks (gethash major-mode aide-mode-finalization-hooks-for-major-modes)))

(define-globalized-minor-mode global-aide-mode aide-mode
  aide-mode-try-enable
  :init-value nil)

(defvar aide-global-modes t
  "Modes for which option `aide-mode' is turned on.

If t, Aide Mode is turned on for all major modes.  If a list,
Mode is turned on for all `major-mode' symbols in that
list.  If the `car' of the list is `not', Aide Mode is turned
on for all `major-mode' symbols _not_ in that list.  If nil,
Aide Mode is never turned on by command `global-aide-mode'.")

(defun aide-mode-may-enable-p-on-demand ()
  "Whether `major-mode' is disallowed by `aide-global-modes'"
  (and
   (pcase aide-global-modes
     (`t t)
     (`(not . ,modes) (not (memq major-mode modes)))
     (modes (memq major-mode modes)))))

(defun aide-mode-may-enable-p-if-not-minibuffer ()
  "Return non-nil if current buffer is not a minibuffer."
  (not (minibufferp)))

(defvar aide-mode-may-enable-p-handlers
  (list #'aide-mode-may-enable-p-on-demand
        #'aide-mode-may-enable-p-if-not-minibuffer)
  "List of may-enable-p handlers.")

(defun aide-mode-may-enable-p ()
  "Check if `aide-mode' may be activated."
  (cl-every #'funcall aide-mode-may-enable-p-handlers))

(defun aide-mode-try-enable ()
  "Enable aide-mode if predicate funcion returns non-nil."
  (when (aide-mode-may-enable-p) (aide-mode)))

(provide 'aide)

;;; aide.el ends here

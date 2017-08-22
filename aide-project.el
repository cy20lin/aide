;;; aide-project.el

;; Copyright (C) 2017 ChienYu Lin

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

;; Author: ChienYu Lin <cy20lin@gmail.com>

;;; Code:

(cl-defun aide-register-project-type (project-type marker-files &key modes commands configs compile test run test-suffix test-prefix properties)
  "Register a project-type."
  (let ((props properties))
    (when marker-files (setq props (plist-put props 'marker-files marker-files)))
    (when compile      (setq props (plist-put props 'compile-command compile)))
    (when run          (setq props (plist-put props 'run-command run)))
    (when test         (setq props (plist-put props 'run-command test)))
    (when modes        (setq props (plist-put props 'modes modes)))
    (when commands     (setq props (plist-put props 'commands commands)))
    (when configs      (setq props (plist-put props 'configs configs)))
    (when test-suffix  (setq props (plist-put props 'test-suffix test-suffix)))
    (when test-prefix  (setq props (plist-put props 'test-prefix test-prefix)))
    (puthash project-type props projectile-project-types)))

(defun aide-project-type-p ()
  "Check wether current buffer is project and its type is `project-type'."
  (let ((marker (aide-project-type-get project-type '(marker-files))))
    (if (listp marker) (projectile-verify-files marker) (funcall marker))))

(defun aide-project-type ()
  "Get current buffer's project-type."
  (ignore-errors (projectile-project-type)))

(defun aide-project-types ()
  "Return all registered project-types in a list"
  (hash-table-keys projectile-project-types))

(defun aide-project-type-run (project-type keys &rest args)
  "Run the property in `project-type' with given accessing `keys'."
  (let (value (aide-project-type-get project-type keys))
    (apply #'aide-project-handle-run `(,keys ,value . ,args))))

(defun aide-project-type-get (project-type keys)
  "Get the property in `project-type' with given accessing `keys'."
  (reduce #'plist-get keys :initial-value (gethash project-type projectile-project-types)))

(defun aide-project-p ()
  "Check if current buffer is a project."
  (projectile-project-p))

(defun aide-project-run (keys &rest args)
  "Run the property in current buffer's `project-type' with given accessing `keys'."
  (apply #'aide-project-type-run `(,(aide-project-type) . ,args)))

(defun aide-project-get (keys)
  "Get the property in current buffer's `project-type' with given accessing `keys'."
  (aide-project-type-get (aide-project-type) keys))

(defun aide-project--handle-run (keys value &rest args)
  "Handle all run handlers defined in `aide-project-run-handlers'."
  (cl-dolist (handler aide-project-run-handlers)
    (pcase (apply handler `(,keys ,value . ,args))
      ('stop (return 'stop))
      (_ (return)))))

(defun aide-project-default-run-handler (keys value &rest args)
  "Default run handler."
  (cond
   ((typep value 'function) (funcall value))
   ((and value (typep value 'list)) (compile (mapconcat #'shell-quote-argument (mapcar #'eval value) " ")))
   ((typep value 'string) (compile value))
   ((and aide-fallback-to-projectile-command (eq (first keys) 'commands))
    (pcase (second keys)
      ('run-command (call-interactively 'projectile-run-project))
      ('compile-command (call-interactively 'projectile-compile-project))
      ('test-command (call-interactively 'projectile-test-project))))
   (t nil))
  nil)

(defvar aide-project-run-handlers (list #'aide-project-default-run-handler)
  "Default run-handlers.")

(defvar aide-project-use-projectile-command-fallback nil
  "Fallback to use projectile command if its value is non-nil.")

(defvar aide-project-generic-use-non-project-properties t
  "Use properties from current non-project-type, when project-type `generic' is specified.")

(defvaralias 'aide-project-types 'projectile-project-types
  "A hash table holding all project-types with its properties.")

;;; aide-project.el ends here
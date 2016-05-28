;;; tiny-menu.el --- Run a selected command from one menu.

;; Copyright (c) 2016 Aaron Bieber
;;
;; Author: Aaron Bieber <aaron@aaronbieber.com>

;; Package-Requires: ((emacs "24.4"))
;; Keywords: menu tools
;; Homepage: https://github.com/aaronbieber/tiny-menu.el

;; Tiny Menu is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.
;;
;; Tiny Menu is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Tiny Menu.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; Tiny Menu provides a simple mechanism for building one-line menus
;; of commands suitable for binding to keys.  For a full description
;; and examples of use, see the `README.md' file packaged along with
;; this program.

;;; Code:

(defface tiny-menu-heading-face
  '((t (:inherit 'font-lock-string-face)))
  "The menu heading shown in the selection menu for `tiny-menu'."
  :group 'tiny-menu)

(defvar tiny-menu-items
  '(())
  "An alist of menus.

The keys in the alist are simple strings used to reference the menu in
calls to `tiny-menu' and the values are lists with three elements:
A raw character to use as the selection key, such as `?a'; a string to
use in the menu display, and a function to call when that item is
selected.

The data structure should look like:

'((\"menu-1\" (?a \"First item\" function-to-call-for-item-1)
            (?b \"Second item\" function-to-call-for-item-2))
  (\"menu-2\" (?z \"First item\" function-to-call-for-item-1)
            (?x \"Second item\" function-to-call-for-item-2)))")

(defun tiny-menu (&optional menu)
  "Display the items in MENU and run the selected item.

If MENU is not given, a dynamically generated menu of available menus
is displayed."
  (interactive)
  (if (< (length tiny-menu-items) 1)
      (message "Configure tiny-menu-items first.")
    (let* ((menu (if (assoc menu tiny-menu-items)
                     (cadr (assoc menu tiny-menu-items))
                   (air-menu-of-menus)))
           (title (car menu))
           (items (append (cadr menu)
                          '((?q "Quit" nil))))
           (prompt (concat (propertize (concat title ": ") 'face 'default)
                           (mapconcat (lambda (i)
                                        (concat
                                         (propertize (concat
                                                      "[" (char-to-string (nth 0 i)) "] ")
                                                     'face 'tiny-menu-heading-face)
                                         (nth 1 i)))
                                      items ", ")))
                   (choices (mapcar (lambda (i) (nth 0 i)) items))
                   (choice (read-char-choice prompt choices)))
           (if (and (assoc choice items)
                    (functionp (nth 2 (assoc choice items))))
               (funcall (nth 2 (assoc choice items)))
             (message "Menu aborted.")))))

(defun air-menu-of-menus ()
  "Build menu items for all configured menus.

This allows `tiny-menu' to display an interactive menu of all
configured menus if the caller does not specify a menu name
explicitly."
  (let ((menu-key-char 97))
    `("Menus" ,(mapcar (lambda (i)
                (prog1
                    `(,menu-key-char ,(car (car (cdr i))) (lambda () (tiny-menu ,(car i))))
                  (setq menu-key-char (1+ menu-key-char))))
              tiny-menu-items))))

(defmacro tiny-menu-run-item (item)
  "Return a function suitable for binding to call the ITEM run menu.

This saves you the trouble of putting inline lambda functions in all
of the key binding declarations for your menus.  A key binding
declaration now looks like:

`(define-key some-map \"<key>\" (tiny-menu-item \"my-menu\"))'."
  `(lambda ()
     (interactive)
     (tiny-menu ,item)))

(provide 'tiny-menu)
;;; tiny-menu ends here
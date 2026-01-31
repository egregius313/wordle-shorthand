;;; wordle-shorthand.el --- Shorthand for expanding wordle games -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025 Edward Minnix III
;;
;; Author: Edward Minnix III <egregius313@gmail.com>
;; Maintainer: Edward Minnix III <egregius313@gmail.com>
;; Created: November 03, 2025
;; Modified: November 03, 2025
;; Version: 0.0.1
;; Keywords: games
;; Homepage: https://github.com/egregius313/wordle-shorthand
;; Package-Requires: ((emacs "27.1") (org-ml "6.0.2") (org "9.7") (dash "2.17") (s "1.12"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Shorthand for recording Wordle games in orgmode
;;
;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'rx))
(require 'org)
(require 'dash)
(require 's)
(require 'org-ml)
(require 'thingatpt)

(defgroup wordle-shorthand nil
  "Wordle Shorthand mode."
  :group 'games)

(defconst wordle-shorthand--line-pattern
  (rx
   (group (any "+/*"))                  ; opening sigil
   (group (*? alpha))                   ; letters
   (backref 1)                          ; closing sigil
   )
  "Pattern for recognizing the shorthand representing a wordle line.")

(defconst wordle-shorthand--winning-line-pattern
  (rx ?* (= 5 alpha) ?*) ; *abcde*
  "Pattern for recognizing when a line indicates winning.")

(defun wordle-shorthand--expand-game-replacer ()
  "Argument to `replace-region-contents' for `wordle-shorthand-expand-game'."
  (cl-loop
   with paragraph = (thing-at-point 'paragraph t)
   with lines = (->> paragraph s-lines (-remove 's-blank-p))
   with table-rows

   for line in lines
   for matches = (s-match-strings-all wordle-shorthand--line-pattern line)

   ;; Check for the winning line
   for is-winning = (->> line
                         s-trim
                         (s-match wordle-shorthand--winning-line-pattern))
   when is-winning
   collect 'hline into table-rows

   for expanded-line = (cl-loop
                        for (_ kind letters) in matches
                        append (cl-loop for c across letters
                                        for cell = (concat kind (list c) kind)
                                        collect cell))
     
   collect expanded-line into table-rows
   
   finally return (concat
                   "\n"
                   (->> table-rows
                        (apply 'org-ml-build-table!)
                        (org-ml-build-special-block "wordle")
                        (org-ml-build-section)
                        (org-ml-build-headline! :title-text "Wordle" :tags '("wordle"))
                        org-ml-to-string)
                   "\n")))

(defun wordle-shorthand-expand-game ()
  (interactive)
  (let* ((bounds (bounds-of-thing-at-point 'paragraph))
         (beg (car bounds))
         (end (cdr bounds)))
    (replace-region-contents beg end 'wordle-shorthand--expand-game-replacer))
  (let* ((element (org-element-at-point))
         (end (org-element-property :end element)))
    (goto-char end)
    (forward-line 1)))

(define-minor-mode wordle-shorthand-mode
  "Minor mode to allow expanding wordle shorthand in `org-roam-dailies' files."
  :keymap (make-sparse-keymap))

(provide 'wordle-shorthand)
;;; wordle-shorthand.el ends here

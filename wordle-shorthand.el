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
;; Package-Requires: ((emacs "24.3"))
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
  (require 'dash)
  (require 'rx))
(require 'org)
(require 's)
(require 'thingatpt)

(defgroup wordle-shorthand nil
  "Wordle Shorthand mode"
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

(cl-defun wordle-shorthand--expand-line ()
  (interactive)
  (cl-flet ((is-line (matches)
              (= 5 (cl-loop for (_ _ letters) in matches sum (length letters))))
            (is-winning (line)
              (->> line
                   s-trim
                   (s-match wordle-shorthand--winning-line-pattern))))
    (let* ((current-line (thing-at-point 'line t))
           (matches (s-match-strings-all wordle-shorthand--line-pattern current-line)))
      (if (not (is-line matches))
          (cl-return-from 'wordle-shorthand--expand-line))
      (beginning-of-line)
      (kill-line)
      (when (is-winning current-line)
        (insert "|-----+-----+-----+-----+-----|\n"))
      (apply #'insert
             (cons "|"
                   (cl-loop
                    for (_ kind letters) in matches
                    append (cl-loop for c across letters
                                    append (list " " kind c kind " |"))))))))

(defun wordle-shorthand-expand-game ()
  (interactive)
  (let ((line-count (->> (thing-at-point 'paragraph t)
                         s-lines
                         length)))
    (org-backward-element)
    (insert "* Wordle :wordle:\n\n")
    (insert "#+begin_wordle\n")
    (dotimes (_ line-count)
      (wordle-shorthand--expand-line)
      (forward-line))
    (insert "\n#+end_wordle\n")))

(define-minor-mode wordle-shorthand-mode
  "Minor mode to allow expanding wordle shorthand in `org-roam-dailies' files."
  :keymap (make-sparse-keymap))

(provide 'wordle-shorthand)
;;; wordle-shorthand.el ends here

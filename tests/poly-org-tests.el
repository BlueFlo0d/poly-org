
(require 'org)
(require 'poly-org)
(require 'polymode-test)

(setq python-indent-offset 4
      python-indent-guess-indent-offset nil)

(ert-deftest poly-org/spans-at-borders ()
  (pm-test-run-on-file poly-org-mode "babel-code.org"
    (pm-map-over-spans
     (lambda ()
       (let* ((sbeg (nth 1 *span*))
              (send (nth 2 *span*))
              (range1 (pm-innermost-range sbeg))
              (range2 (pm-innermost-range send)))
         (should (eq sbeg (car range1)))
         (should (eq send (cdr range1)))
         (unless (eq send (point-max))
           (should (eq send (car range2)))))))))

(ert-deftest poly-org/spans-at-narrowed-borders ()
  (pm-test-run-on-file poly-org-mode "ob-doc-js.org"
    (pm-map-over-spans
     (lambda ()
       (pm-with-narrowed-to-span *span*
         (let* ((range1 (pm-innermost-range (point-min)))
                (range2 (pm-innermost-range (point-max))))
           (should (eq (car range1) (point-min)))
           (should (eq (cdr range1) (point-max)))
           (should (eq (car range2) (point-min)))
           (should (eq (cdr range2) (point-max)))))))))

(ert-deftest poly-org/narrowed-spans ()
  (pm-test-run-on-file poly-org-mode "ob-doc-js.org"
    (narrow-to-region 60 200)
    (let ((span (pm-innermost-span (point-min))))
      (should (eq (car span) nil))
      (should (= (nth 1 span) 60))
      (should (= (nth 2 span) 67)))
    (widen)
    (narrow-to-region 60 500)
    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) 'head))
      (should (= (nth 1 span) 495))
      (should (= (nth 2 span) 500)))))

(ert-deftest poly-org/spans-at-point-max ()
  (pm-test-run-on-file poly-org-mode "ob-doc-js.org"
    (goto-char (point-max))
    (pm-switch-to-buffer)

    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) nil))
      (should (eq (nth 2 span) (point-max)))
      (delete-region (nth 1 span) (nth 2 span)))

    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) 'tail))
      (should (eq (nth 2 span) (point-max)))
      (delete-region (nth 1 span) (nth 2 span)))

    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) 'body))
      (should (eq (nth 2 span) (point-max)))
      (delete-region (nth 1 span) (nth 2 span)))

    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) 'head))
      (should (eq (nth 2 span) (point-max)))
      (delete-region (nth 1 span) (nth 2 span)))

    (let ((span (pm-innermost-span (point-max))))
      (should (eq (car span) nil))
      (should (eq (nth 2 span) (point-max)))
      (delete-region (nth 1 span) (nth 2 span)))))

(ert-deftest poly-org/change-spans ()
  (pm-test-poly-lock poly-org-mode "ob-doc-js.org"
    ((insert-1 ("BEGIN_SRC emacs-lisp" end))
     (insert "p")
     (pm-test-spans)
     (delete-backward-char 1)
     (pm-test-spans)
     (backward-word 1)
     (delete-backward-char 1)
     (pm-test-spans)
     (insert "-")
     (pm-test-spans)
     (forward-line 1)
     (pm-switch-to-buffer)
     (should (eq major-mode 'emacs-lisp-mode)))
    ((delete-2 "console.log")
     (forward-line 1)
     (end-of-line 1)
     (backward-kill-word 1)
     (pm-switch-to-buffer)
     (should-not (eq major-mode 'org-mode))
     (insert "SRC")
     (pm-switch-to-buffer)
     (should (eq major-mode 'org-mode)))))

(ert-deftest poly-org/narrowed-spans ()
  (pm-test-run-on-file poly-org-mode "babel-code.org"
    (goto-char (point-min))
    (pm-switch-to-buffer)
    (should (eq major-mode 'org-mode))
    (re-search-forward "#\\+begin_src ruby")
    (forward-line 1)
    (pm-switch-to-buffer)
    (should (eq major-mode 'ruby-mode))
    (re-search-forward "|sed")
    (pm-switch-to-buffer)
    (should (eq major-mode 'pascal-mode))
    (re-search-forward "cBLU")
    (pm-switch-to-buffer)
    (should (eq major-mode 'org-mode))
    (re-search-forward "return x*x")
    (pm-switch-to-buffer)
    (should (eq major-mode 'python-mode))
    (re-search-forward "defun.*fibonacci")
    (pm-switch-to-buffer)
    (should (eq major-mode 'emacs-lisp-mode))))

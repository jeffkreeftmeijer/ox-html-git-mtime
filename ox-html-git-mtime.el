;;; ox-html-git-mtime.el --- Git-based document modified times for ox-html.el

;;; Commentary:

;; Uses git-mtime to get the modified time when exporting a
;; document.
;;
;; Replaces the %C placeholder used in pre- and postambles from
;; placing the modified time for a file to using the time of the
;; last Git commit that touched the file.

;;; Code:
(setq ox-html-git-mtime--git-mtime-location
      (concat (file-name-directory load-file-name) "git-mtime/git-mtime"))

(defun org-html-git-mtime--git-timestamp (path)
  (string-to-number (shell-command-to-string
		     (concat ox-html-git-mtime--git-mtime-location " --date=format:%s " path))))

(defun org-html-git-mtime--file-timestamp (path)
  (file-attribute-modification-time (file-attributes path)))

(defun org-html-git-mtime--timestamp (path)
  (let ((git-timestamp (org-html-git-mtime--git-timestamp path))
	(file-timestamp (org-html-git-mtime--file-timestamp path)))
    (if ( > git-timestamp 0) git-timestamp file-timestamp)))

(defun org-html-git-mtime-formatted-mtime (path format)
  (format-time-string format (org-html-git-mtime--timestamp path)))

(defun org-html-git-mtime--advise-org-html-format-spec (orig-fun &rest args)
  (let ((info (car args)))
    (append `((?C ,(org-html-git-mtime-formatted-mtime
		    (plist-get info :input-file)
		    (plist-get info :html-metadata-timestamp-format))))
	    (apply orig-fun args))))

(advice-add 'org-html-format-spec
	    :around #'org-html-git-mtime--advise-org-html-format-spec)

(add-to-list
 'ox-extensions-alist '(
			'ox-html-git-mtime
			:add
			(lambda () (advice-add
				    'org-html-format-spec
				    :around
				    #'org-html-git-mtime--advise-org-html-format-spec))
			:remove
			(lambda () (advice-remove
				    'org-html-format-spec
				    #'org-html-git-mtime--advise-org-html-format-spec))))
;;; ox-html-git-mtime.el ends here

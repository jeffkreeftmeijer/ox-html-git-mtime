(defun org-html-git-mtime--git-timestamp (path)
  (string-to-number (shell-command-to-string
		     (concat "git-mtime --date=format:%s " path))))

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

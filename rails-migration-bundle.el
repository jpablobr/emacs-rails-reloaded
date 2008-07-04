;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Constants
;;

(defconst rails/migration/dir "db/migrate/")
(defconst rails/migration/buffer-weight 1)
(defconst rails/migration/buffer-type :migration)
(defconst rails/migration/file-id-mask "[0-9]+")
(defconst rails/migration/resource-file-mask
  (concat  "^" rails/migration/file-id-mask "_create_%s\\.rb"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functions
;;

(defun rails/migration/resource-of-file (file)
  (when-bind (res (string-ext/string=~ (format rails/migration/resource-file-mask "\\([^.]+\\)")
                                       (file-name-nondirectory file)
                                       $1))
    res))

(defun rails/migration/exist-p (root resource-name)
  (when resource-name
    (let ((file (directory-files (concat "~/Sites/pro2/" rails/migration/dir)
                                      nil
                                      (format rails/migration/resource-file-mask resource-name))))
      (when file
        (concat rails/migration/dir (car file))))))

(defun rails/migration/migration-p (file)
  (rails/with-root file
    (when-bind (buf (rails/determine-type-of-file (rails/root) (rails/cut-root file)))
      (eq rails/migration/buffer-type (rails/buffer-type buf)))))

(defun rails/migration/format-file-name (file)
  (let ((file (file-name-nondirectory (file-name-sans-extension file)))
        (re (format "^\\(%s\\)_\\(.*\\)" rails/migration/file-id-mask)))
    (string-ext/string=~ re file (format "%s %s" $1 (string-ext/decamelize $2)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Callbacks
;;

(defun rails/migration/goto-item-from-file (root file rails-current-buffer)
  (when-bind (type (rails/resource-type-p rails-current-buffer rails/migration/buffer-type))
     (when-bind (file-name
                 (rails/migration/exist-p root (rails/buffer-resource-name rails-current-buffer)))
       (make-rails/goto-item :name "Migration"
                             :file file-name))))

(defun rails/migration/determine-type-of-file (rails-root file)
  (when (string-ext/start-p file rails/migration/dir)
    (let ((res (rails/migration/resource-of-file file)))
      (make-rails/buffer :type   rails/migration/buffer-type
                         :weight rails/migration/buffer-weight
                         :name   (rails/migration/format-file-name file)
                         :resource-name res))))

(defun rails/migration/load ()
  (rails/add-to-resource-types-list rails/migration/buffer-type)
  (rails/add-to-layouts-list :model rails/migration/buffer-type)
  (rails/define-goto-key "g" 'rails/migration/goto-from-list)
  (rails/define-goto-menu [migration] 'rails/migration/goto-from-list "Migration")
  (rails/define-fast-goto-key "g" 'rails/migration/goto-current)
  (rails/define-fast-goto-menu [migration] 'rails/migration/goto-current "Migration"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Interactives
;;

(defun rails/migration/goto-from-list ()
  (interactive)
  (let ((file (buffer-file-name)))
    (rails/with-root file
      (rails/directory-to-goto-menu (rails/root)
                                    rails/migration/dir
                                    "Select a Migration"
                                    :reverse t
                                    :limit 25
                                    :name-by 'rails/migration/format-file-name))))

(defun rails/migration/goto-current ()
  (interactive)
  (let ((file (buffer-file-name))
        (rails-buffer rails/current-buffer))
    (rails/with-root file
      (when-bind
       (goto-item
        (rails/migration/goto-item-from-file (rails/root)
                                             (rails/cut-root file)
                                             rails-buffer))
       (rails/fast-find-file-by-goto-item (rails/root) goto-item)))))

(provide 'rails-migration-bundle)
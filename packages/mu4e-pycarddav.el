;;; mu4e-pycarddav.el --- Integrate pycarddav in mu4e
;;; Commentary:
;;
;;; Code:

(require 's)
(require 'mu4e-vars)
(require 'mu4e-utils)

(defun mu4e~pycarddav-get-contacts-buffer ()
  "Put all pycarddav contacts in the returned buffer."
  (let ((buffer (get-buffer-create "*mu4e~pycarddav-contacts*")))
    (with-current-buffer buffer (erase-buffer))
    (call-process
     "pc_query"
     nil ;; input file
     (list buffer nil) ;; output to buffer, discard error
     nil ;; don't redisplay
     "-m")  ;; 1st arg to pc_query: prints email addresses
    buffer))

(defun mu4e~pycarddav-get-contacts ()
  "Return a list of all pycarddav contacts.
The list is of the form
 ((:name \"Some Name\" :mail \"an.email@address.org\") (:name \"Another Name\" :mail \"another@email.com\"))"
  (with-current-buffer (mu4e~pycarddav-get-contacts-buffer)
    (goto-char (point-min))
    (let ((contacts))
      (while (not (eobp))
        (forward-line 1) ;; go to next line (skip the header line as well)
        (let ((line (buffer-substring-no-properties (point-at-bol) (point-at-eol))))
          (when (string-match "\\(.*?\\)\t\\(.*?\\)\t" line)
            (add-to-list 'contacts (list :name (match-string 2 line) :mail (match-string 1 line))))))
      contacts)))

(defun mu4e~pycarddav-fill-contacts (contacts)
  "Fill the list `mu4e~contacts-for-completion' from CONTACTS.
This is used by the completion function in mu4e-compose.
The list must look like

 ((:name \"Some Name\" :mail \"an.email@address.org\") (:name \"Another Name\" :mail \"another@email.com\"))

and can be generated by `mu4e~pycarddav-get-contacts'."
  (setq mu4e~contact-list contacts)
  (let ((lst))
    (dolist (contact contacts)
      (let* ((name (plist-get contact :name))
             (mail (plist-get contact :mail)))
        (when mail
          ;; ignore some address ('noreply' etc.)
          (unless (and mu4e-compose-complete-ignore-address-regexp
                       (string-match mu4e-compose-complete-ignore-address-regexp mail))
            (add-to-list 'lst
                         (if name
                             (format "%s <%s>" (mu4e~rfc822-quoteit name) mail)
                           mail))))))
    (setq mu4e~contacts-for-completion lst)
    (mu4e-index-message "Contacts received: %d"
                        (length mu4e~contacts-for-completion))))

(provide 'mu4e-pycarddav)

;;; mu4e-pycarddav.el ends here

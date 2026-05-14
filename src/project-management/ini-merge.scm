(use-modules (ini)
             (ice-9 match)
             (srfi srfi-1))

(define-syntax push!
  (syntax-rules ()
    ((_ item lst)
     (set! lst (cons item lst)))))


(define-syntax for-match
  (syntax-rules ()
    ((_ (pattern list-expr) body ...)
     (for-each (match-lambda (pattern body ...)) list-expr))))


(define *sections*         (make-hash-table))
(define *sections-order*   '()              )
(define *keys-order*       (make-hash-table))

(define (hash-contains? ht key)
  (if (hash-get-handle ht key) #t #f))

(define (hashtable-default! ht key value-fn)
  (if (not (hash-contains? ht key))
    (hash-set! ht key (value-fn))))

;;
;; Reads file contents and populates global structures 
;; like *keys-order*, *sections* and etc.
;;
(define (read-with-order filename)
  (define ini '())

  (call-with-input-file filename
    (lambda (port)
      (set! ini (ini->scm port))))

  (for-match ((name . content) ini)
    (hashtable-default! *sections* name 
      (lambda ()
        ;; initalize keys order
        (hash-set! *keys-order* name '())
        ;; register itself in the sections order
        (push! name *sections-order*)
        ;; create key/value storage for this section
        (make-hash-table)))

    (define keys  (hash-ref *sections*   name))
    (define order (hash-ref *keys-order* name))

    (for-match ((key . value) content)
      (if (not (hash-contains? keys key))
        (push! key order))
      (hash-set! keys key value))

    ;; set it back
    (hash-set! *keys-order* name order)))

;; Creates order from global structures 
(define (reconstruct)
  (define result '())

  (for-each (lambda (name)
    (define content '())

    (define key-order    (hash-ref *keys-order* name))
    (define content-hash (hash-ref *sections*   name))
  
    ;; add all keys and their values in order
    (for-each (lambda (key)
      (define value (hash-ref content-hash key))
      (push! (cons key value) content))
    key-order)
    
    (push! (cons name content) result))
   *sections-order*)

  result)

(define (main args)
  (if (< (length args) 3)
      (begin
        (format (current-error-port) "Usage: merge-ini.scm base.ini override1.ini [override2.ini ...]\n")
        (exit 1)))
  
  (define files (cdr args))

  ;; read the data 
  (for-each (lambda (file)
    (read-with-order file))
  files)

  ;; recreate
  (define reconstructed (reconstruct))
  
  ;; write it back
  (scm->ini reconstructed #:port (current-output-port)))

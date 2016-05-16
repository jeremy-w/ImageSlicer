#lang racket

;;;; provides utilities to snarf a Gregg Anniversary section into a directory tree of images

(provide
 (all-defined-out))

;;; ---------------------------------------------------------------------------------------------------
;;; IMPORTS & IMPLEMENTATION

(require net/url)
(require html-parsing)
(require sxml)

(define (url-for section)
  ;; String -> URL. Section should be something like "09". Values 01 through 36 are valid.
  (define url-string (string-append "http://gregg.angelfishy.net/anunit" section ".shtml"))
  (string->url url-string))

(define (page-for section-url)
  ;; url -> xexp. Snarfs the page and returns its xexp.
  (call/input-url section-url get-pure-port html->xexp))

(define (image-hierachy-from unit-table-xexp)
  ;; xexp -> hash<heading-string -> vector<image-url> >
  ;; TODO: grab out images and their headings
  ;; smoosh into nested structure
  ;; eventually, splorsh out onto disk with heading as folder title and downloaded images within the folders
  'wip)

(define (unit-table page-xexp)
  ;; xexp -> xexp. Digs out the table representing the unit content.
  (unit-table-query page-xexp))

(define unit-table-query
  ;; sxpath query for the unit table
  (txpath "/descendant::table[3]"))

(define *unit-09*
  ;; convenience for repl'ing
  (page-for (url-for "09")))

(module+ test
  (require rackunit)
  (check-equal? (url->string (url-for "09")) "http://gregg.angelfishy.net/anunit09.shtml" "happy path")
  )

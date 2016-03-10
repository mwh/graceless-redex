#lang racket

(require redex)
(require "inheritance.rkt")

(provide (except-out (all-defined-out)
                     eval
                     run)
         (all-from-out "inheritance.rkt"))

;; Small-step dynamic semantics of Graceless extended with concatenating
;; inheritance.
(define -->GC
  (extend-reduction-relation
   -->GI
   GI
   #:domain p
   ;; Allocate the object o substituting local requests to this object, and
   ;; return the resulting reference.
   (--> [(in-hole E (object (name M (method m _ _)) ... F ...))
         σ]
        [(in-hole E (subst-object ℓ m ... m_f ...
                                  (field-assigns ℓ F ... (ref ℓ))))
         (store σ [(subst-rec-method ℓ m ... m_f ... M_p) ...])]
        (where ℓ (fresh-location σ))
        (where (m_f ...) (fields-names F ...))
        (where (M_f ...) (fields-methods F ...))
        (where (M_p ...) (M ... M_f ...))
        (side-condition (term (unique m ... m_f ...)))
        object)))

;; Progress the program p by one step with the reduction relation -->GC.
(define (step-->GC p) (apply-reduction-relation -->GC p))

;; Evaluate an expression starting with an empty store.
(define-metafunction GI
  eval : e -> e
  [(eval e) ,(car (term (run [e ()])))])

;; Apply the reduction relation -->GC until the result is a value or the program
;; gets stuck or has an error.
(define-metafunction GI
  run : p -> [e σ]
  [(run [uninitialised σ]) [uninitialised σ]]
  [(run [(ref ℓ) σ]) [(object M ...) σ]
   (where [M ...] (lookup σ ℓ))]
  [(run p) (run p_p)
   (where (p_p) ,(step-->GC (term p)))]
  [(run p) p])

;; Run the term t as an initial program with the reduction relation -->GC,
;; returning the resulting object, stuck program, or error.
(define (eval-->GC t) (term (eval ,t)))

;; Run the term t as an initial program with the reduction relation -->GC,
;; returning the resulting object, stuck program, or error, and the store.
(define (run-->GC t) (term (run [,t ()])))

;; Run the traces function on the given term as an initial program with the
;; reduction relation -->GC.
(define (traces-->GC t) (traces -->GC (program t)))
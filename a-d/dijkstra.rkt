#lang r7rs

;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*                                                                 *-*-
;-*-*              Single Source Shortest Path Algorithms             *-*-
;-*-*                                                                 *-*-
;-*-*                       Wolfgang De Meuter                        *-*-
;-*-*                 2008 Programming Technology Lab                 *-*-
;-*-*                   Vrije Universiteit Brussel                    *-*-
;-*-*                                                                 *-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

(define-library (shortest-paths)
  (export dijkstra)
  (import (scheme base)
          (prefix (Gabriel-Isler-0631137 a-d graph weighted config) gr:)
          (prefix (Gabriel-Isler-0631137 a-d pqfib) pq:))
  (begin

    (define (relax! distances how-to-reach u v weight)
      (when (< (+ (vector-ref distances u) weight)
               (vector-ref distances v))
        (vector-set! distances v (+ (vector-ref distances u) weight))
        (vector-set! how-to-reach v u)))

    (define (dijkstra g source) ; only works for positive weights
      (let ((distances (make-vector (gr:order g) +inf.0))
            (how-to-reach (make-vector (gr:order g) '()))
            (pq-nodes (make-vector (gr:order g) #f))
            (pq (pq:new <)))
      
        (define (register-node! node vertex priority) ; 3 args door notify
          (vector-set! pq-nodes vertex node))
        
        (vector-set! distances source 0)
        (gr:for-each-node g (lambda (v) (pq:enqueue! pq v +inf.0 register-node!)))
        (pq:reschedule! pq (vector-ref pq-nodes source) 0 register-node!)
        (let loop ((vert&dist (pq:serve! pq register-node!)))
          (let ((from (car vert&dist)))
            (gr:for-each-edge g from
                              (lambda (weight to)
                                (let ((old-dist (vector-ref distances to)))
                                  (relax! distances how-to-reach from to weight)
                                  (when (< (vector-ref distances to) old-dist)
                                    (pq:reschedule! pq (vector-ref pq-nodes to)
                                                    (vector-ref distances to) register-node!))))))
          (unless (pq:empty? pq)
            (loop (pq:serve! pq register-node!))))
        (cons how-to-reach distances)))
    ))
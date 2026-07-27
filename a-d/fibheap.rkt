#lang r7rs

(define-library (fibheap)
  (export new empty? insert! peek delete! touch-at! node-key node-value)
  (import (scheme base)
          (scheme inexact))
  (begin

    (define-record-type fib-node
      (make-node k v d p c l r m)
      fib-node?
      (k node-key)
      (v node-value node-value!)
      (d node-degree node-degree!)
      (p node-parent node-parent!)
      (c node-child node-child!)
      (l node-left node-left!)
      (r node-right node-right!)
      (m node-marked node-marked!))

    (define-record-type heap
      (make-heap min size lesser)
      heap?
      (min heap-min heap-min!)
      (size heap-size heap-size!)
      (lesser heap-lesser))

    (define (new <<?)
      (make-heap #f 0 <<?))

    (define (empty? h)
      (= (heap-size h) 0))

    (define (new-node key value)
      (let ((n (make-node key value 0 #f #f #f #f #f)))
        (node-left!  n n)
        (node-right! n n)
        n))

    (define (put-left! n curr) ; zet n in lst
      (let ((prev (node-left curr)))
        (node-right! prev   n)
        (node-left!  n      prev)
        (node-right! n      curr)
        (node-left!  curr n)))

    (define (detach-from-list! n) ; haalt n weg zonder verwijderen (voor verplaating)
      (node-right! (node-left  n) (node-right n))
      (node-left!  (node-right n) (node-left  n))
      (node-left!  n n)
      (node-right! n n))

    (define (circular->list start-node)
      (if (not start-node)
          '()
          (let loop ((curr (node-right start-node))
                     (acc (cons start-node '())))
            (if (eq? curr start-node)
                acc
                (loop (node-right curr) (cons curr acc))))))

    (define (root-add! h n)
      (node-parent! n #f)
      (let ((min (heap-min h)))
        (if (not min)
            (heap-min! h n)
            (begin
              (put-left! n min)
              (when ((heap-lesser h) (node-value n) (node-value min))
                (heap-min! h n))))))

    (define (link! child parent)
      (node-parent! child parent)
      (node-marked! child #f)
      (if (node-child parent)
          (put-left! child (node-child parent))
          (node-child!  parent child))
      (node-degree! parent (+ (node-degree parent) 1)))

    (define (merge-roots! h)
      (define (max-degree size) ; hulpfunctie      
      (+ 2 (exact (floor (log size 2)))))
      
      (define <<? (heap-lesser h))
      
      (define roots-by-degree  (make-vector (max-degree (heap-size h)) #f))
      
      (define (merge! new-tree deg)
        (let ((existing-tree (vector-ref roots-by-degree deg)))
          (cond ((not existing-tree)
                 (vector-set! roots-by-degree deg new-tree))
                ((<<? (node-value new-tree) (node-value existing-tree)) ; new wint
                 (vector-set! roots-by-degree deg #f)
                 (link! existing-tree new-tree) ; existing -> kind
                 (merge! new-tree (+ deg 1)))
                (else ; existing wint
                 (vector-set! roots-by-degree deg #f)
                 (link! new-tree existing-tree) ; new -> kind
                 (merge! existing-tree (+ deg 1))))))
      ; verdeel alle wortels over de buckets
      (for-each
       (lambda (n)
         (node-left!  n n) ; isoleer n
         (node-right! n n)
         (merge! n (node-degree n)))
       (circular->list (heap-min h)))
      ; herbouw wortellijst uit de buckets
      (heap-min! h #f)
      (vector-for-each
       (lambda (n) (when n (root-add! h n))) roots-by-degree))

    (define (insert! h key value)
      (let ((n (new-node key value)))
        (root-add! h n)
        (heap-size! h (+ (heap-size h) 1))
        n))

    (define (peek h)
      (if (empty? h)
          (error "heap empty" h)
          (cons (node-key (heap-min h)) (node-value (heap-min h)))))

    (define (delete! h) ; verwijdert minimum en geeft (key . value) terug
      (if (empty? h) (error "heap empty" h))
      (let* ((min-node  (heap-min h))
             (children (circular->list (node-child min-node))))
        (for-each
         (lambda (child)
           (node-left!  child child)
           (node-right! child child)
           (root-add! h child))
         children)
        (if (eq? (node-right min-node) min-node)
            (heap-min! h #f)
            (begin
              (heap-min! h (node-right min-node))
              (detach-from-list! min-node)))
        (heap-size! h (- (heap-size h) 1))
        (unless (empty? h) (merge-roots! h))
        (cons (node-key min-node) (node-value min-node))))

    (define (cut! h n) ; knipt knoop van zijn parent en plaatst hem in wortellijst
      (let ((parent (node-parent n)))
        (when parent
          (when (eq? (node-child parent) n)
            (node-child! parent (and (not (eq? (node-right n) n)) (node-right n))))
          (detach-from-list! n)
          (node-degree! parent (- (node-degree parent) 1))
          (node-marked! n #f)
          (root-add! h n))))

    (define (cascading-cut! h n)
      (let ((parent (node-parent n)))
        (when parent
          (if (node-marked n)
              (begin (cut! h n) (cascading-cut! h parent))
              (node-marked! n #t)))))

    (define (touch-at! h n new-value)
      (node-value! n new-value)
      (let ((parent (node-parent n)))
        (when (and parent ((heap-lesser h) new-value (node-value parent)))
          (cut! h n)
          (cascading-cut! h parent)))
      (when ((heap-lesser h) new-value (node-value (heap-min h)))
        (heap-min! h n)))
    ))
#lang r7rs

(define-library (pqfib)
  (export new priority-queue? enqueue! reschedule! peek serve! full? empty? priority-of)
  (import (scheme base)
          (prefix (Gabriel-Isler-0631137 a-d fibheap) heap:))
  (begin

    (define-record-type priority-queue
      (make h)
      priority-queue?
      (h heap))

    (define (new >>?)
      (make (heap:new >>?)))
    
    (define (empty? pq)
     (heap:empty? (heap pq)))
    
    (define (full?  pq) #f)

    (define (enqueue! pq value priority notify)
      (notify (heap:insert! (heap pq) value priority) value priority)
      pq)

    (define (reschedule! pq node new-priority notify)
      (heap:touch-at! (heap pq) node new-priority)
      (notify node (heap:node-key node) new-priority))

    (define (peek pq)
      (if (empty? pq)
          (error "empty priority queue (peek)" pq)
          (heap:peek (heap pq))))

    (define (serve! pq notify)
      (if (empty? pq)
          (error "empty priority queue (serve!)" pq)
          (heap:delete! (heap pq))))

    (define (priority-of pq node)
      (heap:node-value node))
    ))
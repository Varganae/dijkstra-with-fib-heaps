#lang r7rs
(import (scheme base)
        (scheme file)
        (scheme read)
        (scheme write)
        (prefix (Gabriel-Isler-0631137 a-d graph weighted config) gr:)
        (Gabriel-Isler-0631137 a-d dijkstra))

; Procedure to read a graph from file
(define (read-graph-from-file file)
  (with-input-from-file file
    (lambda ()
      (let ((graph (gr:new #t (read (current-input-port)))))
        (do ((entry (read (current-input-port)) (read (current-input-port))))
          ((eof-object? entry) graph)
          (gr:add-edge! graph (car entry) (cadr entry) (car (cddr entry))))))))

; Some example graphs
(define examples
  (map read-graph-from-file
       (list "examples/circle.txt"
             "examples/dense.txt"
             "examples/dijkstra.txt"
             "examples/galton.txt"
             "examples/pyramid.txt"
             "examples/random.txt")))

(define source 0)

(display (map (lambda (g) (dijkstra g source)) examples))
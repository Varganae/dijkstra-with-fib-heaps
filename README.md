```markdown
# Fibonacci Heap Accelerated Dijkstra's Algorithm

An optimized implementation of **Dijkstra's Algorithm** in Racket, leveraging a custom **Fibonacci Heap** to improve time complexity from $\mathcal{O}((m + n) \log n)$ to $\mathcal{O}(m + n \log n)$.

---

## 📌 Overview

The main bottleneck in Dijkstra's algorithm when using a binary heap comes from the `reschedule!` (decrease-key) operation, which costs $\mathcal{O}(\log n)$. By replacing the binary heap with a Fibonacci Heap, `reschedule!` achieves an amortized time complexity of $\mathcal{O}(1)$. This optimization yields significant performance gains for dense graphs where the number of edges $m$ approaches $n^2$.

---

## 🏗️ Architecture & Module Structure

The project is modularized across three primary Racket files:

```text
dijkstra.rkt  <--->  pqfib.rkt  <--->  fibheap.rkt
  (Algorithm)          (Priority Queue)     (Fibonacci Heap)

```

### 1. `fibheap.rkt` (Fibonacci Heap Core)

* Implements the core Fibonacci Heap data structure using `fib-node` and `heap` records.
* Roots and children are maintained using circular doubly-linked lists.
* **Exported API:** `new`, `empty?`, `insert!`, `peek`, `delete!`, `touch-at!`, `node-key`, `node-value`.
* **Internal Helper Routines:** `merge-roots!`, `cut!`, and `cascading-cut!` are kept private to enforce encapsulation.

### 2. `pqfib.rkt` (Priority Queue Wrapper)

* Provides a Priority Queue ADT wrapped around the Fibonacci Heap, inspired by the priority queue interface in the `a-d` library.
* Features a `notify` callback mechanism triggered after every `enqueue!` or `reschedule!` call. This returns the generated/updated heap node back to Dijkstra's algorithm for mapping.
* Accepts the `notify` parameter in `serve!` for interface uniformity, though it remains unused during serving since the removed minimum element requires no further tracking.

### 3. `dijkstra.rkt` (Dijkstra's Shortest Path Algorithm)

* Interacts strictly with the Priority Queue interface without accessing the heap directly.
* **State Vectors:**
* `distances`: Tracks the current shortest distance from the source to each vertex.
* `how-to-reach`: Tracks the predecessor vertex along the shortest path.
* `pq-nodes`: Stores the mapping from each graph vertex to its corresponding heap node.


* **Execution Flow:** Populates `pq-nodes` via a `register-node!` callback passed as `notify`. Performs a classic Dijkstra loop: serves the closest node, relaxes its neighboring edges, and decreases neighbor priorities upon path improvements.

---

## 🎯 Design & Algorithmic Choices

* **Lazy Insertion:** `insert!` runs in $\mathcal{O}(1)$ time by lazily adding nodes to the root list without restructuring. Consolidation by degree via a bucket vector is deferred until `delete!` is invoked.
* **Cascading Cuts & Marked Flags:** Ensures `delete!` preserves its $\mathcal{O}(\log n)$ upper bound. Cascading cuts prevent trees from degenerating, maintaining theoretical complexity guarantees. The upper bound for maximum degree is set to $\lfloor \log_2 n \rfloor + 2$.
* **Vertex-to-Node Mapping:** `reschedule!` requires direct access to target heap nodes. To avoid an $\mathcal{O}(n)$ linear search across the heap, the priority queue fires a `notify` callback after `enqueue!` or `reschedule!`, storing node references inside the `pq-nodes` vector for instant $\mathcal{O}(1)$ node access.
* **Sentinel Distances:** `+inf.0` is used to initialize unvisited node distances, eliminating the need for an explicit `visited?` boolean flag.
* **Encapsulation & Decoupling:** `dijkstra.rkt` imports `pqfib.rkt` and `a-d/graph/weighted/config`. The underlying heap implementation can be replaced without modifying the core algorithm logic.

---

## 🛠️ Dependencies & Setup

* **Racket** environment.
* **`a-d` Library:** Uses `a-d/graph/weighted/config` for the graph interface. No source files within the `a-d` folder were modified.

```

```

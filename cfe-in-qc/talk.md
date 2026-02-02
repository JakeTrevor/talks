---
paginate: true
---
<style>

section::after {
  content: attr(data-marpit-pagination) '/' attr(data-marpit-pagination-total);
}

section {
  font-family: 'FiraCode Nerd Font';
}

blockquote {
  color: black;
  background: rgb(209, 217, 224);
  padding: 5px;
}

.cols {
  display: flex;
  flex-direction: row;
  gap: 1em;
  height: 100%;
}

.cols > * {
  flex: 1;
  height: 100%;
}

.bigimg {
  display: flex;
  justify-content: space-around;
}

.bigimg > * {
  max-height: 40vh;
  max-width: 40vw;
}

.slightlySmaller {
  font-size: 0.8em;
}

p:has(> img) {
  display: grid;
  place-items: start center;
}

</style>

$$
\newcommand{\llbracket}{[\![}
\newcommand{\rrbracket}{]\!]}
\newcommand{\sem}[1]{\llbracket #1 \rrbracket}
$$

# Control-flow Expressiveness in Quantum Computing

Jake Trevor

---

## In this talk

I will present some work in-review:

- Control-flow expressiveness in classical computing
- Why quantum is different
- The CCF Hierarchy 

And some work in-progress:

- Semantics for the lattice

---
## In classical computing,

#### there are two building blocks of control flow:

- Conditional behaviour (`if` statements)
- Looping behaviour (`while` loops)

---
## Looping behaviour subsumes conditional behaviour

<div class="cols">
<div>

```lua
if (a) {
    b
} 
```

</div>

<div>

```lua
flag = true

while (flag && a) {
    b
    flag = false
}
```

</div>
</div>

---

### There are things we can write with while loops that we can't write without:

```lua hello-world-forever
while (true) {
  print("hello world")
}

```

- `While` *increases the expressiveness* of the language

---

## Similar is true for `if` statements 

```lua
if (randomChoice()) { 
  print("heads")
} else {
  print("tails")
}
```

---
## So, very roughly...


<div class="cols">

<div>

- `while` loops are more powerful than
- `if` statements, which are more powerful than
- no CF whatsoever

</div>

<div>

![](./cfe-in-qc/classical-lattice.png)

</div>

</div>


--- 

### Aside: Is conditional behaviour really more powerful than flat?

Morally - yes, but the devil is in the details.

- If we are talking about instruction languages...
- and an 'if statement' really means a conditional jump...

-> Then the difference in expressiveness depends on the instruction set.

Lots of things can be done branchlessly, if you're clever

---
### Aside: Is conditional behaviour really more powerful than flat?

- If all we have is a function pointer,  (i.e. to an externally defined function)...
- the only way to conditionally call it is with a `cjump` 
    
-> i.e. exactly an if statement.

> Key takeaway: Quantifying this difference is hard
> But it does exist!

---

# Why is QC any different?

---
## Models of Quantum Computation

We will review the three big models of quantum computation:

1. Circuits
2. QRAM
3. Co-Processor Computers

---

## Circuits

A Circuit represents *straight-line code.* 
Generally, there isn't any control flow

#### Deutsch's algorithm:
<div class="cols">

<div>

```lua
function deutsch() {
    a, b = fresh
    X b
    H a
    H b 
    f(a, b) -- our function to measure
    H a
    
    return M a
}

```

</div>

<div>

![](./cfe-in-qc/deutsch-circuit.png)

</div>

</div>

---
## Circuits: Key Characteristics

- Fixed number of qubits (allocation is static)
- Some fixed set of gates are applied (no control flow)

-> Actually, we sometimes slightly relax this.
- We sometimes allow conditioned gate application, based on some measurement result

---

## As in teleportation:

<div class="cols">

<div>

```lua
function teleport(q) { 
    a, b = fresh
    H a
    CX a b

    CX q a 
    H q

    [q', a'] = M [q, a]

    if (a') { X b } 
    if (q') { Z b }
}
```

</div>

<div>

![](./cfe-in-qc/teleportation-circuit.png)

</div>

</div>


---

## QRAM (Quantum Random Access Machine)

First presented by Knill
- Access to some (large) amount of quantum memory
- Generally allows control flow via loops

-> Fully expressive

---
## A simple quantum program with a loop:

```lua
function geometric() { 
  count = 0
  do {
    a = fresh
    H a 
    res = M a 

    count += 1 
  } while (res)

  return count
}

```
---

## Co-processor


<div class="cols">
<div>

-> Extension to QRAM

Two key components:
- the *QPU* (Quantum Processing Unit)
- the *scheduler* (really, just a regular classical computer).

The scheduler tells the QPU what to do

</div>

<div>

![](./cfe-in-qc/co-processor-architecture.png)

</div>
</div>

---
## What about the other way?


<div class="cols">
<div>

### QPU -> Scheduler dataflow

In the co-processor model, dataflow in this direction is given special treatment.

It's called *Dynamic Lifting*

</div>
<div>

![](./cfe-in-qc/co-processor-dyn-lift.png)

</div>
</div>

---

## Why the special treatment?

Notionally, because dynamic lifting **expensive**

Requires the QPU to wait for some classical computation to finish.

Qubits are unstable - they can only hold their state for so long before *losing coherence*.

This is what the co-processor model tries to capture.


---

## Not all dynamic lifting is interesting:

- `C` -> `Q` -> `C`  --- pre- and post-processing
  - Cheap, boring
- `Q1` -> `C` -> `Q2`  --- measurement conditioned continuation
  - Expensive, interesting
  - especially if `Q2` depends on some data from `Q1` being coherently retained
  <!-- (a 'coherent data-dependency') -->

We only really care about the latter case...

But trying to capture this is very difficult
so all dynamic lifting is treated as expensive

---

## Dynamic lifting makes the CF lattice a little more complex:

<div class="bigimg" >

![](./cfe-in-qc/quantum-lattice.png)

</div>

---
## The Classical Control-Flow CCF Hierarchy:


<div class="cols" >
<div>

- **F**, **CC** and **CL** are familiar

-> These are just the points of the classical CF hierarchy

- **QC**, **CLQC** and **QL** are new

-> These involve introducing *dynamic lifting* into the program.

</div>
<div>

![](./cfe-in-qc/quantum-lattice.png)

</div>

</div>

---


## This can help us classify all kinds of things:

- Hardware
- Abstract machines / Models of computation
- Algorithms
- Programming languages

---

## What we looked at earlier:


<div class="cols" >
<div class="slightlySmaller" >

At **F** (Flat):
- Circuits without conditioned application
- Deutsch's algorithm

At **QC**:
- Circuits with conditioned application
- Quantum teleportation

At **QL**:
- QRAM and Co-processor
- The geometric sampling algorithm

</div>
<div>

![](./cfe-in-qc/quantum-lattice.png)

</div>

</div>

---

## I have example programs for each point in the lattice
-> I've left them out here for brevity

---

# Work in progress: Semantics for the Lattice

---
## Idea: 

> - Produce a family of languages...
> - related by adding syntactic features...
> - which capture different levels of the lattice.

Give a semantics to each, and we have a formal way to study the lattice!

<!-- We also get a (conservative) by-construction approach to classifying algorithms 
  - (i.e. if you can implemented in a language at Pt. X, then it requires no more expressiveness than X.) -->

---

## Problem: the full lattice is hard

What is the difference between **CLQC** & **QL**?

- CLQC allows data dependencies on measurements for `if`s, but not `while`s 
- QL allows both

How do we model this syntactically?

-> I haven't come up with a nice way to do this.

---

## (Possibly Temporary) Solution: Reduced lattice

![](./cfe-in-qc/reduced-quantum-lattice.png)

---
<div class="bigimg" >

![](./cfe-in-qc/labelled-reduced-quantum-lattice.png)

</div>

---
## `mrec`: Effectful vs recorded measurement

- Measurement is a critical part of many quantum algorithms, even if when we don't use the result
- Dynamic lifting tries to capture the expense of _conditioning future behaviour on a measurement_
- So we only need to care about measurement when the result is used in the continuation

---

## `mrec`: Effectful vs recorded measurement

- `M q` _measures_ the qubit `q`, but does not record a result
  - This is an effectful measurement 
  - (since we only care about its side effects)
- `a = mrec q` measures `q` and _stores the result_ in the classical variable `a`
  - This is a recorded measurement

---
### A taste of what's cooking: 

Give a denotational semantics, in terms of a function on state 

The state of a QC is probabilistic; At any given time, it may occupy one of many given states, with some associated probability.

Therefore, we model the state as a list of fragments $(p, \sigma)$
such that the sum of probabilities $\sum_p p =1$ 

---

The data part of a fragment ($\sigma$) is comprised of three components:

1. The quantum state $\ket \phi$: a quantum state vector
2. The classical state $s$: a classical bit vector
3. The name map $m$: Mapping of *names* to *data addresses* 
  `Name -> Either Int Int`
  - Left x -> Qubit at index x
  - Right y -> Bit at index y

> We use a bit vector for simplicity, but this technique should generalise to arbitrarily complex classical data

---
### The classical components aren't too interesting:


$$\sem{\text{if(c)\{B\}}} = \texttt{flatmap} (\lambda \sigma. 
  \texttt{if} (\sem{c}\sigma) \quad
    \texttt{then } \sem{B} \sigma \quad
    \texttt{else } \sigma
)
$$


$$\sem {\text{while} (c) \{ B \}} = \mu X. X \circ \sem{\text{if}(c)\{B\}}$$

Note the use of $\texttt{flatmap}$ for $\text{if}$

---
### Sematics of gate application:

$$
\sem {G}_N = G \bigotimes_{|G|}^N ID
$$

$$
\sem{ G q_1...q_n}_N = \texttt{map} (\lambda \sigma.

\texttt{let } \phi = 
(\pi^{-1} \sem{q_1 ... q_n}_N \circ \sem{G}_N  \circ \pi \sem{q_1 ... q_n}_N) \sigma.\phi
\texttt{ in } \{...\sigma, \phi\}
$$

---

## What's left to do?

- measurement
- qubit/cbit allocation
- more complex classical components 
  - (right now, we only have CF)
- a proper, full formalisaiton
- mechanisation? 
  
-> I really like lean, but permutations are quite painful to work with...

- ???
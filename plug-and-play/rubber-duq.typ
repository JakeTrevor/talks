#import "@preview/curryst:0.6.0" as cr
#import "@preview/typewind:0.2.0"
#import "@preview/physica:0.9.8": bra, ket
#import "@preview/fletcher:0.5.8" as fl


#import "@preview/touying:0.7.4": *
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

#show raw.where(block: true): it => {
  show "=>": _ => sym.arrow.r.double.long
  show "->": _ => sym.arrow.long
  show "<=": _ => sym.lt.eq
  it
}

#let isWeakerThan = (
  eq: sym.subset.eq.sq,
)
#let isWeakerThan = sym.subset.sq

#let isSubsumedBy = (
  eq: sym.prec.eq,
)
#let isSubsumedBy = sym.prec

#show math.equation: it => {
  show "@": it => sym.plus.o
  it
}
#let iso = sym.tilde.equiv

#let title = [Plug and Play]
#let subtitle = [Modular Semantics for Quantum Programming Languages]
#let abstract = [
  The semantics of quantum programming languages can be formalised in many ways. These
  different semantic styles have different analytical properties, and are sometimes
  capable of expressing different things. Often, a language must be given a semantics in
  some relatively more complex terms, because of the inclusion of a particular feature.

  In this talk, I will present some in-progress work on modularising the semantics of
  quantum programming languages. This allows us to define the semantics of different
  fragments of a language in different terms, and bring the fragments together in a way
  that retains the semantic structure. Doing so can provide material benefits: for
  example, providing simple decision procedures for the equivalence of some programs, even
  when the semantics given to the language would require a much more complex approach.
  This is based off of some ongoing work mechanising the semantics in the Lean theorem
  prover.
]

#title-slide()[
  = #title
  == #subtitle\

  Jacob Trevor\
  j.trevor.1\@research.gla.ac.uk

  School of Computer Science, University of Glasgow, Glasgow\

  #align(center)[https://github.com/jaketrevor/qpl-semantics]
]


= A Tale of Two Semantics

== Gate Matrix (GM) Semantics
Consider the following program snippet:

```
X 0; X 0
```

What does this program _mean?_

#speaker-note[
  This is how I define the semantics for this; it should look vaguely familiar if you've
  ever looked at e.g. Quil.
]

#pause
#alternatives[$
  cal(G)_N [|-|] &:" "? -> CC^(2^N times 2^N) \
  cal(G)_N [| G #h(0.2em) arrow(q) |] &= pi_N^(-1) arrow(q) dot arrow.t^N G dot pi_N arrow(q)\
  cal(G)_N [|a ; b |] &= cal(G)_N [| b |] dot cal(G)_N [| a |]
$][$
                  cal(G)_N [|-|] & :" "? -> CC^(2^N times 2^N) \
  cal(G)_1 [| #raw("X 0; X 0")|] & = mat(delim: "[", 1, 0; 0, 1)
$]

#speaker-note[
  - We can consider the semantics of such a program on a fixed bitwidth computer
    - (call the bitdwith $N$)

  - We need an operator that _lifts_ gates to the correct size ($arrow.t$)
    - (padding out on the right)

  - and one which permutes the qubits around so the targets are in order on the left
    ($pi_N$)
    - This operates on _partial permutations_

  - With a little wrote calculation, we see the example above is the identity matrix
    - Hopefully, not surprising.
]

== Advantages of GM Semantics:

- Relatively simple to define (See above)
- Easy(ish) to explain
- Analytically, very nice
  - Full abstraction
  - Constructive, decidable equality
  - Directly compare matrices; $2^(2n)$ comparisons

== In fact, lean can just do the check for you, if you set it up correctly:

#figure(
  image("decide.png"),
)

== A (slightly) more complicated program

```
X 0;
X 0;
Meas 0
```

We can't give this a GM semantics - we need something _stronger_

== Density Operator Transformer (DOT) Semantics

$
  cal(D)_N [|-|] &:" " ? -> rho_N -> rho_N\
  cal(D)_N [|a ; b |] &= cal(D)_N [| b |] compose cal(D)_N [| a |]\
  cal(D)_N [| G #h(0.2em) arrow(q) |] &= "let" G' := pi_N^(-1) arrow(q) dot arrow.t^N G dot pi_N arrow(q)'\
  & "    in" lambda rho. G' rho G'^dagger\
  cal(D)_N [|#raw("Meas q")|] &= lambda rho . sum_(i in "t", "f") P_i rho P_i^dagger
$

== Comparison

*DOT semantics is a little less nice*
- Direct equality check no longer works
  - Must instead check a _basis_
  - \~ $2^(2n)$ vs $(2^(2n))^2$ comparisons i.e. quadratic slowdown
  #speaker-note[
    For large programs, this is quite bad.

    And this also does not account for the overhead involved in _computing_ the
    representation, and then passing through each basis state

    This is also worse for DOT than for GM
  ]
  - hard to mechanise

*But!*
- We can handle programs with measurement
#pause
*A tale as old as time:* to handle more complicated languages, we need more complicated
semantics

== The baby and the bathwater

- Do we have to give up the nice analytic properties of our simple semantics to be able to
  work in more expressive languages?

#pause

I say: No!

- Cut the language up into _features_\*
- Give each a _weakest semantics_\*
- Define a way to _glue_ features together
- In a way that lets us derive the semantics of the result

\* we'll define this in a moment

= Fragments and Feature sets

== Language Features

Take a look at this program again:

```
X 0;
X 0;
Meas 0
```

#pause
Two distinct parts:
- `Meas 0` requires DOT ($cal(D)$) semantics... #pause
- but `X 0` can be given GM ($cal(G)$) semantics

#pause

*Idea:* Cut this language up into "little languages"

== Prior work

- What follows is essentially a specialisation of Wouter Swierstra's DTalC @dtalc
- Since I am mechanising it, a bit of extra trickery required to make the typechecker
  happy
  - i.e. containers
- This is a technique adapted from Jonas Maier's 2025 Masters Thesis (LRalC) @lralc

== Features

- A language _feature_ is meant to capture "doing one kind of thing"
  - À la the little languages of Jon Bentley @bentley_little_langs_1986

#pause
So:

Unitary App ($U$) = { $G#h(0.2em) arrow(q)$ }\
Effectful Measurement ($M$) = { $"Meas" q$ }
#pause

- Each feature becomes a _container_

== Containers in 30 seconds

- Think of a container as consisting of:
1. A constant part
2. A number of holes
- The extension of a container into $Y$ tells you how to fill the holes with $Y$s
- We are interested in extending the container into more copies of itself...
- Called the fixed point of a container

== Constant Data
```lean
-- α the type of matrix entries
-- i the bitdwidth of the circuit

inductive uData i α  where
  | app : (h_size : n <= i) -- proof the gate fits
        -> Gate n α         -- the gate to apply
        -> PartialPerm n i  -- the list of targets
        -> uData i α

inductive mData i (α : Type) where
  | meas : Fin i -> mData i α
```

== Containers

```lean
-- Command D n = "A command with constant data D and n holes"
abbrev Command (data : Type) (arity : Nat) : Container
  := {shape := data, pos := fun _ => Fin arity}


def U := Command uData 0
def M := Command mData 0

def Seq := Command Unit 2 -- sequence two commands
```

== Key idea

- We can add feature containers together by taking their _coproduct_ ($plus.o$)
  - The result is another container
- Our AST is now the _fixed point_ of some container

#pause

e.g. the AST of circuit, the language of our second example, can be defined as:
$
  "Circuit" := ("Seq" @ U @ M)."fix"
$


== Semantics of Containerised ASTs

- Define semantics via the container recursor
#align(center)[
  #cr.prooftree(
    cr.rule(
      [$cal(X)[|A."ext" cal(X)|]$],
      [$cal(X)[|A."fix"|]$],
    ),
  )
]

- Sort-of like a post-order tree traversal
  - Given that we evaluate the children of this node...
  - i.e for each hole, we have an $cal(X)$
- So just define the semantics of $A."ext" cal(X)$

== Deriving Semantics


- If $A$ and $B$ have semantics in the same terms, then their coproduct does too

#align(center)[
  #cr.prooftree(
    cr.rule(
      [$cal(X) [|A."ext" cal(X) |]$],
      [$cal(X) [| B."ext" cal(X) |]$],
      [$cal(X) [| (A @ B)."ext" cal(X) |]$],
    ),
  )
]

- Via pattern-matching on the shape, and applying the corresponding instance
- See Lean for details


= Subsumption

== Subsumption

- Even with a finite collection of features, there's an infinite variety of feature sets
  - $A, A @ A, A @ A @ A, ...$
- It's also clear that $A$ is somehow inside $A @ B$
  - e.g. {`X 0; X 0`} is inside `X 0; X 0; M 0`
- How do we formalise this notion?

== Subsumption

A language _subsumes_ another if there's a semantics preserving transformation from one to
the other

$
  A prec.eq[cal(X)] B <=> exists (f : A -> B). cal(X)[|x|] = cal(X)[|f x|]
$

#pause

When the semantics in question is obvious, I'll omit the $[cal(X)]$ e.g.

$
  A prec.eq B
$

== Isomorphisms

- If there's a semantics preserving function in both directions, then the languages can
  express _exactly the same things_
- i.e. they are isomorphic.
- We write
$
  A iso B <=> A prec.eq B and B prec.eq A
$
#pause
- If $A prec.eq B$ but not $B prec.eq A$ then we write $A prec B$
- intuitively, B can express things A cannot

== Normal form lemmas

#alternatives()[$
  (1) A."fix" isSubsumedBy.eq (A @ A) ."fix" && (2) (A @ A)."fix" isSubsumedBy.eq A."fix" \ \
  & (3) (A @ B)."fix" isSubsumedBy.eq (B @ A)."fix"
$][$
  (1) A isSubsumedBy.eq A @ A && (2) A @ A isSubsumedBy.eq A \ \
  & (3) A @ B isSubsumedBy.eq B @ A
$]

#pause

- (1) and (2) say $A iso A @ A$
  - Need only consider $A$; $A @ A$ &c. are equivalent
- (3) gives us $A @ B iso B @ A$ #pause
- Together, these give us a normal form for feature sets
  - Distinct features only
  - "Lexicographic" ordering

== Embedding lemma
$
  A isSubsumedBy.eq A @ B
$

- *Intuition:* There's an obvious way to embed $A$ into a larger feature set
#pause
- *Implication:* Programs in smaller feature sets are valid in larger ones
  - i.e. _syntactic subsumption_
#pause
- *Reminder:* $prec.eq$ means we have a SPF from $A$ to $A @ B$
  - So for any program in $A$, we can generate the matching program in $A @ B$
  - e.g. $"emb"_(U @ M) { - }_U$ embed the program "$-$" in $U$ into $U @ M$

== Aside:
- I've omitted the proof for these, but there's a verified version in lean
- the proofs aren't particularly hard or interesting.

== Summary so far:

- We can cut a language up into fragments
- We can add the fragments together as we wish
- So long as they all have semantics in the same terms, we can derive semantics the larger
  products

#pause

=== What if I don't want to give semantics in the same terms all the time?

= Semantic strength and weakness

== Semantic strength

*Fact:* We can derive a DOT ($cal(D)_N [|-|]$) semantics from the GM ($cal(G)_N [|-|]$)
semantics

$
  cal(G)_N [|-|] & : " " ? -> "Gate" N \
  cal(D)_N [|-|] & : " " ? -> rho_N -> rho_N \
  #pause
  cal(D)_N [|x|] & = lambda rho." "(cal(G)_N [|x|]) rho (cal(G)_N [|x|]^dagger)
$

== Semantic strength
Put another way, we have a function:
$
  & "cast" : && "Gate" N && -> rho_N -> rho_N \
  & "cast"   && G        && = lambda rho." "( G) rho ( G^dagger) \
$$
  cal(D)_N [|x|] & =" " "cast" compose cal(G)_N
$

#pause

- $cal(D)_N$ is derivable from $cal(G)_N$, so $cal(G)_N$ is weaker than $cal(D)_N$
  ($cal(G)_N isWeakerThan.eq cal(D)_N$)

  - Note $cal(G)_N isWeakerThan.eq cal(D)_N$ is the same way around as the function
    $"Dom"(cal(G)_N) -> "Dom"(cal(D)_N)$

== Aside: Sensible Functions

- $"cast"$ needs to be a _sensible_ choice of function #pause
- We shouldn't lose information in the transformation #pause
- Therefore, it should be an _embedding_ i.e.
$
  exists arrow.b, arrow.b compose "cast" = "id"
$
#pause
- Proving that the $"cast"$ function above is a proper embedding has proved to be tricker
  than expected
- Only works up to a global phase
- Which is OK, but harder to mechanise... WIP

== Note that the same is not true in reverse:

- DOT semantics ($cal(D)_N$) can express more than GM semantics ($cal(G)_N$)
- We can't embed $cal(D)_N$ into $cal(G)_N$
- Therefore $cal(G)_N isWeakerThan cal(D)_N$

== Weakest semantics

A language $L$ has a weakest semantics in $cal(X)$ iff for any other semantics of $L$
$cal(Y)$, $cal(X) isWeakerThan.eq cal(Y)$

#pause
- Why care?
#pause

- This makes $cal(X)$ a _complete description_ of $L$
- $cal(X)$ is sufficient to derive any other semantics we might want
- Need only define $cal(X)$, get everything else "for free"

== Formalising some folklore

#figure[
  #fl.diagram(
    spacing: 3em,
    node-outset: 0.4em,
    $
                              & "Hybrid Representations" \
      fl.edge("ur", ->)
      "Density Operator\n Trx"
      fl.edge("rr", ?, "<->") &                          & "Ensemble State\n Trx"
                                                           fl.edge("ul", ->) \
                              & fl.edge("ul", ->)
                                fl.edge("ur", ->)
                                "Gates/Matrices"
    $,
  )
]

*Caveat:* The exact shape of this is still in question

== Big Result:

- Give semantics to each feature in the weakest form
- Derive semantics of feature sets in their weakest form
  - i.e. the least upper bound of the features w.s.
  - Works so long as we are working in a CPO of semantic domains

#pause

=== But!
- This isn't just a neat trick
- By congruence, equality judgements in simpler semantics _must hold_ in more complex ones

i.e. if $cal(X)[|a|] = cal(X)[|b|]$ and
$X isWeakerThan.eq Y <=> cal(Y) = "cast" compose cal(X) [|-|]$ then
$cal(Y)[|a|] = cal(Y)[|b|]$

== Concretely...

- If I know that $cal(G)_N [|{#raw("X 0; X 0")}_U|]$ = $cal(G)_N [| {}_U |]$
  - where ${}$ is the empty program
  - prove easily by calculating the matrix representation of each side #pause
- Then I know that $cal(D)_N [|{#raw("X 0; X 0")}_U|]$ = $cal(D)_N [| {}_U |]$ #pause
- And I can then conclude that
$cal(D)_N [|"emb"_(U plus.o M){ #raw("X 0; X 0")}_U |]$ =
$cal(D)_N [| "emb"_(U plus.o M) {}_U |]$ #pause
- And thus show that $cal(D)_N [| {#raw("X 0; X 0; M 0")}_(U plus.o M)|]$ =
  $cal(D)_N [| {#raw("M 0")}_(U plus.o M) |]$
- Without ever having to look at a DOT!

Verifying certain kinds of program rewriting is now trivial!

= Future work & Conclusions

== Strengthening: problem
Naïvely strengthening along $X isWeakerThan.eq Y$ yields:

$
  #cr.prooftree(cr.rule(
    [$X isWeakerThan.eq Y$],
    [$cal(X)[|A."ext" cal(X)|]$],
    [$cal(Y)[|A."ext" cal(X)|]$],
  ))
$

- Which isn't quite right
  - remember we need $cal(Y)[|A."ext" cal(Y)|]$ to define $cal(Y)[|A."fix"|]$
- There is a fix...

== Strengthening: fix

Split your features into:
- "terminal features" --- with $n=0$ holes, and set semantics in $cal(X)$
  - Yields $forall beta, cal(X)[|A."ext" beta|]$
  - Ensure $cal(X)$ is the weakest semantics, and we're done
- "structural features" --- with $n>0$ holes, and _parametric_ semantics
  - i.e. semantics is defined $forall alpha, alpha[|A."ext" alpha|]$
  - No strengthening needed
  - You're allowed to put restrictions (e.g. typeclass constraints) on $alpha$


== Onwards

- A few definitions still use `sorry`
#pause
- Next Stop: Hybrid languages
  - Semantics becomes much more interesting when classical co-processing is involved
  - Should be some nice strength & subsumption results to come
  - Dynamic qubit allocation is of particular interest

== Onwards
- If you're thinking 'Weakest Semantics' sounds an awful lot like 'Initial Model' #pause
  - I agree!
  - Someone should think about it
  - Not me (for now)

== Applications

- Clear applications to _program optimisation_
  - Every equivalence between two programs induces a SPF
  - If this SPF is an "improvement"
  - It's a verified optimisation
  - Valid even in more complex languages
  - See last slide of previous section for an example
  - Mechanise/automate the generation of such functions

#bibliography("refs.bib")


== That's all folks

*Lean code repository:*\
https://github.com/jaketrevor/qpl-semantics


*Contact me:*\
J.Trevor.1\@research.gla.ac.uk

=== Any Questions?

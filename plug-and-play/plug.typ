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

#set math.vec(delim: "[")
#set math.mat(delim: "[")

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

// #slide[
//   (A mercenary introduction to)
//   = Quantum
// ]

// == State vectors

// - 1-qubit quantum states are modelled generically by state vectors:

// $
//   ket(psi) = vec(alpha, beta)\
//   alpha, beta in CC\
//   "such that" |alpha|^2 + |beta|^2 = 1
// $

// - $alpha, beta$ are the _amplitudes_ of the state, and dictate the measurement statistics

// == Gates

// - Gate application can be modelled as matrix-vector mutiplicaiton

// $
//   X = mat(0, 1; 1, 0)
// $

// $
//   X ket(psi) = mat(0, 1; 1, 0) vec(alpha, beta) = vec(beta, alpha)
// $

// - Gates are (unitary) matrices

// == Measurement

// - When we measure a qubit, there are two possible outcomes:
//   - $ket(0)$ with probability $|alpha|^2$
//   - $ket(1)$ with probability $|beta|^2$

// - There's no way to represent this as a single state vector

// - State vectors alone are not a good representation for computation involving measurement

// == Density Operators
// - Alternative (more powerful) representation
// - Given a state vector $ket(psi)$, we can turn it into a density operator:
// $
//   ket(psi)bra(psi)
// $
// - i.e. we take the outer product of $ket(psi)$ with itself

// $
//   vec(alpha, beta) mat(overline(alpha), overline(beta)) = mat(
//     alpha overline(alpha), alpha overline(beta);
//     beta overline(alpha), beta overline(beta)
//   )
// $
// #pause
// #align(center)[*The diagonal entries are measurement probabilities*]

// == CPTP maps
// - State vectors are mutated by gate matrices
// - Density operators are mutated by quantum channels
// - Essentially, functions on density operators
// $
//   epsilon : rho -> rho
// $

// - Not just any function;
// - channels are *completely positive trace preserving maps*


// == Choi
// - We can represent channels in a number of different ways;
// - In this talk, I will treat them as _functions_
// #pause
// - In reality, *Choi matrices* are the relevant semantic domain for programs with
//   measurement
//   - Written $X_epsilon$
//   - A single large matrix that represents the channel
//   - An $n$-bit Choi matrix is $2^(4n)$ vs $2^(2n)$ for a gate
// - But I won't go into detail on how it's constructed



= A Tale of Two Semantics



== Gate Matrix (GM) Semantics
Consider the following program snippet:

```
X 0; X 0
```

What does this program _mean?_

#pause
#alternatives[
  - Apply the $X$ gate
  - To qubit 0
  - Twice
][$
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

- We can't give this a GM semantics - we need something _stronger_
- Give a semantics as a CPTP map
  - i.e. a function on density operators
  - Density operator = standard representation of quantum states
  - Which supports measurement

== CPTP Map Semantics

$
  cal(D)_N [|-|] &:" " ? -> rho_N -> rho_N\
  cal(D)_N [|a ; b |] &= cal(D)_N [| b |] compose cal(D)_N [| a |]\
  cal(D)_N [| G #h(0.2em) arrow(q) |] &= "let" G' := pi_N^(-1) arrow(q) dot arrow.t^N G dot pi_N arrow(q)'\
  & "    in" lambda rho. G' rho G'^dagger\
  cal(D)_N [|#raw("Meas q")|] &= lambda rho . sum_(i in "t", "f") P_i rho P_i^dagger
$

== Comparison

*CPTP Map semantics are a little less nice*
- $2^(2n)$ vs $2^(4n)$ comparisons i.e. quadratic slowdown
- harder to mechanise

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
- Give each some semantics
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
- `Meas 0` requires CPTP map ($cal(D)$) semantics... #pause
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
Effectful Measurement ($M$) = { $"Meas" q$ }\
Sequencing (Seq) = { \_ ; \_}
#pause

- Each feature becomes a _container_

== Containers in 30 seconds

- Think of a container as consisting of:
1. A constant part
2. A number of holes
#pause
- The extension of a container into $Y$ tells you how to fill the holes with $Y$s
#pause
- We are interested in extending the container into more copies of itself...
#pause
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

- For more details, check slides from last week

= Semantics = Algebra

== Functors Refresher
- Say $cal(C)$ is the category of types and total functions
- if $F : cal(C) -> cal(C)$ is an endofunctor on $cal(C)$
- it's a map that takes types to types
  - $A : "Type" tack.r F A : "Type"$
  - Functors = type formers
- and functions to functions
  - $g : A -> B tack.r F g : F A -> F B$

== _Functors_ generate syntax
- $F A$ = $F$-shaped expressions with $A$s in the holes
- $F : cal(C) -> cal(C)$ is called the _signature_ functor
#pause
- An algebra for the signature $F$ (an $F$-algebra) is a pair:
$
  (A : C, alpha : F A -> A)
$
#pause

- $A$ is called the _carrier_
#pause
- $alpha$ is called the _action_
  - $alpha$ = "eval"
  - Given an expression ($F A$) compute it's value ($A$)


== Fixed points

- $mu F$ = fixed point of $F$
  - $F (mu F) iso mu F$
  #pause
  - Intuition: "recursive expressions"
  #pause
  - Expressions with more expressions in the holes
  #pause
  - There's a function from $F (mu F)$ to $mu F$ that _preserves all structure_
  - (i.e. it's invertible)
  #pause
  - We call this function "$"in"$"
  #pause
- Use this to define the initial algebra of $F$:
$ (mu F : cal(C), " in" : F (mu F) -> mu F) $

== Initial Algebra
$ (mu F : cal(C), " in" : F (mu F) -> mu F) $
- *intuition:* "flatten out" expressions
- "Given expressions where the holes are filled with recursive expressions, give me a
  single recursive expression"
#pause

- Quite boring: "eval" doesn't really do anything
  - This is by design
  - Instead, it specifies a way to deal with these "recursive expresions"
  - How to traverse $mu F$


== Recursion

- Initial algebra lets us define the fold function:

$ "fold" : (alpha : F A -> A) -> (mu F -> A) $

#pause

- It makes the following diagram commute:
#figure[
  #fl.diagram(
    $
      F (mu F)
      #fl.edge("r", "->", label: "in")
      #fl.edge("d", "->", label: $F ("fold" alpha)$)
      & mu F
      #fl.edge("d", "->", label: $"fold" alpha$) \
      F A #fl.edge("r", "->", label: $alpha$) & A
    $,
  )
]




== When does this work?

- Not every functor has a well defined initial algebra
#pause
- But those that are strictly positive always do
#pause
- This is the original motivation for containers:
  - Containers = data types with well defined recursion
  - We can define fold for containers

== An intuition for $"fold"_alpha$

```lean
def fold (c : Container)
  (alpha : c.extension A -> A)
  : c.fix -> A
  | .mk s ch =>
    let ch' i := fold c alpha (ch i)
    alpha ⟨s, ch'⟩
```
#pause
- Evaluate the children (recursively)
#pause
- Then evaluate self
  - Hopefully at some point reaching a leaf with no children
#pause
#align(center)[*\= Post order traversal*]



== Semantics = Algebra

- (Collections of) features are containers $A$
- The AST of the resulting language is $A."fix"$ #pause ($= mu (A."ext")$)
  - (Recall: ext is a functor!)
#pause
- A semantics for $A$ in $cal(X)$ is a function $cal(X)[|-|] : A."fix" -> cal(X)$
#pause
- As we saw, we can define this by giving $alpha : A."ext" cal(X) -> cal(X)$
  - $alpha$ is the action of an $F$-algebra
#pause

#align(center)[*Semantics for $A$ in $cal(X)$ = Model of signature $A$ in $cal(X)$*]



== Deriving Semantics


- If $A$ and $B$ have semantics in the same terms, then their coproduct does too

#align(center)[
  #cr.prooftree(
    cr.rule(
      [$alpha : A."ext" cal(X) -> cal(X)$],
      [$beta : B."ext" cal(X) -> cal(X)$],
      [$alpha times.o beta : (A @ B)."ext" cal(X) -> cal(X)$],
    ),
  )
]

- Via pattern-matching on the shape, and applying the corresponding instance
- $alpha times.o beta$ is a "coproduct model"
- See Lean for details


= Subsumption

== Subsumption

- Even with a finite collection of features, there's an infinite variety of feature sets
  - $A, A @ A, A @ A @ A, ...$
- It's also clear that $A$ is somehow inside $A @ B$
  - e.g. {`X 0; X 0`} is inside {`X 0; X 0; M 0`}
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

*Fact:* If you give me a gate, I can give you a CPTP map:

$
  & e : && "Gate" N && -> rho_N -> rho_N \
  & e   && G        && = lambda rho." "( G) rho ( G^dagger) \
$

- $cal(D)_N$ is derivable from $cal(G)_N$, so $cal(G)_N$ is weaker than $cal(D)_N$
  ($cal(G)_N isWeakerThan.eq cal(D)_N$)
- Note $cal(G)_N isWeakerThan.eq cal(D)_N$ is the same way around as the type of $e$

#align(center)[*Can we leverage this somehow?*]

== Aside: Sensible Functions

- $"cast"$ needs to be a _sensible_ choice of function #pause
- We shouldn't lose information in the transformation #pause
- Therefore, it should be an _embedding_ i.e.
$
  exists p, p compose e = "id"
$

- Similar to the domain theory idea of _embedding/projection pair_
  - Thus the names $e, p$

== Note that the same is not true in reverse:

- CPTP semantics ($cal(D)_N$) can express more than GM semantics ($cal(G)_N$)
- We can't embed $cal(D)_N$ into $cal(G)_N$
- Therefore $cal(G)_N isWeakerThan cal(D)_N$

== Strengthening

- If a language has a semantics in $cal(X)$,
- and $cal(X) isWeakerThan.eq cal(Y)$,
- then we can use $e$ to _derive_ the semantics in $cal(Y)$

$
  cal(Y)[|-|] = e compose cal(X)[|-|]
$

#pause

#align(center)[
  *Prove things are equal in $cal(X)$, by congruence also equal in
  $cal(Y)$*\

  Lift judgements from simple domains to more complex ones!
]

== Strengthening: problem
Naïvely strengthening along $cal(X) isWeakerThan.eq cal(Y)$ yields:

$
  #cr.prooftree(cr.rule(
    [$cal(X) isWeakerThan.eq cal(Y)$],
    [$alpha : A."ext" cal(X) -> cal(X)$],
    [$e compose alpha : A."ext" cal(X) -> cal(Y)$],
  ))
$

- Which isn't quite right
#pause
- remember: we need $A."ext" cal(Y) -> cal(Y)$ to define $A."fix" -> cal(Y)$ via fold
  - So a model in $cal(X)$ doesn't guarantee one in $cal(Y)$
- Causes a problem when trying to lift judgements

== Strengthening: problem (continued)

- Consider two programs $p, q : A."fix"$
#pause
- $A$ has a model in $cal(X)$ ($alpha : A."ext" cal(X) -> cal(X)$)
#pause
- Giving a semantics $cal(X)[|-|] : A."fix" -> cal(X) = "fold" alpha$
#pause
- Now consider that we want to rewrite along $cal(X)[|p|] = cal(X)[|q|]$
#pause
- ...in $A plus.o B$, where there is only a semantics in
  $cal(Y), cal(X) isWeakerThan.eq cal(Y)$
#pause
- The semantics in $A plus.o B$ is given by $cal(Y)[|-|] = "fold" (beta_A times.o beta_B)$
#pause
- Requiring us to have a model $beta_A : A."ext" cal(Y) -> cal(Y)$
#pause
- But for the congruence argument to work, we require:
$
  "str" ("fold" alpha) = "fold" beta_A
$





== Strengthening: fix

Split your features into:
- "terminal features" --- with $n=0$ holes
- "structural features" --- with $n>0$ holes,

== Terminal features (\#holes = 0)

- *Observation:* All extensions of a terminal features are isomorphic
  - extension = fill holes
  - no holes to fill $->$ all fillings are the same
  #pause
- Define:
$
  "spec" : forall x" "y, ("Tm" A)."ext" x -> ("Tm" A)."ext" y
$
- (spec is self-inverse, and defines the isomorphism)
- It's enough to give semantics to a 'trivial filling' i.e. extension into Unit

== Terminal Features

#align(center)[
  #fl.diagram(
    $
      A -> cal(X)
      fl.edge("r", "->", label: "str")fl.edge("d", "->", label: "Tm") & A -> cal(Y)
      fl.edge("d", "->", label-anchor: "east", label: "Tm")
      \
      ("Tm" A)."ext" top -> cal(X)
      fl.edge("r", "->", label: "str")
      fl.edge("d", "->", label: "fold" compose "spec")
      & ("Tm" A)."ext" top -> cal(Y)
      fl.edge("d", "->", label-anchor: "east", label: "fold" compose "spec")
      \
      ("Tm" A)."fix" -> cal(X)
      fl.edge("r", "->", label: "str") & ("Tm" A)."fix" -> cal(Y) \
    $,
  )
]


== Structural features (\#holes > 0)

- So far, I've found no way to automate the generation of semantics
- Instead, we require you to provide an algebraic model for each domain
- The two models must be "consistent" with the e/p pair
  - Strengthening from the weaker model should be the same as the stronger model

== A diagram helps

- Two $A$-models $alpha : A."ext" cal(X) -> cal(X)$ and $beta : A."ext" cal(Y) -> cal(Y)$
  are consistent ($alpha tilde beta$) iff this diagram commutes:

#align(center)[
  #fl.diagram(
    $
      & top
      fl.edge("dl", "->", label: gamma alpha)
      fl.edge("dr", "->", label: gamma beta)
      \
      A."ext" cal(X) -> cal(X)
      fl.edge("d", "->", label: "fold")
      & & A."ext" cal(Y) -> cal(Y)
      fl.edge("d", "->", label: "fold")
      \
      A."fix" -> cal(X) fl.edge("rr", "->", label: "str") & & A."fix" -> cal(Y) \
    $,
  )
]

== Current question: Coproduct coherence

Given

- two domains $cal(X), cal(Y), cal(X) isWeakerThan.eq cal(Y)$
- two features $A, B$,
- for each, a model in $cal(X)$ ($alpha_A, alpha_B$) and $cal(Y)$ ($beta_A, beta_B$)
- If their respective models are consistent wrt the embedding
  - $alpha_A tilde beta_A, alpha_B tilde beta_B$

Are the two resulting coproduct models consistent?
- $alpha_A times.o alpha_B tilde beta_A times.o beta_B$

= Assuming that works out

== Concretely

- If I know that $cal(G)_N [|{#raw("X 0; X 0")}_U|]$ = $cal(G)_N [| {}_U |]$
  - where ${}$ is the empty program
  - prove easily by calculating the matrix representation of each side #pause
- Then I know that $cal(D)_N [|{#raw("X 0; X 0")}_U|]$ = $cal(D)_N [| {}_U |]$ #pause
- And I can then conclude that
$cal(D)_N [|"emb"_(U plus.o M){ #raw("X 0; X 0")}_U |]$ =
$cal(D)_N [| "emb"_(U plus.o M) {}_U |]$ #pause
- And thus show that $cal(D)_N [| {#raw("X 0; X 0; M 0")}_(U plus.o M)|]$ =
  $cal(D)_N [| {#raw("M 0")}_(U plus.o M) |]$
- Without ever having to look at a CPTP map!

Verifying certain kinds of program rewriting is now trivial!

= Future work & Conclusions

== Onwards

- A few definitions still use `sorry`
#pause
- Next Stop: Hybrid languages
  - Semantics becomes much more interesting when classical co-processing is involved
  - Should be some nice strength & subsumption results to come
  - Dynamic qubit allocation is of particular interest


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

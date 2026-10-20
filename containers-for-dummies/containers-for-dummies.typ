#import "@preview/fletcher:0.5.8" as fl

#import "@preview/touying:0.7.4": *
#import themes.simple: *

#let hidden = it => []

#show: simple-theme.with(aspect-ratio: "16-9")
#show "->": it => math.arrow.long
#show "=>": it => math.arrow.double.long

#let title = [Containers for Dummies]
#let subtitle = [Or: Strictly Positive Data Types à la Carte]
#let abstract = [
  Recursively defined structures are ubiquitous in computer science. When formalising such
  structures in a system like Lean or Agda, they are required to satisfy a condition
  called strict positivity. Work in such a system long enough, and you will surely run
  into positivity problems when trying to formalise things in the natural way. Containers
  are a tool developed (among other reasons) to tackle positivity problems. They are
  flexible enough to model a variety of structures in a way which is strictly positive by
  construction - and therefore, amenable to use in a theorem prover like lean or agda.

  Despite their usefulness, containers remain something of a mystery to many people. Part
  of this, I believe, is due to the presentation in the existing work, which tends to be
  about the category theory underpinning them. In my experience however, they are much
  like monads; it is not necessary to understand the theoretical underpinning to use
  containers or find them useful. A simpler presentation is possible.

  In this talk, I will give this simpler presentation. I will explain what containers are,
  why they are useful, and how to use them, without reference to the categorical
  underpinnings. This will be heavily motivated by examples, which have been adapted from
  my own research work.
]


#title-slide[
  = #title
  == #subtitle
  #v(2em)

  Jacob Trevor #footnote[School of Computing Science, University of Glasgow]

  Today
]

== The menu:

- Containers are _very useful,_ particularly if you are working in a mechanised setting.
  #pause
- All the literature is category flavoured,#pause
  - & consequently a touch confusing for some
#pause
- I will explain what containers are, by looking at an application to a particular example
- Hopefully without any reference to the categorical underpinnings
- which is just a well because
#pause
Disclaimer: I am not a category theorist


== Quick preliminary: Dependent Type theory

```lean
def Fin n := { x : Nat // x < n }
-- "all natural numbers less than n"

example : (Σ x : Nat, Fin x) := ⟨1, 0⟩
--         ^ sigma type          ^  ^ Fin x ( = fin 1)
--           (dependent pair)    | x : Nat
-- pair of numbers; 2nd < 1st

```

= A motivating example: Expressions

== Syntax trees

PL people formalise _languages_ as syntax trees

When we write something like

$ a + b times c $

== We represent it with a tree like this:
#align(center)[

  #fl.diagram(
    cell-size: 15mm,
    $
                       & + \
      a #fl.edge("ur") &                 & times #fl.edge("ul") \
                       & b#fl.edge("ur") &                      & c #fl.edge("ul")
    $,
  )
]


#pause
We call this an _abstract syntax tree (AST)_

== Grammar

We formally describe how to build such trees with a _grammar_
#pause

Here's a simple grammar for arithmetic expressions, such as the one we just saw:

$
  "Expr" E = & NN \
           | & E + E \
           | & E times E
$

What if I want to add a new binary operation?

== Simple Approach: add more constructors
$
  "Expr" E = & NN \
           | & E + E \
           | & E times E \
           | & E ** E
$
#pause

- But now, all our old use sites will break
- Need to rewrite everything!
- with this approach, it's difficult to _scope changes_.
- *Can we do better?*

== The Expression Problem

#quote(attribution: [Phil Wadler])[The goal is to define a datatype by cases, where one
  can add new cases to the datatype and new functions over the datatype, without
  recompiling existing code, and while retaining static type safety (e.g., no casts).]

> Phil Wadler

== Enter Data Types a la Carte

- Fantastic Functional Perl by Wouter Swierstra@dtalc
  - It's friendly, entertaining and approachable (go read it!)

Basic idea:
1. define _pieces_ or _fragments_ of the language
2. define a way to glue them together

== Step 1: Fragments

$
  "LitExpr" = & NN \
  "AddExpr" = & E + E \
  "MulExpr" = & E times E \
  "PowExpr" = & E ** E
$

== Or, in lean:

```lean
inductive LitExpr where
  | val : Nat -> LitExpr

inductive AddExpr where
  | plus : E -> E -> AddExpr

inductive MulExpr where
  | mul : E -> E -> MulExpr

inductive PowExpr where
  | pow : E -> E -> PowExpr
```

== What's `E`?
```lean
inductive AddExpr where
  | plus : E -> E -> AddExpr
```
- Here, `E` is _whatever goes in the holes_ of (+)
- So, `E` is an expression. #pause
- A simple idea:
```lean
inductive AddExpr where
  | plus : AddExpr -> AddExpr -> AddExpr
```
But now, I can only add other add expressions...

== What's `E`?
The real fix is to make `E` an argument of the inductive type:
```lean
inductive AddExpr (E : Type) where
  | plus : E -> E -> AddExpr E
```

- So an `(AddExpr Nat)` is an add expression where the holes are filled with `Nat`s
  - eg. 1 + 2



== Important difference

- Before, `Expr` was a type
- but `AddExpr` &c are now _type formers_
  - they need an argument
- _E_ is the _type of subterms_
  - this is the expression AS#emph[Tree]
  - E is the type of _child nodes_

== Step 2: Glue

- We want "Either Add or Mul or Pow" #pause
  - Sounds like a coproduct!
  - Needs to be a bit special, to pass through `E` #pause
```lean
inductive coprod (A B : Type -> Type) (E : Type) : Type  where
  | inl : A E
  | inr : B E

infixr:50 " :+: " => coprod
```
N.B. as a result, `LitExpr` also needs to take in an `E`

== What should `E` be?
We can now write:

```lean
def Expr := LitExpr :+: AddExpr :+: MulExpr :+: PowExpr
```
#pause
- But this isn't quite right - `Expr` here has type `Type -> Type`

#pause

- Recall: `E` is the _type of subterms_ #pause
  - The children of an expression are expressions

- So we want something like:

```lean
def Expr :=
  (LitExpr :+: AddExpr :+: MulExpr :+: PowExpr) Expr
```

== Taking the Fixpoint
Swierstra sets this up with a special function:

```lean
def fix f := f (fix f)
```
And then you can simply do:

```lean
def Expr :=  fix (AddExpr :+: MulExpr :+: PowExpr)
```

And just like that, you have defined a totally modular AST for your expressions!

== Isn't this attractive?
- Define language in fragments
- Glue them together as you like
- There's also discussion in the paper about how to modularise things like evaluation and
  type checking
  - in short, use typeclasses

I certainly thought so

Only one problem...

== This presentation is badly behaved

```lean
def fix f := f (fix f)
```

- `fix` doesn't terminate #pause
  - think about unfolding this definition:
```lean
def fix f := f (f (f (f ...)))
```
#pause
- There's no base case for the recursion
- The same thing happens if we use the raw definition for `Expr` #pause
- *It's not allowed in lean*

= So, what do we do about it?

= Our hero: Containers


== Templates $!=$ Containers

- Jumping straight in to a full description of containers is probably a bit much
- So I will introduce a simplified version first
- We will slowly hack away at it until we get to the real thing

== Let's look at our modular expressions again:

```lean
inductive LitExpr (E : Type) where
  | val : Nat -> LitExpr

inductive AddExpr (E : Type) where
  | plus : E -> E -> AddExpr

inductive MulExpr (E : Type) where
  | mul : E -> E -> MulExpr

inductive PowExpr (E : Type) where
  | pow : E -> E -> PowExpr
```
== Expr = data + arity
We can think of each expression as having a _constant part_ and an _arity_

#pause

```lean
inductive AddExpr (E : Type) where
  | plus : E -> E -> AddExpr
--  ^      ^---^ 2 subterms (Es) = arity 2
--  | constant part = "it's a (+) expr"
```
#pause
```lean
inductive LitExpr (E : Type) where
  | val : Nat -> LitExpr -- 0 subterms (Es) = arity 0
--  ^     ^  constant part = 'its a literal' + value

```
#pause
The same goes for both of our other expression constructors

== Expression Templates
We can define a structure which represents a template for an expression:

```lean
structure Template where
  data : Type -- some constant part
  arity : Nat -- the arity i.e. #subterms
```
== Example:

```lean
-- the constant data:
inductive LitD where | val   : Nat -> LitD
inductive AddD where | plus  : AddD
inductive MulD where | times : MulD
inductive PowD where | pow   : PowD

-- the templates:
def LitExpr : Template := {data := LitD, arity := 0}
def AddExpr : Template := {data := AddD, arity := 2}
def MulExpr : Template := {data := MulD, arity := 2}
def PowExpr : Template := {data := PowD, arity := 2}
```


== Expression Instances
We can create an _instance_ of a template:

```lean
structure Template.instance (T : Template) where
  -- What should go here?
```

== Expression Instances
We can create an _instance_ of a template:

```lean
structure Template.instance (T : Template) where
  out : T.data × _
--- obviously, we need the "constant part" of the expression
```

== Expression Instances
We can create an _instance_ of a template:

```lean
structure Template.instance (T : Template) where
  out : T.data × (Fin T.arity -> ?)
-- And something to put in each hole
```
== Expression Instances
Given a template, we can create a real instance of that expression:
```lean
structure Template.instance (T : Template) (E : Type) where
  out : T.data × (Fin T.arity -> E)
-- we reuse the "E" trick for the child type
```
Think "A `T`-template with the holes filled with `E`s"

== example:

```lean
inductive LitD where | val : Nat -> LitD

def LitExpr : Template := {data := LitD, arity := 0}

def lit1 : LitExpr.instance () -- literal with value 1
  := ⟨.val 1 , fun x => nomatch x⟩
--                 ^ Fin 0 = an empty type
--                   no nat < 0
```


== So to reiterate:
- A template specifies a type of expression via:
  - The type of the _constant part_ (data)
  - Some _number of holes_ (arity)
- An _instance_ of a template is a pair:
  - The actual constant part
  - A way to fill in the holes (in the form of a function)

== Fixedpoints

- Now, we can also consider "What if the holes were filled with more expressions?"
- And we get the following construction:

```lean
structure Template.fix (T : Template) where
  out : T.data × (Fin T.arity -> (T.fix))
```
#pause

Intuivitely: "A T-template with the holes filled with more T-templates"

== Fixedpoints

- Now, we can also consider "What if the holes were filled with more expressions?"
- And we get the following construction:

```lean
structure Template.fix (T : Template) where
  out : T.data × (Fin T.arity -> (T.fix))
```

This definition is strictly positive!

$->$ This basic trick is what makes containers 'magic'


== What about glue?

We want to be able to define a sensible notion of _coproduct_ on templates
- Question for the audience - why on the template, not on the instance?
#pause
- Ans: To get our AST, we define a _template_ for an expression and then take a fixedpoint

How do we glue templates together?

== Template Coproduct

```lean
structure Template where
  data : Type
  arity : Nat

def Template.coprod (A B : Template) : Template := _
-- function : Template -> Template -> Template

```

== Template Coproduct

```lean
structure Template where
  data : Type
  arity : Nat

def Template.coprod (A B : Template) : Template := {
    data := _,
    arity := _,
  }

```

== Template Coproduct

```lean
structure Template where
  data : Type
  arity : Nat

def Template.coprod (A B : Template) : Template := {
    data := A.data ⊕ B.data, -- just use the normal coprod
    arity := _,
  }

```
#pause
- But the arity should depend on _which_ kind of expression it is
- A little tweak required

== Template Coproduct

```lean
structure Template where
  data : Type
  arity : data -> Nat -- arity now depends on the const data

def Template.coprod (A B : Template) : Template := {
    data := A.data ⊕ B.data,
    arity d := match d with -- just use the matching arity
      | .inl x => A.arity x
      | .inr x => B.arity x
  }
```

== This requires a litle tweak to the expressions:
```lean
def LitExpr : Template := {data := LitD, arity := fun _ => 0}
def AddExpr : Template := {data := AddD, arity := fun _ => 2}
def MulExpr : Template := {data := MulD, arity := fun _ => 2}
def PowExpr : Template := {data := PowD, arity := fun _ => 2}
```
- Note the function for arity
  - we just throw away the arg, since the arity of all these is constant

== And to instance and fix:
```lean
structure Template where
  data : Type
  arity : data -> Nat

structure Template.instance (T : Template) (E : Type) where
  out : Σ (x : T.data), (Fin (T.arity x) -> E)
```

== Why not just roll `Fin` into "arity"?
```lean
structure Template where
  data : Type
  arity : data -> Type

def LitExpr : Template
  := {data := LitD, arity := fun _ => Fin 0}

def Template.instance (T : Template) (E : Type) :=
  ∑ (x : T.data), (T.arity x -> E)
```

== Congratulations - you just invented containers:

```lean
structure Container where
  | shape : Type
  | pos   : shape -> Type

def Container.extension (C : Container) (E : Type) :=
  ∑ x : C.shape, (C.pos x -> E)

def Container.fix (C : Container) :=
  ∑ x : C.shape, (C.pos x -> T.fix)
```

== Anatomy of a container
- If you understood up til this point, then you have (in effect) understood containers
- A container is defined by just two things:
  - a type of _shapes_ (this is the constant data)
  - a function from shapes into a type, called the position function (this is the arity)

== Anatomy of a container
```lean
structure Container : Type where
  shape : Type
  pos   : shape -> Type
```
This is often written
$
  S triangle.l P
$

(Except in the first paper, where the triangle is reversed...)
== Putting things inside

The container object itself doesn't actually _contain_ anything yet.
//
For that, we need to take the _extension_ of the container:
$
  [| S triangle.l P |] : "Type" -> "Type"
$

#alternatives[This is just like an _instance_ of the _templates_ from earlier.][
  - The extension is a function that takes a type to a type.
  - The input is the type of _elements_ inside the container.
    - It's `E` (the child type) from earlier
    - "What do you want to put inside?"
]

== Putting things inside

It's defined like this:
$
  [| S triangle.r P |] E := Sigma" "s : S, (P s -> E)
$

#pause
- The first element of the pair is a _shape_
  - i.e. constant data #pause
- The second element is a function from the positions of the shape into the values
  - i.e. for each hole, something to put inside

== An example: Lists

```lean
def list : Container := {
    shape := Nat, pos := fun n => Fin n
}
```
How do we interpret this?

- The _shape_ here is the _length_ of the list
- the position function takes a natural number to a Type
  - In this case, `Fin n`

== List continued

- Let's fill the list with Natural numbers:

```lean
def listEx : list.extension Nat
  := ⟨cast (by simp) 3, fun x => match x with
    | 0 => 1
    | 1 => 2
    | 2 => 4
  ⟩
```

This corresponds to the list `[1, 2, 4]`.

Question: What data type corresponds to the fixpoint of `list`?

#hidden[Answer: Rost trees with leaf=unit (i.e. \[\])]

= Squiggly Horrors

== Polynomial functors

- Extension $[|-|]$ is a functor
  - e.g. concretely, in the category of types and total functions
  - Extension takes types $(alpha : "Type")$ to types $([|S triangle.l P|]alpha : "Type")$
  - and functions $f : alpha -> beta$ to functions\
    $[|S triangle.l P|]f : [|S triangle.l P|] alpha -> [|S triangle.l P|]beta$
  - "Just map over the children"

- These functors are 'nice' (i.e. polynomial)

== Polynomial functors?

#alternatives[

  $
    [| S triangle.r P |] X := Sigma" "s : S, (P s -> X)
  $

  - $(A -> B)$ is a type
  - Sometimes called the "function space" of $A$ to $B$
  - The cardinality of this type is $B^A$
  - So sometimes we write $B^A$ for the function space
  - So we rewrite our expressions at the top to...
][
  $
    [| S triangle.r P |] X := Sigma" "s : S, X^(P s)
  $
  - Sigma types = sum over possible values in a type
  - function spaces = generalised exponents
  Sound familiar?
  $ ZZ[x] := sum_k alpha_k x^k $
  - All containers are polynomial functors; all polynomial functors are containers.
]

== Initial algebra

- We can always find the initial algebra for a polynomial functor
- This gives us a convenient, rigorous way to handle recursion
  - Containers are great ways of setting up inductive data types
  - Useful backbone for theorem proving
- Come back next week if you want to know what that means!


== Algebra

- Containers define a _signature_ for a singly-kinded algebra
  - Shapes with no holes are _constants_
  - Shapes with $n$ holes are $n$-ary operators
- Indexed containers can handle multi-kinded algebras
- Directed containers model coalgebras
- non-free algebras (i.e. algebras with axioms) can be handled by _quotient containers_

$->$ highly relevant to my work; come and chat if you want to know more

== In conclusion:

- Containers are extremely useful
  - Can model anything where there's a set of questions, and for each, a set of allowable
    responses
  - If you can phrase your data as a container, it _will_ be OK in lean/agda/rocq
- They allow you to constructively model fixed points


#slide[
  #bibliography("refs.bib")
]


#slide[
  = Thanks for your attention!

  === Any questions?
]

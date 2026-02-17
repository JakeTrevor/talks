---
paginate: true
abstract: It seems that many technical problems can be reduced to installing a package. It's not surprising then that package managers are among the most ubiquitous software components in the world. Despite this, package management isn't quite a solved problem. Many buggy components of the worlds' software supply chain are slightly rubbish package managers - and they cost us precious time and peace of mind. In this talk, I will quantify how and why some package managers fail to do their job properly. To do this, I will discuss what it means, in a formal sense, for a package manager to be well behaved. We will use this formalisation to discuss why pip is beyond redemption (though it isn't really pip's fault), and on why Nix's versioning system has some issues.
---
<style>
section {
  font-family: 'FiraCode Nerd Font';
}

section::after {
  content: attr(data-marpit-pagination) '/' attr(data-marpit-pagination-total);
}

blockquote {
  color: #1e293b;
  background: rgb(209, 217, 224);
  padding: 5px;
  border-radius: 10px;
}

.bigimg > * {
  max-height: 40vh;
  max-width: 40vw;
}


.centered {
    display: flex;
    flex-direction: row;
    justify-content: center;
}

.light {
    color: 'gray';
}

.top {
    position: fixed;
    top: 20vh;
}

</style>

$$
\newcommand{\get}{\texttt{Get }}
\newcommand{\put}{\texttt{Put }}
\newcommand{\commit}{\texttt{Commit }}
\newcommand{\checkout}{\texttt{Checkout }}
\newcommand{\prop}{\text{Prop}}
\newcommand{\hist}[1]{H\text{<}#1\text{>}}
\newcommand{\grey}[1]{\textcolor{grey}{#1}}
\newcommand{\lens}[2]{\mathcal L\ #1\ #2}
$$

# Package Managers, through a lens or two

### Jake Trevor

---

## Disclaimers:

- Mot my main line of work
    - There are some holes
- Not a PL talk - just PL themed

---

## Package managers are Ubiquitous

How many can you think of?

---

## Package managers are Ubiquitous


Some are familiar:
- utilities from the system PM (apt, brew, yum...)
- language specific dependencies (cargo, npm, pip, etc.)

Some are a little more exotic:
- ready-made actions in your CI (github actions)
- docker images on GHCR
- games on your iPad's app store
- minecraft mods via a mod manager (other games available)
- music from spotify

---

## Hygiene factors

- Despite how ubiquitous PMs are, no one spends any time thinking about them

- ... because if you are thinking about your package manager, something has gone wrong

- A good package manager is a _hygiene factor_ - you notice it only by its absence

> No one notices a clean bathroom

##### Similarly, no one ever wants to think about `pip`

---

## What should you take out of this talk?

- How can we characterise good behaviour for package managers?
    - both informally
    - and formally
- One potential idea for how to formalise good behaviour
- Maybe some learning about lenses

---
## What is a package manager?

There are three characteristic problems package managers solve:

1. **Install** packages
2. Handle **dependencies**
3. (or perhaps, 2.a) Manage **versions**

Almost no one gets #1 wrong

But the rest is a lottery!

---

## What is a good package manager?

#### How should a well behaved package manager behave?

---

## Idea: Lenses

----

### Lenses

A lens $\mathcal L\ \Gamma\ \Delta$ is a structure on two types $\Gamma, \Delta$ 



$\Gamma$ is the _source_ type

$\Delta$ is the _target_ type - it's a _view_ on the source

---

## Lenses

A lens is just a pair of functions:

$$
\begin{align*}
\get&: \Gamma \to \Delta & 
\put&: \Delta \times \Gamma \to \Gamma
\end{align*}
$$


---
### Lens Laws:

A lens is _well behaved_ if it obeys the lens laws:


$$
\begin{gather*}
&\forall\ \left(i : \Gamma\right)\ \left(x: \Delta\right), \\
\text{put-get} &&
\text{get-put} \\
\get (\put x\ i) = x &&
\put (\get i)\ i = i
\end{gather*}
$$

---
### Lens Laws:

A lens is _very well behaved_ if it is also idempotent:

$$
\begin{gather*}
\text{put-put}\\
\put x\ (\put x\ i) =\ \put x\ i
\end{gather*}
$$

---

### Lenses?

Morally, this seems like it might be a good model...

- We have some notion of a source type $\left(\Gamma\right)$ (the remote package repository)
- We want a _view_ on that source type $\left(\Delta\right)$ (our local installation of packages)

but the devil is in the details

---
## Package lenses:

Let's say that we have: 
- a type $P$ of package names
- and for each package $p : P$, a body of type $B$

A package manager is then a collection of lenses

---
## Package lenses:

The source type is a map of names to bodies:


$$\Gamma = P \to B$$

For each subset of package names $P' \subseteq P$, we have a target type, which is a map from names to bodies:

$$\Delta_{P'} = P' \to B$$

---

## Can we mechanise this?

---
## Package lenses:

In lean, we define subsets by their _characteristic predicate:_

> e.g. $hP'$ = is $p$ in the subset $P' \subseteq P$?

```lean4
-- given h : P -> Prop

type P' = { p : P // h p }

type P' = Subtype h
```

---

The _package manager_ itself can be understood as a function from the choice of packages to the corresponding lens:

$$\text{PLens} : (hP' : P \to \text{Prop}) \to \mathcal L\ \Gamma\ \Delta_{P'}$$


---
## Package lenses:

In this formalism, since $P' <: P$, $\Gamma <: \Delta_{P'}$

So $\get$is just a cast from $\Gamma$ to $\Delta_{P'}$

```lean4
get : (P -> Prop) -> (Subtype h -> Prop)
get := fun γ p => γ p
```

<!-- We "mask off" the parts of $\gamma$ that we don't want to see in our $\delta$ -->

---
## Package lenses:

$\put$_overwrites_ $\Gamma_P$ with values from $\Delta_{P'}$ whenever they exist:

```lean4
put : ((Subtype h -> Prop) × (P -> Prop)) -> (P -> Prop)
put := fun (δ, γ) p =>
    if h p
    then δ p 
    else γ p
```

<!-- We _overlay_ our $\delta$ onto our $\gamma$. -->

---

## Package lenses

- Models the intuitive behaviour of installing packages
- All the lenses are _very well behaved_
-> I have lean proofs to back this up

---
## Dependencies

<!-- The challenges of dependency management:
- Avoid dependency war (whenever possible)
- Model _cyclical dependencies_ -->

---
## The Problem: Dependency war

- Let's say that I use package $\text{B}$
* and $\text{B}$ depends on $\text{A}$ version 1
* Let's say I also want to use $\text{C}$
* which depends on $\text{A}$ version 2

* Some combinations of packages are _impossible_  
* How should a well behaved package manager deal with this?

---
## Dependency war

![](../out/package-manager/diagram.png)

---
## Dependencies: Internal

- Sometimes, a package _completely encapsulates_ its dependencies
    - e.g. if there's no way to tell that A depends on B from the A's interface alone
- In this case, the dependencies are **internal** to the package

-> We can use the package without knowing about its dependencies

---
## Dependencies: External

> Packages can be _leaky_

- What if types from a dependency appear in the public interface of the package?
- Then the user of the package is _exposed_ to the dependencies
- These are called **external** dependencies

---
## To be clear:

- External dependencies make solving dependency war very hard
#### My view:

- Dependency war between external dependencies in packages is _not_ a technical problem
- It's fundamental to the implementation of the packages

> Some sets of packages are _incompatible_
> Nothing a package manager can do will solve this

---
## Aside: Can we fix it?

If you allow importing multiple versions of the same package, e.g. by naming them differently...

then you can expose both interfaces without a namespace collision


> but doing so is contrary to the _spirit_ of versioning

-> Versions provide different ways of doing the same thing
$\therefore$ it's weird to use two versions of the same thing

<!-- If two versions of a package are truly different, why are they not separate packages? -->
<!-- Some preliminary work in this vein exists; see Florisson & Mycroft -->

---

**However**, dependency war between internal dependencies should not be an issue

#### Solution: Dependency Locality

---

## Local Dependencies:

The key idea is that we can load dependencies in a _localised_ way:

1. When we load a dependency, it must not have side effects on some global environment

2. To support this, packages need to support _dependency injection_


---

Python does not have this facility; packages are referred to by name, as objects existing on the path 

This is not a feature of the package manager, but of the underlying language/system

It's not pip's fault 

## Pip sucks because python sucks

---
## Module systems:

There's an extensive body of work on module systems, such as: 

- **MixML** for ML (Rossberg & Dreyer)
- **backpack** for haskell (Kilpatrick & al.)
- $\Pi$ - a language agnostic module calculus; unpublished (Florisson & Mycroft)

These are much more complicated than I have time to go into here, and also a little out of scope

---
## Versions

---
## Solution 1: new version, new name

- e.g. `pkg-A-v1` and `pkg-A-v2` are different packages
- This works very nicely with the theory we presented!
- It's also completely useless 
    - in that it fails to model the actual problem
- _Dependency war_ is just _namespace collision_
- If we really want to think about versions, we need to treat them as more than just 'new names'


---
## How should versions work?

- Versioning software is a solved problem
    -> Just do what git does!

- What are the semantics of git?

---
## VCS semantics

We have:
- $S$ - a type of the _items_ being versioned
- $\hist S$ - the type of histories
- $\text{Hash}$ - an associated type of _hashes_

---
## VCS semantics

We don't care about the content of the types
so long as we can define the following two functions:

$$
\begin{align*}
\commit &: \hist S \times \text{Hash} \times S \to \hist S \times \text{Hash}\\
\checkout &: \hist S \times \text{Hash} \to S\\
\end{align*}
$$

---
### VCS semantics

This might look familiar...

$$
\begin{gather*}
\Gamma = \hist S \times \text{Hash} &&
\Delta = S\\
\get = \checkout && \put = \commit
\end{gather*}
$$

---
## VCS semantics

There's an infinite family of version control lenses (VCLs), constructed by the function:
$$
\text{VCL} : (S : \text{Type}) \to  \mathcal L\ (\hist S\times \text{Hash})\ S
$$

---
## VCS: Is it a lens?

- If I checkout what I just committed, I should get the same thing back:
$$
\checkout (\commit x\ i) = x 
$$

- If I check something out, and try to commit it, nothing will happen

-> since Git will not (by default) allow empty commits
$$
\commit (\checkout i)\ i = i
$$

- By the same fact, committing the same thing twice does nothing
$$
\commit x\ (\commit x\ i) = \commit x\ i
$$


---

### So, in fact, this kind of abstract VCS is a lens, and it's _very well behaved!_

* Formalising this turned out to be hard
* I have a (very ugly) lean definition for VCLs
* But the proofs are not finished

---
## What do we want, morally? 

- Let's say that we have a _history of bodies_ for each package

- For a package $p : P$, let $V_p$ be the set of its versions 

-> i.e. hashes in its history

- Then for a set of packages $P'$, a _choice of versions_ $V_{P'}$ is an object with type
$$V_{P'} = (p : P') \to V_p$$

---
## What do we want, morally? 

Our source type should be a _map of histories_ of package bodies:

$$\Gamma = P \to \hist B$$

As before, for a choice of packages $P'$ versions $V_{P'}$, we have a target type - a map of names to bodies:

$$\Delta_{V_{P'}} = P' \to B$$


We want a family of lenses, constructed by a function:

$$
\text{mkPkgMan} = P'\times V_{P'} \to \mathcal L\ (P \to \hist B)\ (P' \to B)
$$

---

## What do we have?

We can construct a package lens from names to histories


$$\text{PLens ref} : \mathcal L\ (P \to \hist B)\ (\text{Subtype ref} \to \hist B)$$

We can construct a VCL on those histories:

$$\text{VCL } B: \mathcal L\ (\hist B\times \text{Hash})\ B$$


---
## Here are two other lenses:

$$
\begin{gather*}
ID : \mathcal L\ A\ A \\\\
\text{Concentrate} : \mathcal L\ \left((B \to C) \times (B \to D)\right)\ (B \to (C \times D))

\end{gather*}
$$

These are both vwb. (proofs in lean)

We will need these later

---
## Constructions on lenses:

Lenses can be tensored (parallel composition):
$$\_ \otimes \_: \mathcal L\ A\ B \to \mathcal L\ C\ D \to \mathcal L\ (A \times C)\ (B \times D)$$

Composed (sequential composition):
$$\_ \circ \_ : \mathcal L\ A\ B \to \mathcal L\ B\ C \to \mathcal L\ A\ C$$

We can split a lens over a function in the second argument:

$$\_ \text{ split } \_ : \mathcal L\ A\ (B \to C) \to \mathcal L\ C\ D \to \mathcal L\ A\ (B \to D)$$

> These constructions are _behaviour preseving_ - their output is vwb. when the input lenses are.

---

## We can use these lenses and constructions to define a formalism for _versioned package lenses_

* This is a little complex, so we will go through it slowly
* It's OK if you don't follow this completely

---
## What we get: Versioned Package Lenses

$$
\text{VPL ref} : (P \to \prop) \to \mathcal L\ ((P \to \hist B) \times V_{P'})\ (P' \to B)
$$

---

$$
\text{VPL ref} = 
((\text{PLens ref} \otimes \text{ID})
    \circ \text{Concentrate})\
    \text{split}\ (\text{VCL }B)
$$

---

<div class="top">

$$
\text{VPL ref} = 
\grey{(}(\text{PLens ref} \otimes \text{ID})
    \grey{\circ \text{Concentrate})\
    \text{split}\ (\text{VCL }B)}
$$

</div>

$$ 
(\text{PLens ref} \otimes \text{ID}) : \lens{((P \to \hist B)\times V_{P'})\ \ \ }{((P' \to \hist B)\times V_{P'})}
$$

---

<div class='top'>

$$
\text{VPL ref} = 
((\text{PLens ref} \otimes \text{ID})
    \circ \text{Concentrate})\
    \grey{\text{split}\ (\text{VCL }B)}
$$

</div>

Recall that $V_{P'}$ is just $(p:P') \to V_p$

$$ 
\begin{align*}
    &(\text{PLens ref} \otimes \text{ID}) \circ \text{Concentrate} \\
    &: \lens{((P \to \hist B)\times V_{P'})\ \ \ }{(P' \to (\hist B \times V_p))}
\end{align*}
$$


---

<div class='top'>

$$
\text{VPL ref} = 
((\text{PLens ref} \otimes \text{ID})
    \circ \text{Concentrate})\
    \text{split}\ (\text{VCL }B)
$$

</div>

$\hist B \times V_p$ is exactly the source type of our version control lens

$$ 
\begin{align*}
    &((\text{PLens ref} \otimes \text{ID})
    \circ \text{Concentrate})\
    \text{split}\ (\text{VCL }B)\\
    &: \lens{((P \to \hist B)\times V_{P'})\ \ \ }{(P' \to B)}
\end{align*}
$$

---
## What we get: Versioned Package Lenses

$$
\begin{align*}
    \text{VPL ref} 
    &= ((\text{PLens ref} \otimes \text{ID}) \circ \text{Concentrate}) \text{split}\ (\text{VCL }B)\\
    & : (P \to \prop) \to \mathcal L\ ((P \to \hist B) \times V_{P'})\ (P' \to B)
\end{align*}
$$

Since this is formed only by vwb. lenses and behaviour preserving constructions, the result is also vwb.

---
## If you didn't follow, the key take away is:

---
## What we get isn't quite what we wanted

$$
\mathcal L\ ((P \to \hist B) \times V_{P'})\ (P' \to B)
$$

The target type is correct

$$\Delta = (P' \to B)$$

but the source type is a little different:

$$
\begin{gather*}
\text{Wanted:} && \text{Got:}\\
\Gamma = P \to \hist B && \Gamma = (P \to \hist B) \times V_{P'}
\end{gather*}
$$

---
## The difference

The source type includes our choice of versions $V_{P'}$

Intuitively: $\put$can change our choice of versions

- From a certain point of view, this makes sense
    - The version you just pushed is not the one you checked out

- From another, it does not:
    - If versions can change with a push, why not the set of packages?
    - i.e. what's the story for 'pushing a new package'?

---

It may well be that a different approach might yield a more pleasing result

wherein versions are names are treated more similarly

Food for thought

---
## The wrinkles

- Since the formalisation of VCL is not done, I don't have a verified proof that this is all OK just yet
- At present, while 'tensoring' is morally right, it's not sufficient
- The type of Hashes depends on the value of history, so
- We need a dependent tensor - where the second argument can depend on the first

---
## Take care!

Notice that for us, the package registry is a _map of histories_:

$$P \to \hist B$$

But Nix instead has a _history of maps_:

$$\hist {P \to B}$$

nixpkgs (the central repository) is a versioned map of names to recipes

> Which is the right way around?

---

## My view: Nix does it wrong

With Nix' system, we refer to packages in a particular version of nixpkgs 
<!-- (a big git repository that acts as Nix's remote repository) -->

**Problem 1**: bumping a version might not change your installation at all
    -> i.e. if the packages were not changed in that commit

**Problem 2**: Versioned versions

---

## Versioned Versions

Nix allows you to refer to different nixpkgs versions
to allow you to refer to specific builds of a given package

But this can be cumbersome 

$\therefore$ different versions of a package are often distributed as _different packages_

> e.g. php82 and php83 are different packages.

php82 might exist in 2 commits

You can refer to _different versions of php82_

-> Ridiculous

---
### Conclusions

- We can model package managers with lenses
    - Lots of the nuance is nicely captured
- Particularly, simple unversioned package managers
- For good dependency behaviour, the underlying system needs a good module system
    - Even if we get everything else right, we can still get trapped by non-local dependencies
- This formalism has some weaknesses, space for development
    - A more equal treatment of versions and package names would be nice

---
## Future work?

- What does proper behaviour for **shared dependencies** look like?
-> What's the next best thing after full locality?
-> What about version constraints?

- **Extra features**
    - e.g. declarative/imperative interfaces, reversibility and uninstallation
    -> some of this is already captured by the models I've already presented

- **Security**
    -> Push should fail sometimes - is that worth modelling?

---
Some references:

[1] Florisson & Mycroft, _Towards a Theory of Packages_  _unpublished draft_ (2016)
[2] Rossberg & Dreyer, _Mixin’ Up the ML Module System_ (2013)
[3] Kilpatrick & al, _Backpack: Retrofitting Haskell with Interfaces_ (2014)

----


## Over cakes:

What's your most hated package manager?

Can you think of bad behaviour that isn't captured by this model?
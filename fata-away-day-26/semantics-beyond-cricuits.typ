#import "@preview/touying:0.7.2": *
#import themes.university: *
#show: university-theme.with(aspect-ratio: "16-9")

#import "@preview/quill:0.7.2": *
#import "@preview/subpar:0.2.2"

#let tq = tequila
#let ket = x => $|#x chevron.r$

#show raw: set text(size: 10pt)
#show figure.caption: set text(size: 15pt)
#set par(justify: true)

= Semantics beyond Circuits


== Quantum Circuits

Quantum circuits blocks of straight-line code

== Example

#subpar.grid(
  columns: (1fr, 1fr),
  align: center + horizon,
  figure(
    ```rust
    fn bellPair() {
      let a, b = new Qubit()
      H a
      CX a b
      return (a, b)
    }

    fn teleport(q) {
      let a, b = bellPair()
      CX q a
      H q

      let qres = measRec q
      let ares = measRec a

      if (ares) { X b}
      if (qres) { Z b }

      return b
    }
    ```,
    caption: [Code],
  ),
  figure(
    quantum-circuit(
      lstick(ket(math.psi)),
      1,
      1,
      ctrl(1),
      $H$,
      1,
      meter(target: 2),
      [\ ],
      lstick(ket(0)),
      $H$,
      ctrl(1),
      targ(),
      1,
      meter(target: 1),
      [\ ],
      lstick(ket(0)),
      1,
      targ(),
      1,
      1,
      $X$,
      $Z$,
      1,
      rstick(ket(math.psi)),
      gategroup(
        2,
        2,
        x: 1,
        y: 1,
        label: (content: [Create Bell pair], pos: bottom),
        stroke: (dash: "dotted"),
      ),
    ),
    caption: [Circuit],
  ),

  caption: [Quantum teleportation, 2 ways],
)

== Quantum Circuits

Circuits are foundational in QC, but not terribly expressive

#pause
$->$ straight-line code

#pause
$->$ No loops

#pause
$->$ Not turing complete

== hierarchies
Classical computing observes an _expressiveness hierarchy_ based on the level of control
flow offered:


#figure(
  image("../out/cfe-in-qc/classical-lattice.png", height: 50%),
  caption: [Classical CF Lattice],
)

== hierarchies

There is an analogous hierarchy in QC, though it looks more complicated

#figure(
  image("../out/cfe-in-qc/quantum-lattice.png", height: 70%),
  caption: [CF Lattice for QC],
)


= Why the complication?

== Measurement
We tend to assume QC follow the _co-processor architecture_

#figure(
  image("../out/cfe-in-qc/co-processor-architecture.png", height: 40%),
  caption: [Co-processor Architecture],
)
#pause
- _QPU_ is a quantum computer
#pause
- _scheduler_ is just a classical computer that tells the QPU what to do

== Measurement
Adding measurement adds a backwards edge to this graph:

#figure(
  image("../out/cfe-in-qc/co-processor-dyn-lift.png", height: 40%),
  caption: [Co-processor Architecture with Dynamic Lifting],
)

#pause
- Passing results back from the QPU to the scheduler is called _dynamic lifting_
#pause
- And generally, it's considered expensive

== What I'm working on

#grid(
  columns: (1fr, 1fr),
  [
    Circuits represent $Q C$ and below
    #pause

    Semantics of circuits well understood

    But higher levels of control flow are more complicated
  ],

  [
    #meanwhile
    #grid.cell(
      figure(
        image("../out/cfe-in-qc/quantum-lattice.png", width: 85%),
        caption: [CF Lattice for QC],
      ),
      align: horizon,
    )],
)

== What I'm working on

#grid(
  columns: (1fr, 1fr),
  [

    The big idea:
    - A family of languages
    #pause
    - One for each level in this Lattice
    #pause
    - Related by simple addition of syntactic features

    #pause

    $->$ give a semantics to each, and we have a nice framework for studying
    - languages
    - algorithms
    - hardware
  ],
  [
    #meanwhile
    #grid.cell(
      stack(
        only((1, 2))[#figure(
            image("../out/cfe-in-qc/reduced-quantum-lattice.png", width: 85%),
            caption: [(Reduced) CF Lattice for QC],
          )
        ],
        only((3, 4))[#figure(
            image("../out/cfe-in-qc/labelled-reduced-quantum-lattice.png", width: 90%),
            caption: [(Reduced) CF Lattice for QC \ with syntactic feature labels],
          )
        ],
      ),
      align: horizon,
    )
  ],
)

== Where are we now?

SQIR is a mechanically (i.e. in ROQC) specified quantum intermediate language

Part of the larger VOQC project (verified optimisation)

Could be a good jumping off point for this work...

I'll either:
- extend SQIR
- or start from scratch (if so, probably in lean)
  - for higher levels in the lattice, this might be easier, since SQIR has no handling for
    classical data

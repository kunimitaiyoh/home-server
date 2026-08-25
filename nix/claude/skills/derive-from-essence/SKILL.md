---
name: derive-from-essence
description: "Reference knowledge for choosing how to encode, structure, or name state: derive the form from the essence — the representation-independent requirement, the abstract state space — rather than from the form already in hand (the current encoding, a lowered value, an existing name, the smallest edit). Use when a feature adds or changes a mode/variant/case/dimension of state; when deciding or reshaping how state is modeled (enum, discriminated union, struct, flags, state machine, persisted shape); when tempted to patch the current encoding or alias a type name to minimize edit distance; or when reviewing for data valid in only one variant, illegal/junk states, or a discriminant paired with an always-present companion field."
user-invocable: false
disable-model-invocation: false
---

# Derive From Essence

How a thing is encoded, structured, or named should be derived from its **essence** — the representation-independent requirement, the abstract state space an outside observer of the spec would describe — not from the **form already in hand**: the current encoding, a value already lowered to some other shape, an existing name, or the smallest edit from where the code sits now.

The form in hand exerts a pull — it is cheaper to patch than to rederive. Letting that pull decide is **path-dependence**, and it is how clean models quietly rot.

## Essence vs form

- **Essence** (Brooks's *essential*, against *accidental*) is what the requirement inherently is — the objective variations a feature must support, independent of encoding. **Form** is any particular encoding of it.
- In data-abstraction terms: the essence is the **abstract value**; an encoding is a **concrete representation** mapped to it by an abstraction function.
- Two forms that denote the same essence are *essentially the same* state — but they are **not equally good**. Choosing among them is the real work.

## The criterion: representable ≈ reachable

A form is faithful when the set of values it **can represent** is close to the set of states actually **reachable**. Minimize two gaps:

- **junk** — representable values that are not real states (illegal states the type permits)
- **redundancy** — several encodings of one real state (which can drift out of agreement)

The faithful form is the one with the least junk and redundancy. This is the operational meaning of "ideal".

## A sum stays a sum

The essence is often a **sum** (a coproduct): a tagged set of variations, some carrying data.

```
{ day, week, month }  ⊕  ( days × dayCount )
```

The faithful form is the **isomorphic discriminated union**. The canonical failure is encoding the sum as a **product** — a tag plus an always-present companion field:

```ts
// Unfaithful: a sum encoded as a product.
class CalendarState {
  range: "day" | "week" | "month" | "days";
  dayCount: number; // read only when range === "days"
}
```

The companion opens both gaps. When `range !== "days"` the count is inert, so `("week", 5)` and `("week", 7)` are **redundant** encodings of one "week"; when `range === "days"` nothing holds the count to its valid band, so `("days", 0)` is **junk** — no real state. Either way an **unenforced invariant** — "`dayCount` is read only when `range === "days"`" — stands in for what the type fails to say, and every reader must carry it.

```ts
// Faithful: each variant carries exactly its own data.
type CalendarRange =
  | { kind: "day" }
  | { kind: "week" }
  | { kind: "month" }
  | { kind: "days"; count: number };
```

Now "week" has one encoding, and a count lives only where it is read. Representable ≈ reachable; the lone residual — a `days` count outside its band — is the kind of gap a type alone cannot close.

## Detection signature

The unfaithful form has a recognizable shape. Suspect it when several co-occur:

- a field sits beside a discriminant (`kind` / `type` / `mode` / an enum / a status)
- it is read in **exactly one arm** of a `switch`/`if` on that discriminant
- it is threaded through constructors, props, or update methods even where the discriminant rules it out
- a default or magic value is assigned where the field is inert (`count = 7` while `range === "month"`)
- the tag→value resolution that consumes it is **duplicated** in more than one place

It is not only runtime data; the same move hits **type identity and naming**. Below, the new union is named, but the name that meant the whole concept is kept as an alias for just the tag, so call sites need not move:

```ts
// Path-dependent: "Range" silently demoted to mean only the tag.
type CalendarView  = { kind: "week" } | { kind: "days"; count: number };
type CalendarRange = CalendarView["kind"];            // now just "week" | "days"

// From essence: the concept keeps its name; the tag is a derived alias.
type CalendarRange     = { kind: "week" } | { kind: "days"; count: number };
type CalendarRangeKind = CalendarRange["kind"];
```

## Path-independence (the discipline when the essence changes)

When a feature **changes the essence** — adds a variation, a dimension, a parameterized arm — re-derive the form from the abstract space, not by the smallest edit from the current encoding.

Judge the change at the **requirements** level, blind to any internal model: "the calendar can now show N chosen days" is objectively a new variation, whatever the smallest diff to the current enum would be. That is what stops "well, *days* is just a parameter" from rationalizing a patch.

The test:

> Would I choose this form writing from scratch, knowing only the requirements and this codebase's conventions?

If edit-distance-from-the-current-form is steering the choice, that is the contamination.

## Why it recurs

Knowing the better form does not prevent the worse one, because the cost gradient points the wrong way. The patch is cheap now and paid for later — by every reader who carries the unenforced invariant, every site that re-derives what the type could have stated. Greedy local optimization stops at the cheap patch. It is most damaging as a **regression**: degrading a previously clean model precisely because the cheap path avoided reshaping it.

The pull operates on data fields, on names, on defaults, and on how you organize your own work — watch for it anywhere a decision could be anchored to the form in front of you instead of the thing being modeled.

## Judgment: smell vs benign

Additive fields are not wrong by default. One test:

> Does the field introduce a conditional-validity invariant — "valid only when tag === X" — that the type does not enforce?

- **Yes** → unfaithful; move it into the variant.
- **No** (independently valid in every state) → an ordinary field; leave it.

### Remembered preference

A value may legitimately outlive the variant that uses it — a count persisted so it is restored next session, or shown as the last choice. That does not justify hoisting it into the active state. **Separate two concepts**: the *active state* (a discriminated union) and a *remembered preference* (a distinct, named, often-persisted value). Whether the essence even *includes* a remembered preference is a **specification** question — settle it there, not by leaving a flat field in the active type.

## Honest line-drawing

- Independent of *this form's current encoding* — **not** of the codebase's conventions. The ideal is the tightest faithful form *within the existing design language*; a locally "perfect" choice that ignores how the codebase already models its unions (e.g. its discriminant field name) is its own defect.
- *Determining* the ideal is always worth doing; *adopting* it fully now is a separate cost/risk call. A staged migration that keeps the ideal form internally and converts at the edge is legitimate — make it a deliberate, noted decision, not a default.
- "Ideal" means the tightest **faithful** form of the **actual** (already-real) state space — not the most general or flexible. Representing states that now exist is not speculative generality; it is compatible with YAGNI.
- Practical floor: when the type system cannot express the tightest form (e.g. an integer restricted to a range), enforce the residual invariant at a single point rather than spreading it.

## Preferred fixes

- model the tag and its data as a discriminated union; put each case's data inside the case
- if a value must outlive its variant, model it as a separate, named remembered preference
- resolve a derived quantity once and pass the resolved value to consumers that only need it, instead of threading the raw conditional field plus a duplicated resolver
- reference a named constant for a default rather than repeating a magic number in a state where the field is inert
- in languages without sum types, enforce the invariant at one construction/guard point and document it

## Non-problems

Do not flag:

- a change that does not alter the essence — a genuinely new *value* within an unchanged structure
- a field independently valid in all states
- a deliberately denormalized cache or derived field with one owner and a clear sync point
- a remembered preference already modeled as separate from active state
- a documented, deliberate staged migration
- a provisional variant that may be removed soon, with the invariant noted

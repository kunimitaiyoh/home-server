---
name: semantic-boundary
description: "Reference knowledge for preserving semantic boundaries in code: keeping external, persisted, serialized, display, formatted, fallback-applied, and internal domain/application representations distinct and explicitly converted. Use when writing, refactoring, or reviewing code that reads from APIs, Firestore, LocalStorage, files, environment variables, URL params, forms, or other external sources; or code that formats, serializes, renders, builds URLs/paths/labels, applies fallback values, or later uses those representations in conditions or business logic."
user-invocable: false
disable-model-invocation: false
---

# Semantic Boundary

Semantic Boundary is a design principle for keeping values in the correct semantic phase as they move between external, persisted, serialized, display, formatted, fallback-applied, and internal domain/application representations.

A semantic boundary is a point where the meaning, trust level, responsibility, or intended use of a value changes. Code should make these boundaries explicit through parsing, normalization, mapping, naming, types, modules, or conversion functions.

Semantic Boundary Confusion is a violation of this principle: values cross semantic boundaries inconsistently, causing unnecessary reinterpretation, repeated validation, duplicated meaning, or accidental coupling between layers.

This is not merely stringly typing, primitive obsession, sentinel values, magic strings, or leaky abstractions. Those are common symptoms. The core issue is losing track of which semantic phase a value is in.

## Principle

Interpret values at the boundary where their semantics change.

- External values should be parsed or normalized before becoming internal application state.
- Persisted values should not leak broadly as domain/application models.
- Display, formatted, serialized, fallback-applied, and output values should not be used to infer domain/application state when the pre-conversion value is available.
- Types, names, modules, and conversion functions should make semantic phases explicit.

## Common phases

Examples of semantic phases:

- raw external input
- parsed input
- normalized value
- persisted document
- domain/application model
- view model
- display value
- fallback-applied value
- serialized value
- log/output value

A value crossing one of these boundaries should usually be converted once and then treated according to its new phase.

## Input-side boundary failure

Input-side boundary failure occurs when external or persisted values are used directly across application code without boundary parsing or normalization.

High-risk sources include Firestore `snapshot.data()`, LocalStorage `getItem`, API responses, URL params, form values, files, environment variables, and JSON parsed from unknown sources.

Problematic:

```ts
const user = snapshot.data();

if (typeof user.name === "string" && user.name.trim() !== "") {
  renderUserName(user.name);
}
```

Preferred:

```ts
const user = parseUserDocument(snapshot.data());

renderUserName(user.name);
```

Problematic:

```ts
const settings = JSON.parse(localStorage.getItem("settings") ?? "{}");

if (settings.theme === "dark") {
  enableDarkMode();
}
```

Preferred:

```ts
const settings = parseStoredSettings(localStorage.getItem("settings"));

if (settings.theme === "dark") {
  enableDarkMode();
}
```

The goal is not to wrap every primitive value. The goal is to prevent raw, uncertain, or storage-shaped representations from leaking into broad application code.

## Output-side boundary failure

Output-side boundary failure occurs when code lowers a meaningful value into a display, serialized, formatted, fallback-applied, or output representation, then later inspects that lowered value to recover domain/application meaning.

Problematic:

```ts
const displayPhotoURL = user.photoURL ?? "/images/default.png";

if (!displayPhotoURL.endsWith("default.png")) {
  showRemovePhotoButton();
}
```

Preferred:

```ts
const hasCustomPhoto = user.photoURL != null && user.photoURL.trim() !== "";

const displayPhotoURL = hasCustomPhoto
  ? user.photoURL
  : "/images/default.png";

if (hasCustomPhoto) {
  showRemovePhotoButton();
}
```

A stronger model may preserve the semantic state explicitly:

```ts
type UserPhoto =
  | { kind: "custom"; url: string }
  | { kind: "none" };
```

Then domain/application decisions can use `kind`, while display code can separately choose a fallback URL.

## Recognition cues

Check the semantic boundary when code:

- repeatedly validates or normalizes the same raw value in multiple places
- uses Firestore documents, parsed JSON, LocalStorage values, API responses, URL params, or form values directly in application logic
- uses display, formatted, serialized, fallback, URL, path, label, log, or command values in domain/application conditions
- uses `includes`, `startsWith`, `endsWith`, `split`, regex, or string equality to recover business meaning
- would change behavior if a display label, fallback filename, URL shape, date format, or log format changed

These cues are not automatically wrong. They indicate that the boundary should be checked.

## Preferred fixes

Prefer the smallest structural fix that preserves the semantic boundary:

- move the decision before the transformation
- parse or normalize external values at the I/O boundary
- introduce a semantic type, parser, normalizer, repository, mapper, view model, or discriminated union
- preserve semantic state explicitly with a boolean, enum, `kind` field, or structured value
- separate domain/application decisions from presentation, persistence, transport, logging, and formatting
- rename values so their semantic phase is visible

Do not treat constant extraction as a complete fix if the boundary violation remains:

```ts
const DEFAULT_PHOTO_URL = "/images/default.png";

const hasCustomPhoto = !displayPhotoURL.endsWith(DEFAULT_PHOTO_URL);
```

This removes a magic string but still infers domain state from a display value.

## Non-problems

Do not flag code merely because it parses, formats, serializes, or validates data.

These are normal when they are the explicit responsibility of the code:

- parsing external input at an I/O boundary
- decoding Firestore, LocalStorage, API, file, URL, form, or environment values
- validating user input before creating an internal model
- formatting values for display
- serializing values for storage or transport
- testing exact output format
- compatibility code for legacy data or external protocols

The distinction:

- acceptable: interpreting an external or lowered representation at a clear boundary
- problematic: allowing that representation to leak inward, or using it later to reconstruct meaning that was already available

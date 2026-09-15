---
name: view-model-hook
user-invocable: false
description: "Reference knowledge for React view model hooks: component-specific custom hooks defined in the same file as their component, encapsulating internal state, render-value derivation, and event-handler implementation while exposing only JSX-facing values and UI actions. Use when writing, refactoring, or reviewing React components with component-specific state, derived render values, or event handlers."
---

# View Model Hook

## Definition

A view model hook is a custom hook dedicated to a specific React component.

Its purpose is to remove implementation details that are not needed for reading the component's JSX.

A view model hook is not a reusable general-purpose hook.
It is a component-specific organization technique.

## Core principle

The component body should only know the values required for final rendering and the actions passed to UI elements.

The component body does not need to know:

- which internal state a rendered value depends on
- how a rendered value is derived
- which temporary variables are used to derive a rendered value
- which state an event handler reads
- which state an event handler updates
- how consistency between multiple states is maintained

Therefore, a component-specific view model hook encapsulates internal state, rendered-value derivation, and event-handler implementation.

It exposes only the values and actions required by JSX.

## Props

A view model hook may receive the target component's `props` as its argument.

`props` are the component's input. Internal state, rendered-value derivation, and event-handler implementation may depend on `props`.

```tsx
type OrderTotalPanelProps = {
  unitPrice: number;
  initialQuantity: number;
  couponDiscount: number;
};

function useViewModel(props: OrderTotalPanelProps) {
  // ...
}

export function OrderTotalPanel(props: OrderTotalPanelProps) {
  const { totalLabel, addItem, toggleCoupon } = useViewModel(props);

  return (
    // ...
  );
}
```

## Naming

Name the view model hook `useViewModel` by default.

Because the hook is private to the component file, its name does not need to include the component name.

```tsx
function useViewModel(props: OrderTotalPanelProps) {
  // ...
}
```

## Example

Before:

```tsx
import { useCallback, useMemo, useState } from "react";

type OrderTotalPanelProps = {
  unitPrice: number;
  initialQuantity: number;
  couponDiscount: number;
};

export function OrderTotalPanel(props: OrderTotalPanelProps) {
  const [quantity, setQuantity] = useState(props.initialQuantity);
  const [hasCoupon, setHasCoupon] = useState(false);

  const totalLabel = useMemo(() => {
    const subtotal = quantity * props.unitPrice;
    const total = hasCoupon ? subtotal - props.couponDiscount : subtotal;

    return `${total.toLocaleString()}円`;
  }, [quantity, hasCoupon, props.unitPrice, props.couponDiscount]);

  const addItem = useCallback(() => {
    setQuantity((quantity) => quantity + 1);
  }, []);

  const toggleCoupon = useCallback(() => {
    setHasCoupon((hasCoupon) => !hasCoupon);
  }, []);

  return (
    <section>
      <p>合計: {totalLabel}</p>

      <button type="button" onClick={addItem}>
        商品を追加
      </button>

      <button type="button" onClick={toggleCoupon}>
        クーポンを切り替え
      </button>
    </section>
  );
}
```

After:

```tsx
import { useCallback, useMemo, useState } from "react";

type OrderTotalPanelProps = {
  unitPrice: number;
  initialQuantity: number;
  couponDiscount: number;
};

function useViewModel(props: OrderTotalPanelProps) {
  const [quantity, setQuantity] = useState(props.initialQuantity);
  const [hasCoupon, setHasCoupon] = useState(false);

  const totalLabel = useMemo(() => {
    const subtotal = quantity * props.unitPrice;
    const total = hasCoupon ? subtotal - props.couponDiscount : subtotal;

    return `${total.toLocaleString()}円`;
  }, [quantity, hasCoupon, props.unitPrice, props.couponDiscount]);

  const addItem = useCallback(() => {
    setQuantity((quantity) => quantity + 1);
  }, []);

  const toggleCoupon = useCallback(() => {
    setHasCoupon((hasCoupon) => !hasCoupon);
  }, []);

  return {
    totalLabel,
    addItem,
    toggleCoupon,
  };
}

export function OrderTotalPanel(props: OrderTotalPanelProps) {
  const { totalLabel, addItem, toggleCoupon } = useViewModel(props);

  return (
    <section>
      <p>合計: {totalLabel}</p>

      <button type="button" onClick={addItem}>
        商品を追加
      </button>

      <button type="button" onClick={toggleCoupon}>
        クーポンを切り替え
      </button>
    </section>
  );
}
```

In this example, `OrderTotalPanel` does not know `quantity`, `hasCoupon`, `setQuantity`, `setHasCoupon`, `subtotal`, or `total`.

It also does not know how `totalLabel` is derived or how `addItem` and `toggleCoupon` are implemented.

The component body only knows `totalLabel` for rendering and `addItem` / `toggleCoupon` as UI actions.

## Return value

A view model hook returns only the values and actions required by JSX.

Return values may include:

- display values
- display labels
- visibility flags
- disabled conditions
- UI state such as selected or checked values
- event handlers called from JSX
- values equivalent to props passed to child components

Do not return:

- internal state not directly needed by JSX
- `setState`
- temporary values used during derivation
- values needed only to implement event handlers

Bad:

```tsx
return {
  quantity,
  setQuantity,
  hasCoupon,
  setHasCoupon,
  totalLabel,
};
```

Good:

```tsx
return {
  totalLabel,
  addItem,
  toggleCoupon,
};
```

## Destructuring

The component should usually destructure the values and actions returned by the view model hook.

```tsx
const { totalLabel, addItem, toggleCoupon } = useViewModel(props);
```

The destructured values should still be only JSX-facing values and UI actions, not internal state or implementation details.

## Type definitions

Do not define an explicit `ViewModel` type for the return value by default.

A view model hook is dedicated to its target component and is tightly coupled to it. Its return type usually does not need to be stabilized as an external API.

Let TypeScript infer the return type from `return { ... }`.

Consider an explicit type only when:

- the return type must be referenced from multiple places
- a mock view model must be constructed explicitly
- the hook is no longer component-specific
- the inferred type becomes too complex to read
- the return value is intentionally stabilized as a public API

## useMemo and useCallback

A view model hook does not imply that `useMemo` or `useCallback` must be used.

The important point is to hide rendered-value derivation and event-handler implementation from the component body.

Use a plain `const` when the calculation is simple.
Avoid `useCallback` when referential stability is not needed.

## Location

Define the view model hook in the same file as the target component.

It is not a reusable hook.
It is a component-specific organization technique.

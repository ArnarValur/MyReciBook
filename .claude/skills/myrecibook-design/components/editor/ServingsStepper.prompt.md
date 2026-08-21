Editor servings stepper — stadium pill with −/+ around "1 serving" / "4 servings"; the word is rendered, never typed. Replaces free-text servings pills in manual entry and import review.

```jsx
<ServingsStepper value={n} onChange={setN} />
```

40px tall, hairline border, 32px round step targets (primary icons, 40%-muted at the clamp). Needs bounded width — put it in a flex cell.

Editor duration pill — schedule icon, number field, min/hr toggle chips ("min" is a control, never typed). Emits total minutes; comma decimals accepted ("1,5" hr → 90, Norwegian keyboards).

```jsx
<DurationField initialMinutes={25} onChanged={setTotalMin} />
```

40px pill, hairline border; unit chips are tiny stadium segments (secondary-container when selected). Display form elsewhere is "25 min" / "2 hr" / "1 hr 30 min" — exactly what MetaChips show. Needs bounded width.

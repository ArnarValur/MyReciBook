/* @ds-bundle: {"format":4,"namespace":"MyReciBookDesignSystem_4222aa","components":[{"name":"LogoMark","sourcePath":"components/brand/LogoMark.jsx"},{"name":"IngredientRow","sourcePath":"components/data-display/IngredientRow.jsx"},{"name":"MetaChip","sourcePath":"components/data-display/MetaChip.jsx"},{"name":"ProductRow","sourcePath":"components/data-display/ProductRow.jsx"},{"name":"RecipeCard","sourcePath":"components/data-display/RecipeCard.jsx"},{"name":"COVER_GRADIENTS","sourcePath":"components/data-display/RecipeCover.jsx"},{"name":"RecipeCover","sourcePath":"components/data-display/RecipeCover.jsx"},{"name":"SectionLabel","sourcePath":"components/data-display/SectionLabel.jsx"},{"name":"StatusPill","sourcePath":"components/data-display/StatusPill.jsx"},{"name":"StripedPlaceholder","sourcePath":"components/data-display/StripedPlaceholder.jsx"},{"name":"CoverPickerField","sourcePath":"components/editor/CoverPickerField.jsx"},{"name":"DurationField","sourcePath":"components/editor/DurationField.jsx"},{"name":"ServingsStepper","sourcePath":"components/editor/ServingsStepper.jsx"},{"name":"ConfirmDialog","sourcePath":"components/feedback/ConfirmDialog.jsx"},{"name":"Snackbar","sourcePath":"components/feedback/Snackbar.jsx"},{"name":"Button","sourcePath":"components/forms/Button.jsx"},{"name":"CategoryChipRow","sourcePath":"components/forms/CategoryChipRow.jsx"},{"name":"FilterChip","sourcePath":"components/forms/FilterChip.jsx"},{"name":"SearchBar","sourcePath":"components/forms/SearchBar.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Icon","sourcePath":"components/icon/Icon.jsx"},{"name":"AppBackButton","sourcePath":"components/navigation/AppBackButton.jsx"},{"name":"GlassNavBar","sourcePath":"components/navigation/GlassNavBar.jsx"},{"name":"GradientFab","sourcePath":"components/navigation/GradientFab.jsx"},{"name":"DashedInfoCard","sourcePath":"components/surfaces/DashedInfoCard.jsx"},{"name":"GlassCircle","sourcePath":"components/surfaces/GlassCircle.jsx"},{"name":"GlassPill","sourcePath":"components/surfaces/GlassPill.jsx"},{"name":"TokenCard","sourcePath":"components/surfaces/TokenCard.jsx"}],"sourceHashes":{"components/brand/LogoMark.jsx":"2faaa72f0ea3","components/data-display/IngredientRow.jsx":"88ecfeed4fde","components/data-display/MetaChip.jsx":"3de0be503fc6","components/data-display/ProductRow.jsx":"ddc3375034ae","components/data-display/RecipeCard.jsx":"a44b27d05342","components/data-display/RecipeCover.jsx":"a54f90a746e4","components/data-display/SectionLabel.jsx":"842ffe21fa1f","components/data-display/StatusPill.jsx":"fb840d6ce382","components/data-display/StripedPlaceholder.jsx":"2039ce32a5d0","components/editor/CoverPickerField.jsx":"05f29772145f","components/editor/DurationField.jsx":"14823a97fdaf","components/editor/ServingsStepper.jsx":"0ad448cfce12","components/feedback/ConfirmDialog.jsx":"d6f81fbf7d87","components/feedback/Snackbar.jsx":"938f6549f9e7","components/forms/Button.jsx":"61ada727acf4","components/forms/CategoryChipRow.jsx":"c524200d5c10","components/forms/FilterChip.jsx":"09b7b15283ef","components/forms/SearchBar.jsx":"dde9e8331c33","components/forms/SegmentedControl.jsx":"9e7aa9d139ea","components/icon/Icon.jsx":"fc1f34b0d7f9","components/navigation/AppBackButton.jsx":"9b8f001a711c","components/navigation/GlassNavBar.jsx":"524bd5599d78","components/navigation/GradientFab.jsx":"6896e6e656ff","components/surfaces/DashedInfoCard.jsx":"0de748d78fc5","components/surfaces/GlassCircle.jsx":"874f95b2935f","components/surfaces/GlassPill.jsx":"033071e1e088","components/surfaces/TokenCard.jsx":"b226079ffb0d"},"inlinedExternals":[],"unexposedExports":[{"name":"coverSlot","sourcePath":"components/data-display/RecipeCover.jsx"},{"name":"qtyBold","sourcePath":"components/data-display/IngredientRow.jsx"}]} */

(() => {

const __ds_ns = (window.MyReciBookDesignSystem_4222aa = window.MyReciBookDesignSystem_4222aa || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/brand/LogoMark.jsx
try { (() => {
let _maskSeq = 0;

/**
 * The MyReciBook logo mark — drawn (not an image) so it tints with the
 * scheme and stays crisp at any size. Geometry is a 1:1 transcription of
 * the app's LogoMark painter (108-unit design space; the spine is knocked
 * OUT of the book via mask so the mark sits on any background).
 * It is the app icon, the Cookbook tab icon, and the cover watermark —
 * the three read as one mark.
 */
function LogoMark({
  size = 24,
  color = 'var(--primary)',
  withSteam = true,
  style = {}
}) {
  const [maskId] = React.useState(() => `rb-lm-${++_maskSeq}`);
  // Ink bounds in design space, stroke widths included (from the painter).
  const viewBox = withSteam ? '26 23 56 55' : '26 51 56 27';
  return /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: viewBox,
    preserveAspectRatio: "xMidYMid meet",
    "aria-hidden": "true",
    style: {
      display: 'block',
      flex: 'none',
      ...style
    }
  }, /*#__PURE__*/React.createElement("mask", {
    id: maskId
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "0",
    width: "108",
    height: "108",
    fill: "#fff"
  }), /*#__PURE__*/React.createElement("line", {
    x1: "54",
    y1: "62",
    x2: "54",
    y2: "76",
    stroke: "#000",
    strokeWidth: "2.5",
    strokeLinecap: "round"
  })), /*#__PURE__*/React.createElement("path", {
    d: "M54 60 C47 53 36 51 26 53 L26 72 C36 70 47 72 54 78 C61 72 72 70 82 72 L82 53 C72 51 61 53 54 60 Z",
    fill: color,
    mask: `url(#${maskId})`
  }), withSteam && [45, 63].map(x => /*#__PURE__*/React.createElement("path", {
    key: x,
    d: `M${x} 26 C${x - 5} 33 ${x + 5} 35 ${x} 42`,
    fill: "none",
    stroke: color,
    strokeWidth: "6",
    strokeLinecap: "round"
  })));
}
Object.assign(__ds_scope, { LogoMark });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/brand/LogoMark.jsx", error: String((e && e.message) || e) }); }

// components/data-display/RecipeCover.jsx
try { (() => {
/** The six cover pairs, in hash-table order — do not reorder. */
const COVER_GRADIENTS = [['#3F51B5', '#24389C'],
// indigo — the brand
['#4A5A8C', '#2C3557'],
// slate blue
['#8E3B62', '#5B2340'],
// plum
['#B4643C', '#7C3F24'],
// terracotta
['#2E6F6A', '#1B4744'],
// teal
['#5E7346', '#3B4A2B'] // olive
];

/** The app's stable title hash — NOT String.hashCode (must survive relaunches). */
function coverSlot(title) {
  let sum = 0;
  for (let i = 0; i < title.length; i++) sum = (sum + title.charCodeAt(i) * 31) % 1000003;
  return sum % COVER_GRADIENTS.length;
}

/**
 * A recipe's cover: the picked image when there is one, otherwise a drawn
 * 135° gradient chosen deterministically from the title, watermarked with
 * the LogoMark at 22% white. Screenshots are NOT promoted to covers —
 * the originals stay one tap away behind the hero's provenance flip.
 */
function RecipeCover({
  src,
  title = '',
  style = {}
}) {
  if (src) {
    return /*#__PURE__*/React.createElement("img", {
      src: src,
      alt: "",
      style: {
        width: '100%',
        height: '100%',
        objectFit: 'cover',
        display: 'block',
        ...style
      }
    });
  }
  const pair = COVER_GRADIENTS[coverSlot(title)];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      height: '100%',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: `linear-gradient(135deg, ${pair[0]}, ${pair[1]})`,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: '46%',
      maxWidth: '46%',
      aspectRatio: '1 / 1',
      opacity: 0.22
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.LogoMark, {
    size: "100%",
    color: "#ffffff"
  })));
}
Object.assign(__ds_scope, { COVER_GRADIENTS, coverSlot, RecipeCover });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/RecipeCover.jsx", error: String((e && e.message) || e) }); }

// components/data-display/RecipeCard.jsx
try { (() => {
/**
 * Cookbook grid card (2-col): 106px cover — the picked photo, else the
 * title-derived gradient tile with the LogoMark watermark (RecipeCover)
 * — 2-line title, meta line "25 min · Serves 4".
 */
function RecipeCard({
  title,
  meta,
  cover,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      background: 'var(--surface-container-lowest)',
      borderRadius: 'var(--radius-md)',
      border: '1px solid var(--hairline)',
      boxShadow: 'var(--elev-1)',
      overflow: 'hidden',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 106,
      background: 'var(--surface-container-low)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.RecipeCover, {
    src: cover,
    title: title
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '9px 11px 11px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--title-sm-size)',
      fontWeight: 'var(--weight-semibold)',
      lineHeight: 1.3,
      color: 'var(--on-surface)',
      display: '-webkit-box',
      WebkitLineClamp: 2,
      WebkitBoxOrient: 'vertical',
      overflow: 'hidden'
    }
  }, title), meta && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 3,
      fontFamily: 'var(--font-body)',
      fontSize: 11.5,
      color: 'var(--on-surface-variant)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, meta)));
}
Object.assign(__ds_scope, { RecipeCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/RecipeCard.jsx", error: String((e && e.message) || e) }); }

// components/data-display/SectionLabel.jsx
try { (() => {
/**
 * Tiny tracked uppercase section label — `INGREDIENTS · 8`.
 * 11px w600, +0.9px tracking, on-surface-variant.
 */
function SectionLabel({
  children,
  trailing,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-sm-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--label-sm-tracking)',
      textTransform: 'uppercase',
      color: 'var(--on-surface-variant)'
    }
  }, children), trailing);
}
Object.assign(__ds_scope, { SectionLabel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/SectionLabel.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Snackbar.jsx
try { (() => {
/**
 * Floating snackbar — inverse surface, radius 12, elev-2.
 * Calm receipts: "Notes saved", "Added to grocery — checked-off
 * items skipped", "Screenshot saved for your next import".
 */
function Snackbar({
  message,
  action,
  onAction,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 20,
      right: 20,
      bottom: 20,
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 16px',
      background: 'var(--inverse-surface)',
      color: 'var(--inverse-on-surface)',
      borderRadius: 'var(--radius-md)',
      boxShadow: 'var(--elev-2)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-lg-size)',
      lineHeight: 1.4,
      zIndex: 40,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }, message), action && /*#__PURE__*/React.createElement("button", {
    onClick: onAction,
    style: {
      border: 'none',
      background: 'transparent',
      color: 'var(--inverse-primary)',
      fontFamily: 'var(--font-body)',
      fontSize: 13,
      fontWeight: 'var(--weight-semibold)',
      cursor: 'pointer',
      padding: 0
    }
  }, action));
}
Object.assign(__ds_scope, { Snackbar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Snackbar.jsx", error: String((e && e.message) || e) }); }

// components/forms/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const HEIGHTS = {
  md: 'var(--button-h)',
  sm: 'var(--button-sm-h)'
};

/**
 * Stadium button — every MyReciBook button is a pill (StadiumBorder).
 * Variants map 1:1 to the Flutter theme: filled / tonal / outlined /
 * text / danger (the destructive-confirm verb).
 */
function Button({
  variant = 'filled',
  size = 'md',
  icon,
  trailingIcon,
  fullWidth = false,
  disabled = false,
  children,
  style = {},
  ...rest
}) {
  const base = {
    display: fullWidth ? 'flex' : 'inline-flex',
    width: fullWidth ? '100%' : undefined,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    height: HEIGHTS[size] || HEIGHTS.md,
    padding: size === 'sm' ? '0 14px' : '0 24px',
    borderRadius: 'var(--radius-full)',
    border: 'none',
    fontFamily: 'var(--font-body)',
    fontSize: size === 'sm' ? 13 : 'var(--label-lg-size)',
    fontWeight: 'var(--weight-semibold)',
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'filter var(--dur-fast) var(--ease-standard), transform var(--dur-fast) var(--ease-standard)',
    userSelect: 'none'
  };
  const variants = {
    filled: {
      background: 'var(--primary)',
      color: 'var(--on-primary)',
      boxShadow: 'var(--elev-1)'
    },
    tonal: {
      background: 'var(--secondary-container)',
      color: 'var(--on-secondary-container)'
    },
    outlined: {
      background: 'transparent',
      color: 'var(--primary)',
      border: 'var(--border-focus) solid var(--secondary)',
      height: size === 'sm' ? HEIGHTS.sm : 44
    },
    text: {
      background: 'transparent',
      color: 'var(--primary)',
      fontSize: 13,
      padding: '0 12px',
      height: size === 'sm' ? HEIGHTS.sm : 40
    },
    danger: {
      background: 'var(--error)',
      color: 'var(--on-error)'
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    disabled: disabled,
    style: {
      ...base,
      ...(variants[variant] || variants.filled),
      ...style
    },
    onMouseEnter: e => {
      if (!disabled) e.currentTarget.style.filter = 'brightness(1.08)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.filter = '';
      e.currentTarget.style.transform = '';
    },
    onMouseDown: e => {
      if (!disabled) e.currentTarget.style.transform = 'scale(0.98)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = '';
    }
  }, rest), icon, children, trailingIcon);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Button.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ConfirmDialog.jsx
try { (() => {
/**
 * THE canonical destructive confirm — reuse verbatim for any
 * destructive action; never draft new shapes. Title asks the
 * question, body states what survives before what stops,
 * actions are a safe text Cancel + a filled error verb.
 */
function ConfirmDialog({
  open = true,
  title,
  body,
  verb = 'Delete',
  onCancel,
  onConfirm,
  style = {}
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'var(--scrim)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: 28,
      zIndex: 50
    },
    onClick: onCancel
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      width: '100%',
      maxWidth: 320,
      background: 'var(--surface-container-lowest)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--elev-2)',
      padding: 24,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 'var(--title-lg-size)',
      fontWeight: 'var(--weight-bold)',
      color: 'var(--on-surface)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10,
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-lg-size)',
      lineHeight: 1.5,
      color: 'var(--on-surface-variant)'
    }
  }, body), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 18,
      display: 'flex',
      justifyContent: 'flex-end',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "text",
    onClick: onCancel
  }, "Cancel"), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "danger",
    onClick: onConfirm
  }, verb))));
}
Object.assign(__ds_scope, { ConfirmDialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ConfirmDialog.jsx", error: String((e && e.message) || e) }); }

// components/forms/CategoryChipRow.jsx
try { (() => {
/**
 * The category chip row — pantry shelf + Add-food drawer share it.
 * DIFFERENT from FilterChip: selected = solid PRIMARY fill. Labels
 * carry counts ("🥦 Produce 12"); emoji render as text here (the one
 * emoji surface in the app). null active = "All".
 */
function CategoryChipRow({
  categories = [],
  active = null,
  onSelect,
  allLabel = 'All',
  style = {}
}) {
  const pill = (key, label, selected) => /*#__PURE__*/React.createElement("button", {
    key: key === null ? '__all' : key,
    onClick: onSelect ? () => onSelect(key) : undefined,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      padding: '8px 14px',
      border: 'none',
      borderRadius: 'var(--radius-full)',
      background: selected ? 'var(--primary)' : 'var(--surface-container-high)',
      color: selected ? 'var(--on-primary)' : 'var(--on-surface)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-md-size)',
      fontWeight: 'var(--weight-medium)',
      whiteSpace: 'nowrap',
      cursor: 'pointer',
      flex: 'none',
      transition: 'background var(--dur-fast) var(--ease-standard)'
    }
  }, label);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      overflowX: 'auto',
      ...style
    }
  }, pill(null, allLabel, active === null), categories.map(c => pill(c.key, c.count != null ? `${c.label} ${c.count}` : c.label, active === c.key)));
}
Object.assign(__ds_scope, { CategoryChipRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/CategoryChipRow.jsx", error: String((e && e.message) || e) }); }

// components/icon/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Material Symbols Rounded glyph — the app's ONLY icon system
 * (Flutter `Icons.*_rounded`). `fill` for active/selected states.
 */
function Icon({
  name,
  size = 24,
  weight = 400,
  fill = false,
  color = 'currentColor',
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    className: "material-symbols-rounded",
    style: {
      fontSize: size,
      lineHeight: 1,
      color,
      fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${Math.min(48, Math.max(20, size))}`,
      userSelect: 'none',
      flex: 'none',
      ...style
    }
  }, rest), name);
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/icon/Icon.jsx", error: String((e && e.message) || e) }); }

// components/data-display/IngredientRow.jsx
try { (() => {
/** "400 g spaghetti" → bold leading quantity, regular rest. */
function qtyBold(raw) {
  const m = raw.match(/^[\d½¼¾⅓⅔][\d\s./,½¼¾⅓⅔×x–-]*\s*(?:[a-zA-Zæøåðþ]+\.?)?/);
  if (!m || m[0].length === 0 || m[0].length >= raw.length) return raw;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("strong", {
    style: {
      fontWeight: 'var(--weight-bold)'
    }
  }, raw.slice(0, m[0].length)), raw.slice(m[0].length));
}

/**
 * Check-off row for ingredients & grocery items: 18px radius-6
 * checkbox, bold leading quantity, strikethrough when checked.
 * Kitchen-session state — the caller owns it.
 */
function IngredientRow({
  text,
  checked = false,
  onToggle,
  trailing,
  staple = false,
  last = false,
  style = {}
}) {
  const row = /*#__PURE__*/React.createElement("div", {
    onClick: onToggle,
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      gap: 10,
      padding: '9px 0',
      borderBottom: last ? 'none' : '1px solid var(--separator)',
      cursor: onToggle ? 'pointer' : 'default',
      opacity: staple ? 0.55 : 1,
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 'var(--checkbox-size)',
      height: 'var(--checkbox-size)',
      marginTop: 1,
      flex: 'none',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: 6,
      background: checked ? 'var(--primary)' : 'transparent',
      border: checked ? 'none' : '2px solid var(--outline)',
      transition: 'background var(--dur-fast) var(--ease-standard)'
    }
  }, checked && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    size: 13,
    color: "var(--on-primary)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-md-size)',
      lineHeight: 1.45,
      textDecoration: checked ? 'line-through' : 'none',
      color: checked ? 'var(--on-surface-variant)' : 'var(--on-surface)'
    }
  }, qtyBold(text)), trailing && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-body)',
      fontSize: 11,
      color: 'var(--on-surface-variant)',
      alignSelf: 'center'
    }
  }, trailing), staple && /*#__PURE__*/React.createElement("span", {
    style: {
      alignSelf: 'center',
      padding: '2px 8px',
      borderRadius: 8,
      background: 'var(--surface-container-high)',
      fontFamily: 'var(--font-body)',
      fontSize: 10.5,
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--on-surface-variant)'
    }
  }, "staple"));
  return row;
}
Object.assign(__ds_scope, { qtyBold, IngredientRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/IngredientRow.jsx", error: String((e && e.message) || e) }); }

// components/data-display/MetaChip.jsx
try { (() => {
/**
 * Stadium meta chip on surface-container-high with a primary
 * icon — recipe time ("25 min") and servings ("Serves 4").
 */
function MetaChip({
  icon,
  label,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("span", {
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      padding: '7px 13px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--surface-container-high)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-md-size)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--on-surface)',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 16,
    color: "var(--primary)"
  }), label);
}
Object.assign(__ds_scope, { MetaChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/MetaChip.jsx", error: String((e && e.message) || e) }); }

// components/data-display/ProductRow.jsx
try { (() => {
/**
 * The ONE pantry product card — used by the Pantry list and the diary's
 * Add-food picker; change it here, both follow. 38px photo thumb
 * (secondary-container kitchen tile when absent), name + brand·quantity
 * meta, optional kcal MetaChip.
 */
function ProductRow({
  name,
  brand,
  quantity,
  kcal,
  image,
  onClick,
  style = {}
}) {
  const meta = [brand, quantity].filter(Boolean).join(' · ');
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      background: 'var(--surface-container-lowest)',
      border: '1px solid var(--hairline)',
      borderRadius: 14,
      boxShadow: 'var(--elev-1)',
      padding: '10px 14px',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, image ? /*#__PURE__*/React.createElement("img", {
    src: image,
    alt: "",
    style: {
      width: 38,
      height: 38,
      borderRadius: 12,
      objectFit: 'cover',
      flex: 'none'
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      width: 38,
      height: 38,
      borderRadius: 12,
      background: 'var(--secondary-container)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      flex: 'none'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "kitchen",
    size: 20,
    color: "var(--on-secondary-container)"
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-lg-size)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--on-surface)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, name), meta && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-sm-size)',
      color: 'var(--on-surface-variant)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, meta)), kcal != null && /*#__PURE__*/React.createElement(__ds_scope.MetaChip, {
    label: `${Math.round(kcal)} kcal`
  }));
}
Object.assign(__ds_scope, { ProductRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/ProductRow.jsx", error: String((e && e.message) || e) }); }

// components/data-display/StatusPill.jsx
try { (() => {
/**
 * Quiet status pill — the "On this phone" / "Synced" storage
 * badge. Success-tinted fill, muted text; never shouts.
 */
function StatusPill({
  icon,
  label,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      padding: '4px 10px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--pill-success-tint)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-sm-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: '0.2px',
      color: 'var(--on-surface-variant)',
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 13,
    color: "var(--on-surface-variant)"
  }), label);
}
Object.assign(__ds_scope, { StatusPill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/StatusPill.jsx", error: String((e && e.message) || e) }); }

// components/data-display/StripedPlaceholder.jsx
try { (() => {
/**
 * Diagonal-striped placeholder — stands in wherever a user
 * screenshot would render but none exists. Never ship real
 * artwork in these slots; the stripes ARE the design.
 */
function StripedPlaceholder({
  icon,
  height = '100%',
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "rb-stripes",
    style: {
      width: '100%',
      height,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 30,
    color: "var(--on-surface-variant)"
  }));
}
Object.assign(__ds_scope, { StripedPlaceholder });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/StripedPlaceholder.jsx", error: String((e && e.message) || e) }); }

// components/editor/DurationField.jsx
try { (() => {
/**
 * Editor duration pill: schedule icon, a number field, min/hr toggle —
 * "min" is a control, never typed. Reports total minutes (null when
 * empty/unparseable). Comma decimals accepted ("1,5" hr → 90).
 */
function DurationField({
  initialMinutes = null,
  onChanged,
  hint = '25',
  style = {}
}) {
  const whole = initialMinutes != null && initialMinutes >= 60 && initialMinutes % 60 === 0;
  const [unit, setUnit] = React.useState(whole ? 'hr' : 'min');
  const [text, setText] = React.useState(initialMinutes == null ? '' : String(whole ? initialMinutes / 60 : initialMinutes));
  const total = (t, u) => {
    const v = parseFloat(t.trim().replace(',', '.'));
    if (isNaN(v) || v <= 0) return null;
    const m = Math.round(u === 'hr' ? v * 60 : v);
    return m < 1 ? null : m;
  };
  const emit = (t, u) => onChanged && onChanged(total(t, u));
  const chip = u => /*#__PURE__*/React.createElement("button", {
    onClick: () => {
      setUnit(u);
      emit(text, u);
    },
    style: {
      padding: '6px 9px',
      border: 'none',
      borderRadius: 'var(--radius-full)',
      background: unit === u ? 'var(--secondary-container)' : 'transparent',
      color: unit === u ? 'var(--on-secondary-container)' : 'var(--on-surface-variant)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-sm-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: '0.2px',
      cursor: 'pointer',
      flex: 'none'
    }
  }, u);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      height: 40,
      padding: '0 5px 0 13px',
      border: '1px solid var(--hairline)',
      borderRadius: 'var(--radius-full)',
      boxSizing: 'border-box',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "schedule",
    size: 16,
    color: "var(--primary)"
  }), /*#__PURE__*/React.createElement("input", {
    type: "text",
    inputMode: "decimal",
    value: text,
    placeholder: hint,
    onChange: e => {
      const t = e.target.value.replace(/[^0-9.,]/g, '');
      setText(t);
      emit(t, unit);
    },
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      outline: 'none',
      background: 'transparent',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-md-size)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--on-surface)'
    }
  }), chip('min'), chip('hr'));
}
Object.assign(__ds_scope, { DurationField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/editor/DurationField.jsx", error: String((e && e.message) || e) }); }

// components/editor/ServingsStepper.jsx
try { (() => {
/**
 * Stadium pill with −/+ around "N servings" — the word is rendered,
 * never typed. 40px, hairline border, 32px round step targets.
 */
function ServingsStepper({
  value,
  onChange,
  min = 1,
  max = 99,
  style = {}
}) {
  const label = value === 1 ? '1 serving' : `${value} servings`;
  const step = d => onChange && onChange(Math.min(max, Math.max(min, value + d)));
  const btn = (icon, dis, d, title) => /*#__PURE__*/React.createElement("button", {
    onClick: dis ? undefined : () => step(d),
    title: title,
    style: {
      width: 32,
      height: 32,
      border: 'none',
      background: 'transparent',
      borderRadius: '50%',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: dis ? 'default' : 'pointer',
      padding: 0,
      flex: 'none'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 18,
    color: dis ? 'color-mix(in srgb, var(--on-surface-variant) 40%, transparent)' : 'var(--primary)'
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      height: 40,
      padding: '0 4px',
      border: '1px solid var(--hairline)',
      borderRadius: 'var(--radius-full)',
      boxSizing: 'border-box',
      ...style
    }
  }, btn('remove', value <= min, -1, 'Fewer servings'), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-md-size)',
      fontWeight: 'var(--weight-medium)',
      color: 'var(--on-surface)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, label), btn('add', value >= max, 1, 'More servings'));
}
Object.assign(__ds_scope, { ServingsStepper });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/editor/ServingsStepper.jsx", error: String((e && e.message) || e) }); }

// components/forms/FilterChip.jsx
try { (() => {
/**
 * 36px stadium filter chip (All / Favorites / Quick / Sweet).
 * Selected = secondary-container fill; icon turns with it.
 */
function FilterChip({
  label,
  icon,
  selected = false,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      height: 'var(--chip-h)',
      padding: '0 14px',
      border: 'none',
      borderRadius: 'var(--radius-full)',
      background: selected ? 'var(--secondary-container)' : 'var(--surface-container-high)',
      color: selected ? 'var(--on-secondary-container)' : 'var(--on-surface)',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--label-md-size)',
      fontWeight: 'var(--weight-semibold)',
      cursor: 'pointer',
      transition: 'background var(--dur-fast) var(--ease-standard)',
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 15,
    color: selected ? 'var(--on-secondary-container)' : 'var(--primary)'
  }), label);
}
Object.assign(__ds_scope, { FilterChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/FilterChip.jsx", error: String((e && e.message) || e) }); }

// components/forms/SearchBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Pill search field — 48px stadium on surface-container
 * ("Search your cookbook…").
 */
function SearchBar({
  placeholder = 'Search your cookbook…',
  value,
  onChange,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      height: 'var(--search-h)',
      padding: '0 16px',
      background: 'var(--surface-container)',
      borderRadius: 'var(--radius-full)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "search",
    size: 20,
    color: "var(--on-surface-variant)"
  }), /*#__PURE__*/React.createElement("input", _extends({
    type: "text",
    value: value,
    onChange: onChange ? e => onChange(e.target.value) : undefined,
    placeholder: placeholder,
    style: {
      flex: 1,
      minWidth: 0,
      border: 'none',
      outline: 'none',
      background: 'transparent',
      fontFamily: 'var(--font-body)',
      fontSize: 'var(--body-lg-size)',
      color: 'var(--on-surface)'
    }
  }, rest)));
}
Object.assign(__ds_scope, { SearchBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SearchBar.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
/**
 * Stadium segmented control — one pill container (3px padding,
 * surface-container-high), the active segment is a
 * surface-container-lowest pill with the card shadow.
 * Used by the import sheet ("One recipe · 3 shots / 3 separate
 * recipes") and Settings theme picker (with check icon).
 */
function SegmentedControl({
  options,
  value,
  onChange,
  showCheck = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      padding: 3,
      background: 'var(--surface-container-high)',
      borderRadius: 'var(--radius-full)',
      ...style
    }
  }, options.map(opt => {
    const o = typeof opt === 'string' ? {
      value: opt,
      label: opt
    } : opt;
    const selected = o.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: o.value,
      onClick: onChange ? () => onChange(o.value) : undefined,
      style: {
        flex: 1,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 5,
        height: 'var(--segment-h)',
        border: selected && showCheck ? '1px solid var(--hairline)' : 'none',
        borderRadius: 'var(--radius-full)',
        background: selected ? 'var(--surface-container-lowest)' : 'transparent',
        boxShadow: selected ? 'var(--elev-1)' : 'none',
        color: selected ? showCheck ? 'var(--on-surface)' : 'var(--primary)' : 'var(--on-surface-variant)',
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-md-size)',
        fontWeight: selected ? 'var(--weight-semibold)' : 'var(--weight-medium)',
        cursor: 'pointer',
        transition: 'background var(--dur-fast) var(--ease-standard), box-shadow var(--dur-fast) var(--ease-standard)'
      }
    }, selected && showCheck && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "check",
      size: 15
    }), o.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/navigation/AppBackButton.jsx
try { (() => {
/**
 * The one back button — arrow_back (rounded), 22px app-bar icon size,
 * 44px hit target, tooltip "Back". Flutter's BackButton forces the
 * platform glyph; this stays ours.
 */
function AppBackButton({
  onClick,
  color = 'var(--on-surface)',
  style = {}
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    title: "Back",
    style: {
      width: 44,
      height: 44,
      border: 'none',
      background: 'transparent',
      borderRadius: '50%',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      padding: 0,
      flex: 'none',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "arrow_back",
    size: 22,
    color: color
  }));
}
Object.assign(__ds_scope, { AppBackButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/AppBackButton.jsx", error: String((e && e.message) || e) }); }

// components/navigation/GradientFab.jsx
try { (() => {
/**
 * The 52px gradient FAB — the import door. 135° primary-container
 * → primary, white add glyph, strong Moody Blue glow.
 */
function GradientFab({
  icon = 'add',
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      width: 'var(--fab-size)',
      height: 'var(--fab-size)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: '50%',
      border: 'none',
      background: 'var(--gradient-fab)',
      boxShadow: 'var(--glow-fab)',
      cursor: 'pointer',
      padding: 0,
      flex: 'none',
      transition: 'transform var(--dur-fast) var(--ease-standard)',
      ...style
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.95)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = '';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = '';
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 24,
    color: "var(--on-primary)"
  }));
}
Object.assign(__ds_scope, { GradientFab });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/GradientFab.jsx", error: String((e && e.message) || e) }); }

// components/navigation/GlassNavBar.jsx
try { (() => {
/**
 * Floating glass pill nav bar: 56px pill inside a 64px hint (FAB
 * overhang), 16px above the bottom edge, 20px side margins.
 * 4 tabs split 2+2 around the center gradient FAB — Cookbook ·
 * Grocery · [FAB] · slot 3 (feature-flagged: Food / Pantry / Unlock /
 * Queue) · Settings. The Cookbook tab draws the LogoMark (book only)
 * so the tab and the app icon are one mark. Content scrolls under.
 */
function GlassNavBar({
  items,
  active = 0,
  onTab,
  onFab,
  style = {}
}) {
  const tabs = items || [{
    icon: 'menu_book',
    label: 'Cookbook',
    logo: true
  }, {
    icon: 'checklist',
    label: 'Grocery'
  }, {
    icon: 'download',
    label: 'Queue'
  }, {
    icon: 'settings',
    label: 'Settings'
  }];
  const item = (t, i) => {
    const selected = i === active;
    const color = selected ? 'var(--primary)' : 'var(--on-surface-variant)';
    return /*#__PURE__*/React.createElement("button", {
      key: t.label,
      onClick: onTab ? () => onTab(i) : undefined,
      style: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 2,
        border: 'none',
        background: 'transparent',
        cursor: 'pointer',
        padding: 0,
        color
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'relative',
        display: 'inline-flex'
      }
    }, t.logo ? /*#__PURE__*/React.createElement(__ds_scope.LogoMark, {
      size: 22,
      withSteam: false,
      color: color
    }) : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: t.icon,
      size: 22,
      fill: selected
    }), t.badge > 0 && /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'absolute',
        top: -4,
        right: -8,
        minWidth: 15,
        height: 15,
        padding: '0 4px',
        borderRadius: 'var(--radius-full)',
        background: 'var(--primary)',
        color: 'var(--on-primary)',
        fontFamily: 'var(--font-body)',
        fontSize: 10,
        fontWeight: 'var(--weight-bold)',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center'
      }
    }, t.badge)), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--font-body)',
        fontSize: 10.5,
        fontWeight: 'var(--weight-semibold)',
        letterSpacing: '0.2px'
      }
    }, t.label));
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 20,
      right: 20,
      bottom: 16,
      height: 64,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: 0,
      right: 0,
      bottom: 0,
      height: 'var(--nav-pill-h)',
      display: 'flex',
      alignItems: 'stretch',
      borderRadius: 'var(--radius-full)',
      background: 'var(--glass-fill)',
      border: '1px solid var(--glass-border)',
      backdropFilter: 'blur(var(--blur-glass))',
      WebkitBackdropFilter: 'blur(var(--blur-glass))'
    }
  }, item(tabs[0], 0), item(tabs[1], 1), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 60,
      flex: 'none'
    }
  }), item(tabs[2], 2), item(tabs[3], 3)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 0,
      left: '50%',
      transform: 'translateX(-50%)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.GradientFab, {
    onClick: onFab
  })));
}
Object.assign(__ds_scope, { GlassNavBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/GlassNavBar.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/DashedInfoCard.jsx
try { (() => {
/**
 * Dashed-border info card — the quiet product-promise framing:
 * "Not a recipe? We skip it and say so — no junk lands in your book."
 */
function DashedInfoCard({
  children,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '11px 13px',
      border: '1px dashed color-mix(in srgb, var(--outline) 60%, transparent)',
      borderRadius: 'var(--radius-md)',
      fontFamily: 'var(--font-body)',
      fontSize: 12.5,
      lineHeight: 1.5,
      color: 'var(--on-surface-variant)',
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { DashedInfoCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/DashedInfoCard.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/GlassCircle.jsx
try { (() => {
/**
 * 40px frosted-glass circular button — hero overlays (back,
 * edit, favorite, delete over the recipe cover).
 */
function GlassCircle({
  icon,
  fill = false,
  iconColor,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      width: 'var(--glass-circle)',
      height: 'var(--glass-circle)',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: '50%',
      background: 'var(--glass-fill)',
      border: '1px solid var(--glass-border)',
      backdropFilter: 'blur(var(--blur-glass-soft))',
      WebkitBackdropFilter: 'blur(var(--blur-glass-soft))',
      cursor: 'pointer',
      padding: 0,
      flex: 'none',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20,
    fill: fill,
    color: iconColor || 'var(--on-surface)'
  }));
}
Object.assign(__ds_scope, { GlassCircle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/GlassCircle.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/GlassPill.jsx
try { (() => {
/**
 * Frosted-glass stadium pill with icon + tiny label — the
 * cover ⇄ original provenance flipper on the recipe hero.
 */
function GlassPill({
  icon,
  label,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 5,
      padding: '6px 12px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--glass-fill)',
      border: '1px solid var(--glass-border)',
      backdropFilter: 'blur(var(--blur-glass-soft))',
      WebkitBackdropFilter: 'blur(var(--blur-glass-soft))',
      fontFamily: 'var(--font-body)',
      fontSize: 11.5,
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: '0.2px',
      color: 'var(--on-surface)',
      cursor: 'pointer',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 15
  }), label);
}
Object.assign(__ds_scope, { GlassPill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/GlassPill.jsx", error: String((e && e.message) || e) }); }

// components/editor/CoverPickerField.jsx
try { (() => {
/**
 * Tappable cover slot for the editors: the chosen photo (with a "change"
 * glass pill), or an "Add a cover photo" affordance. Camera/gallery
 * choice happens in a sheet the screen owns — this is just the door.
 */
function CoverPickerField({
  src = null,
  height = 140,
  onClick,
  style = {}
}) {
  if (!src) {
    return /*#__PURE__*/React.createElement("div", {
      onClick: onClick,
      role: "button",
      style: {
        height,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        background: 'var(--surface-container-low)',
        border: '1px solid var(--hairline)',
        borderRadius: 'var(--radius-md)',
        cursor: 'pointer',
        ...style
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "add_a_photo",
      size: 22,
      color: "var(--primary)"
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--font-body)',
        fontSize: 'var(--label-lg-size)',
        fontWeight: 'var(--weight-semibold)',
        color: 'var(--primary)'
      }
    }, "Add a cover photo"));
  }
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    role: "button",
    style: {
      position: 'relative',
      height,
      borderRadius: 'var(--radius-md)',
      overflow: 'hidden',
      cursor: 'pointer',
      ...style
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      display: 'block'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      right: 8,
      bottom: 8,
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.GlassPill, {
    icon: "edit",
    label: "change"
  })));
}
Object.assign(__ds_scope, { CoverPickerField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/editor/CoverPickerField.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/TokenCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * The house card: surface-container-lowest, hairline border,
 * radius 12–16, soft blue-tinted shadow. `selected` switches to
 * the 1.5px primary border + Moody Blue glow (selected storage
 * option, merge prompt, paywall price card).
 */
function TokenCard({
  children,
  padding = 12,
  radius = 12,
  selected = false,
  shadow = true,
  color,
  borderColor,
  style = {},
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      background: color || 'var(--surface-container-lowest)',
      borderRadius: radius,
      border: selected ? 'var(--border-focus) solid var(--primary)' : `var(--border-hairline) solid ${borderColor || 'var(--hairline)'}`,
      boxShadow: selected ? 'var(--glow-primary)' : shadow ? 'var(--elev-1)' : 'none',
      padding,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { TokenCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/TokenCard.jsx", error: String((e && e.message) || e) }); }

__ds_ns.LogoMark = __ds_scope.LogoMark;

__ds_ns.IngredientRow = __ds_scope.IngredientRow;

__ds_ns.MetaChip = __ds_scope.MetaChip;

__ds_ns.ProductRow = __ds_scope.ProductRow;

__ds_ns.RecipeCard = __ds_scope.RecipeCard;

__ds_ns.COVER_GRADIENTS = __ds_scope.COVER_GRADIENTS;

__ds_ns.RecipeCover = __ds_scope.RecipeCover;

__ds_ns.SectionLabel = __ds_scope.SectionLabel;

__ds_ns.StatusPill = __ds_scope.StatusPill;

__ds_ns.StripedPlaceholder = __ds_scope.StripedPlaceholder;

__ds_ns.CoverPickerField = __ds_scope.CoverPickerField;

__ds_ns.DurationField = __ds_scope.DurationField;

__ds_ns.ServingsStepper = __ds_scope.ServingsStepper;

__ds_ns.ConfirmDialog = __ds_scope.ConfirmDialog;

__ds_ns.Snackbar = __ds_scope.Snackbar;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.CategoryChipRow = __ds_scope.CategoryChipRow;

__ds_ns.FilterChip = __ds_scope.FilterChip;

__ds_ns.SearchBar = __ds_scope.SearchBar;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.AppBackButton = __ds_scope.AppBackButton;

__ds_ns.GlassNavBar = __ds_scope.GlassNavBar;

__ds_ns.GradientFab = __ds_scope.GradientFab;

__ds_ns.DashedInfoCard = __ds_scope.DashedInfoCard;

__ds_ns.GlassCircle = __ds_scope.GlassCircle;

__ds_ns.GlassPill = __ds_scope.GlassPill;

__ds_ns.TokenCard = __ds_scope.TokenCard;

})();

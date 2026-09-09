// Re-serialises a merged JSON file in the layout its "ours" side already used.
// Usage: git-json-merge-fix.mjs <merged-file> <pre-merge-ours-file>
import { readFileSync, writeFileSync } from 'node:fs';

const [mergedPath, originalPath] = process.argv.slice(2);
const merged = JSON.parse(readFileSync(mergedPath, 'utf8'));
const original = readFileSync(originalPath, 'utf8');

const endsWithNewline = original.endsWith('\n');

// Indentation of the first nested line, if the file indents at all.
const indentMatch = original.match(/^[ \t]+(?=\S)/m);
const indent = indentMatch ? indentMatch[0] : '';

// xdiff appends the keys it patched in rather than placing them, so an
// alphabetical map comes back out of order. Only re-sort files that were already
// sorted: the *.json glob also covers package.json and tsconfig.json, where key
// order is deliberate.
function keysWereSorted(text) {
  try {
    const keys = Object.keys(JSON.parse(text));
    return keys.length > 1 && keys.every((key, i) => i === 0 || keys[i - 1] <= key);
  } catch {
    return false;
  }
}

function withSortedKeys(object) {
  const result = {};
  for (const key of Object.keys(object).sort()) result[key] = object[key];
  return result;
}

// One key per line, value object inline, no indentation — mirrors formatOutput in
// the monorepo's packages/i18n/src/translate.ts.
function formatFlatMap(object, resort) {
  const keys = resort ? Object.keys(object).sort() : Object.keys(object);
  const lines = keys.map((key) => {
    const value = object[key];
    const isPlain = value !== null && typeof value === 'object' && !Array.isArray(value);
    if (!isPlain) return `${JSON.stringify(key)}: ${JSON.stringify(value)}`;

    // translate.ts emits description before defaultMessage.
    const inner = Object.keys(value)
      .sort((a, b) =>
        a === 'description' ? -1 : b === 'description' ? 1 : a.localeCompare(b),
      )
      .map((name) => `${JSON.stringify(name)}: ${JSON.stringify(value[name])}`)
      .join(', ');

    return `${JSON.stringify(key)}: { ${inner} }`;
  });

  return `{\n${lines.join(',\n')}\n}`;
}

function isFlatMapOfObjects(object) {
  const values = Object.values(object);
  return (
    values.length > 0 &&
    values.every(
      (value) =>
        value === null ||
        typeof value !== 'object' ||
        (!Array.isArray(value) &&
          Object.values(value).every((inner) => typeof inner !== 'object')),
    )
  );
}

const isPlainObject =
  merged !== null && typeof merged === 'object' && !Array.isArray(merged);
const resort = isPlainObject && keysWereSorted(original);

const output =
  indent === '' && isPlainObject && isFlatMapOfObjects(merged)
    ? formatFlatMap(merged, resort)
    : JSON.stringify(resort ? withSortedKeys(merged) : merged, null, indent || 2);

writeFileSync(mergedPath, endsWithNewline ? `${output}\n` : output, 'utf8');

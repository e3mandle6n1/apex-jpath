# Troubleshooting

## Execute Anonymous: CPU / heap / log explosions

**Symptoms**: `System.LimitException: Apex CPU time limit exceeded`, heap size
errors, `HTTP ERROR 431`, or huge debug logs when trying a path in Developer
Console.

**Cause**: One anonymous block often contains many queries plus
`JSON.serialize` / `System.debug` on large graphs. The window also counts the
entire script body (including comments) toward processing cost.

**Fix**: Run **one** query per Execute Anonymous execution. Copy only the
payload setup and a single `selectPath` from `examples/`. Prefer small payloads
while exploring; use the [JSONPath Finder](https://e3mandle6n1.github.io/apex-jpath/)
to draft paths before pasting into Apex.

## Path must start with `$`

**Symptoms**: `JSONPathException` mentioning that the path must start with `$`.

**Cause**: `selectPath` requires a root-anchored expression.

**Fix**: Use `$.…` or `$..…`, not a bare property name.

## Blank or invalid JSON

**Symptoms**: `JSONPathException` on construction (`JSON string cannot be null
or empty` or parse failure).

**Cause**: Empty constructor input, or JSON that `JSON.deserializeUntyped`
rejects.

**Fix**: Pass a non-blank JSON string. The constructor trims newlines; it does
not repair malformed JSON.

## Filter / function not supported

**Symptoms**: Empty results or unexpected misses for `&&` / `||`, `length()`,
or `$` inside `[?(…)]`.

**Cause**: Those features are intentionally out of scope. See
[library limitations](../library/jsonpath.md#limitations-by-design).

**Fix**: Split into simpler paths in Apex, or filter the returned
`List<Object>` in code.

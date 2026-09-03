# JSONPath library

Native Apex JSONPath/JPath-style querying. Classes live under
`force-app/main/default/classes/`.

## Surface

| Member | Purpose |
|--------|---------|
| `JSONPath(String jsonString)` | Deserialize JSON; blank or invalid JSON throws `JSONPathException` |
| `List<Object> selectPath(String path)` | Return matches for a path that starts with `$` |
| `JSONPathException` | Library error type |

Paths that omit `$` or are blank throw `JSONPathException`.

## Supported operations

| Operation | Syntax | Description |
|-----------|--------|-------------|
| Property access | `$.property` | Object property |
| Array indexing | `$.array[0]` | Element by index (negative indices supported) |
| Wildcard | `$.array[*]` | All elements |
| Filter | `$.array[?(@.prop > 10)]` | Simple comparisons |
| Recursive descent | `$..property` | Property at any depth |
| Slice | `$.array[0:2]` | Array slice |

## Examples

### Basic property access

```apex
String json = '{"name": "John", "age": 30}';
JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.name');
// ["John"]
```

### Array indexing

```apex
String json = '{"fruits": ["apple", "banana", "orange"]}';
JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.fruits[1]');
// ["banana"]
```

### Filtering

```apex
String json = '{"employees":[{"name":"John","salary":50000},{"name":"Jane","salary":60000},{"name":"Bob","salary":45000}]}';
JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.employees[?(@.salary > 50000)]');
```

Numeric comparisons also work when values are stored as strings in JSON (e.g.
`"price": "12.99"` vs `12.99`).

Longer Execute Anonymous samples: `examples/example1.txt`, `examples/example2.txt`.
Path explorer: https://e3mandle6n1.github.io/apex-jpath/

## Limitations (by design)

Omitted to stay secure and governor-limit friendly:

- Script expressions / `eval()`
- Complex filter logic (`&&`, `||`, grouping)
- JSONPath functions (`length()`, `avg()`, `match()`, …)
- Referencing root (`$`) inside filters

Install and deploy: [local development](../usage/local-development.md).

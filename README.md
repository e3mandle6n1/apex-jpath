# Salesforce Apex JPath

[![Salesforce Platform](https://img.shields.io/badge/Platform-Salesforce%20Winter%20'26-blue.svg?logo=salesforce&logoColor=white)](https://www.salesforce.com/platform/)
[![Apex](https://img.shields.io/badge/Apex-v64.0-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
[![Apex Tests](https://github.com/e3mandle6n1/apex-jpath/actions/workflows/apex-tests.yml/badge.svg)](https://github.com/e3mandle6n1/apex-jpath/actions/workflows/apex-tests.yml)
[![Salesforce DX](https://img.shields.io/badge/CLI-v2.108.6-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/sfdxcli)
[![JSON](https://img.shields.io/badge/JSON-000?logo=json&logoColor=fff)](#)
[![Node.js](https://img.shields.io/badge/Node.js-6DA55F?logo=node.js&logoColor=white)](#)

Query complex JSON in Apex… simply.

- Pure Apex JSONPath/JPath-style querying
- Fast path selection, wildcards, slices, and simple filters
- Includes an interactive JSONPath Finder tool

## What This Repo Contains

- Apex library source: `force-app/`
- Example Execute Anonymous snippets: `examples/`
- GitHub Pages JSONPath Finder: https://e3mandle6n1.github.io/apex-jpath/

## Prerequisites

Required:

- A Salesforce org (Scratch org, Sandbox, or Prod)

For developer workflow:

- Salesforce CLI (`sf`)

## Quick Start

### Unlocked Package Installation

**Production org:**

[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)

**Sandbox org:**

[![Deploy to Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)

### Developer Installation

```bash
git clone https://github.com/e3mandle6n1/apex-jpath
cd apex-jpath
sf force:source:deploy -p force-app
```

## JSONPath Finder Tool

Use the interactive tool to explore payloads, generate paths, and copy sample Apex code:

- https://e3mandle6n1.github.io/apex-jpath/

## Usage

> For quick hands-on evaluation, see `examples/example1.txt` and `examples/example2.txt`.

### Basic Property Access

```apex
String json = '{"name": "John", "age": 30}';
JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.name');
// Returns: ["John"]
```

### Array Indexing

```apex
String json = '{"fruits": ["apple", "banana", "orange"]}';
JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.fruits[1]');
// Returns: ["banana"]
```

### Filtering

```apex
String json = '{
  "employees": [
    {"name": "John", "salary": 50000},
    {"name": "Jane", "salary": 60000},
    {"name": "Bob", "salary": 45000}
  ]
}';

JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.employees[?(@.salary > 50000)]');
// Returns employees with salary > 50000
```

### Numeric Comparisons with String Values

```apex
String json = '{
  "items": [
    {"name": "A", "price": 12.99},
    {"name": "B", "price": 12.99},
    {"name": "C", "price": 8}
  ]
}';

JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.items[?(@.price >= 12.99)]');
// Correctly matches both items with price >= 12.99
```

## Supported Operations

| Operation         | Syntax                    | Description                   |
| :---------------- | :------------------------ | :---------------------------- |
| Property Access   | `$.property`              | Access object property        |
| Array Indexing    | `$.array[0]`              | Access array element by index |
| Wildcard          | `$.array[*]`              | Select all elements           |
| Filter            | `$.array[?(@.prop > 10)]` | Filter elements               |
| Recursive Descent | `$..property`             | Find property at any level    |
| Slice             | `$.array[0:2]`            | Extract slice of array        |

## Limitations (By Design)

To stay secure and governor-limit friendly, this Apex implementation omits:

- Script expressions / `eval()`
- Complex filter logic (`&&`, `||`, grouping)
- JSONPath functions (`length()`, `avg()`, `match()`, etc.)
- Referencing root (`$`) inside filters

## Testing

CI runs Apex tests on every push/PR via GitHub Actions:

- https://github.com/e3mandle6n1/apex-jpath/actions/workflows/apex-tests.yml

## License

MIT

## Contributing

1. Fork the repo
2. Create a feature branch
3. Commit changes
4. Open a Pull Request

## Support

- Questions / feature requests: https://github.com/e3mandle6n1/apex-jpath/discussions
- Bugs: open an issue

All proceeds support coding education for kids in Africa: https://tangible.levafoundation.org/

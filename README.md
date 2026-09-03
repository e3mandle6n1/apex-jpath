# Salesforce Apex JPath

[![Apex Tests](https://github.com/e3mandle6n1/apex-jpath/actions/workflows/apex-tests.yml/badge.svg)](https://github.com/e3mandle6n1/apex-jpath/actions/workflows/apex-tests.yml)
[![Salesforce Platform](https://img.shields.io/badge/Platform-Salesforce%20Winter%20'26-blue.svg?logo=salesforce&logoColor=white)](https://www.salesforce.com/platform/)
[![Apex](https://img.shields.io/badge/Apex-v64.0-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
[![Salesforce DX](https://img.shields.io/badge/CLI-sf-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/sfdxcli)
[![JSON](https://img.shields.io/badge/JSON-000?logo=json&logoColor=fff)](#)

Pure Apex JSONPath/JPath-style querying for Salesforce. Path selection, wildcards,
slices, and simple filters; no script/`eval`. Ships an unlocked package, source
under `force-app/`, and an interactive [JSONPath Finder](https://e3mandle6n1.github.io/apex-jpath/).

## Responsibilities

- Parse JSON in Apex and evaluate JSONPath expressions via `JSONPath.selectPath`
- Support property access, indexing, wildcards, slices, recursive descent, and simple filters
- Stay governor-limit and security friendly by omitting script expressions and complex filter logic
- Provide Execute Anonymous examples and a browser finder that generates sample Apex

## Configuration

**Production org:**

[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)

**Sandbox org:**

[![Deploy to Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)

For source deploy you need a Salesforce org and Salesforce CLI auth. Do not commit
auth URLs, tokens, or org credentials.

```bash
sf org login web --alias <alias>
# CI uses a Dev Hub auth URL in GitHub Actions secret SFDX_AUTH_URL
```

## Architecture

```text
Apex caller / Execute Anonymous
        |
        |  JSON string
        v
  JSONPath                deserializeUntyped → root (Map | List)
        |
        |  selectPath('$.…')
        v
  segment loop            current node set → next node set
        |
        +-- .key / ["key"]     property
        +-- [n] / [-n]         index
        +-- [*]                wildcard
        +-- [start:end:step]   slice
        +-- [a,b]              union
        +-- [?(…)]             simple filter
        +-- ..key              recursive descent
        |
        v
  List<Object> matches

Repo layout:

  force-app/     JSONPath + JSONPathException + tests
  examples/      Execute Anonymous snippets
  docs/          Pages finder (index.html) + usage / library guides
  .github/       scratch-org deploy + Apex test CI
```

- `force-app/` is the product. Everything else helps you install, explore paths, or prove the library still works.
- Evaluation is pure Apex: one parse up front, then a left-to-right walk of path segments over an in-memory tree. No callouts, no Dynamic Apex.
- Filters stay simple on purpose (no `eval`, no `&&` / `||`); unsupported JSONPath is listed in the library doc.

More detail:

- [Local development](docs/usage/local-development.md)
- [Library surface](docs/library/jsonpath.md)
- [Troubleshooting](docs/usage/troubleshooting.md)

## Library

Public surface is small:

| Member | Purpose |
|--------|---------|
| `JSONPath(String jsonString)` | Parse JSON; blank/invalid input throws `JSONPathException` |
| `List<Object> selectPath(String path)` | Evaluate a path starting with `$` |

Supported operations, examples, and intentional limits: [library](docs/library/jsonpath.md).

## Local Development

```bash
git clone https://github.com/e3mandle6n1/apex-jpath
cd apex-jpath
sf project deploy start --source-dir force-app --target-org <alias>
```

Install options, examples, and tests: [local development](docs/usage/local-development.md).

Interactive path explorer: https://e3mandle6n1.github.io/apex-jpath/

MIT. Proceeds support coding education for kids in Africa: https://tangible.levafoundation.org/

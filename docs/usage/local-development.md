# Local development

## Prerequisites

- A Salesforce org (scratch, sandbox, or production)
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) for source deploy and tests

## 1. Install via unlocked package

No CLI required:

- [Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)
- [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td2000000q7aYAAQ)

## 2. Deploy from source

```bash
git clone https://github.com/e3mandle6n1/apex-jpath
cd apex-jpath
sf org login web --alias <alias>
sf project deploy start --source-dir force-app --target-org <alias>
```

Scratch org (matches CI shape):

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias jpath-scratch --set-default
sf project deploy start --source-dir force-app
sf apex run test --test-level RunLocalTests --result-format human --wait 10
```

## 3. Try it

- Library contract and snippets: [JSONPath library](../library/jsonpath.md)
- Execute Anonymous payloads: `examples/example1.txt`, `examples/example2.txt`
- Browser finder (generate paths + sample Apex): https://e3mandle6n1.github.io/apex-jpath/

Run **one** query per Execute Anonymous window. Serializing and debugging large
results in a single block often hits CPU / heap / log limits. See
[troubleshooting](troubleshooting.md).

## 4. CI

GitHub Actions workflow [apex-tests.yml](../../.github/workflows/apex-tests.yml)
authenticates a Dev Hub (`SFDX_AUTH_URL`), creates a one-day scratch org, deploys
`force-app`, runs local Apex tests, then deletes the org.

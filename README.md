# Salesforce Apex JPath Library

In Apex, while `JSON.deserialize()` is effective for mapping JSON to strongly-typed Apex objects, it requires a predefined class structure. For dynamic JSON or when you only need a few specific values from a large, complex structure, using `JSON.deserializeUntyped()` is the alternative. However, this often leads to verbose and hard-to-read code with multiple levels of casting and map lookups, a pattern often referred to as "map-string-object hell."

The apex-jpath library simplifies this by providing a concise, expressive way to query and extract data from a JSON structure using JPath expressions. This avoids the need for boilerplate code and makes the developer's intent much clearer.

[![Salesforce Platform](https://img.shields.io/badge/Platform-Salesforce%20Winter%20'26-blue.svg?logo=salesforce&logoColor=white)](https://www.salesforce.com/platform/)
[![Apex](https://img.shields.io/badge/Apex-v64.0-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
[![Salesforce DX](https://img.shields.io/badge/CLI-v2.108.6-blue.svg?logo=salesforce&logoColor=white)](https://developer.salesforce.com/tools/sfdxcli)
[![JSON](https://img.shields.io/badge/JSON-000?logo=json&logoColor=fff)](#)
[![Node.js](https://img.shields.io/badge/Node.js-6DA55F?logo=node.js&logoColor=white)](#)

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
  - [Unlocked Package Installation](#unlocked-package-installation)
  - [Developer Installation](#developer-installation)
- [Features](#features)
- [→ JSONPath Finder Tool ←🆕😍](#jsonpath-finder-tool)
- [Usage Examples](#usage-examples)
  - [Basic Property Access](#basic-property-access)
  - [Array Indexing](#array-indexing)
  - [Filtering](#filtering)
  - [Numeric Comparisons with String Values](#numeric-comparisons-with-string-values)
- [More Usage Examples](#more-usage-examples)
  - [Sample JSON](#sample-json)
  - [Basic Usage](#basic-usage)
    - [1. Accessing a Top-Level Property](#1-accessing-a-top-level-property)
    - [2. Accessing a Nested Property](#2-accessing-a-nested-property)
    - [3. Accessing an Element in an Array by Index](#3-accessing-an-element-in-an-array-by-index)
    - [4. Accessing a Specific Property of an Array Element](#4-accessing-a-specific-property-of-an-array-element)
  - [Intermediate Usage](#intermediate-usage)
    - [5. Getting a List of a Specific Property from an Array of Objects](#5-getting-a-list-of-a-specific-property-from-an-array-of-objects)
    - [6. Retrieving an Entire Array](#6-retrieving-an-entire-array)
  - [Advanced Usage](#advanced-usage)
    - [7. Filtering an Array to Find an Object by a Property Value](#7-filtering-an-array-to-find-an-object-by-a-property-value)
    - [8. Filtering to Get a Property of a Matching Object](#8-filtering-to-get-a-property-of-a-matching-object)
    - [9. Filtering Based on a Boolean Property](#9-filtering-based-on-a-boolean-property)
    - [10. Filtering Based on "Greater Than" or "Less Than"](#10-filtering-based-on-greater-than-or-less-than)
- [How?](#how)
- [Supported Operations](#supported-operations)
- [Limitations and Design Choices](#limitations-and-design-choices)
- [Testing](#testing)
- [License](#license)
- [Contributing](#contributing)
- [Support](#support)

## Overview

This library provides JSONPath functionality directly within Apex, allowing developers to query and filter JSON data using familiar JSONPath expressions. It's designed specifically for Salesforce environments and supports common JSONPath operations including:

- Property access (`.property`)
- Array indexing (`[0]`, `[-1]`)
- Wildcard matching (`[*]`)
- Filter expressions (`[?(@.property > 10)]`)
- Recursive descent (`..property`)
- Slice operations (`[0:2]`)

## Installation

### Unlocked Package Installation

Install this package using the following URL in your Salesforce prod org:

[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td20000007RjRAAU)

Install this package using the following URL in your Salesforce sandbox org:

[![Deploy to Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td20000007RjRAAU)

### Developer Installation

1.  Clone this repository
2.  Deploy to your Salesforce org using sf:
    ```bash
    sf force:source:deploy -p force-app
    ```

## Features

- **Native Apex Implementation**: Pure Apex code with no external dependencies
- **Full JSONPath Support**: Implements core JSONPath specification with Salesforce-specific enhancements
- **Type Safety**: Robust type handling with automatic conversion between numeric types
- **Filter Expressions**: Complex filtering with comparison operators and logical conditions
- **Error Handling**: Comprehensive exception handling with descriptive error messages
- **Performance Optimized**: Efficient parsing and evaluation of JSONPath expressions

## JSONPath Finder Tool

🔍 **Need help constructing JSONPath expressions?**

Use the interactive <a href="https://e3mandle6n1.github.io/apex-jpath/" target="_blank" rel="noopener noreferrer">**JSONPath Finder Tool**</a> to:

- **Paste your JSON payload** and instantly visualise its structure
- **Navigate hierarchically** through nested objects and arrays
- **Copy paths with one click** - hover over any node and click "Copy"
- **Avoid syntax errors** - get the exact path you need

Perfect for:

- Building complex queries for deeply nested JSONfeat(v0.2): enhance core library, add interactive JSONPath Finder tool, and improve docs
- Learning JSONPath syntax interactively
- Quickly testing path expressions before using them in Apex

> **Pro Tip:** Use this tool alongside the [example files](#usage-examples) to rapidly prototype and validate your JSONPath queries!

## Usage Examples

> **Quick Testing:**  
> For rapid hands-on evaluation, see the attached example files (`examples/example1.txt` and `examples/example2.txt`).  
> These contain ready-to-copy Apex code blocks for Execute Anonymous windows, allowing you to quickly test JSONPath queries and verify library functionality in your Salesforce org.  
> **Important:** Run each test block individually to avoid hitting governor limits (see comments in the files for details).

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
    {"name": "A", "price": "12.99"},
    {"name": "B", "price": 12.99},
    {"name": "C", "price": 8}
  ]
}';

JSONPath jp = new JSONPath(json);
List<Object> result = jp.selectPath('$.items[?(@.price >= 12.99)]');
// Correctly matches both items with price >= 12.99
```

## More Usage Examples

Find a series of examples to get you started with `apex-jpath`. All examples will use the following sample JSON, which represents a simple data structure for a fictional online store.

### Sample JSON

```json
{
  "store": {
    "name": "The Awesome Store",
    "location": {
      "city": "San Francisco",
      "state": "CA"
    },
    "products": [
      {
        "id": 1,
        "name": "Laptop",
        "price": 1200,
        "tags": ["electronics", "computers"],
        "inStock": true
      },
      {
        "id": 2,
        "name": "Mouse",
        "price": 25,
        "tags": ["electronics", "accessories"],
        "inStock": true
      },
      {
        "id": 3,
        "name": "Book",
        "price": 15.5,
        "tags": ["reading", "education"],
        "inStock": false
      }
    ]
  }
}
```

### Basic Usage

These examples cover the most common use cases for accessing data.

#### 1. Accessing a Top-Level Property

To get the name of the store.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

String storeName = (String) path.select('store.name');
// Extracts the store's name: "The Awesome Store"
```

#### 2. Accessing a Nested Property

To get the city where the store is located.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

String city = (String) path.select('store.location.city');
// Extracts the city: "San Francisco"
```

#### 3. Accessing an Element in an Array by Index

To get the first product in the `products` array. Note that the result will be a `Map<String, Object>` representing the JSON object.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

Map<String, Object> firstProduct = (Map<String, Object>) path.select('store.products[0]');
// Retrieves the first product object from the array.

System.assertEquals(1, firstProduct.get('id'));
System.assertEquals('Laptop', firstProduct.get('name'));
```

#### 4. Accessing a Specific Property of an Array Element

To get the name of the second product.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

String secondProductName = (String) path.select('store.products[1].name');
// Gets the name of the second product: "Mouse"
```

### Intermediate Usage

These examples show how to work with collections of data.

#### 5. Getting a List of a Specific Property from an Array of Objects

To get a list of all product names.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

List<Object> productNames = (List<Object>) path.select('store.products[*].name');
// Returns a list of all product names: ["Laptop", "Mouse", "Book"]
```

#### 6. Retrieving an Entire Array

To get the full list of products.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

List<Object> allProducts = (List<Object>) path.select('store.products');
// Returns the entire list of product objects.

System.assertEquals(3, allProducts.size());
```

### Advanced Usage

These examples demonstrate the real power of `apex-jpath` by using filters to query for specific data.

#### 7. Filtering an Array to Find an Object by a Property Value

To find the product with the `id` of 3.

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

// Note that the filter returns a list of matching elements
List<Object> results = (List<Object>) path.select('store.products[?(@.id == 3)]');
// Finds the product object where the id is 3.

System.assertEquals(1, results.size());
Map<String, Object> book = (Map<String, Object>) results[0];
System.assertEquals('Book', book.get('name'));
System.assertEquals(15.50, book.get('price'));
```

#### 8. Filtering to Get a Property of a Matching Object

To get the price of the product named "Laptop".

**Apex Code:**

```apex
String jsonString = '...'; // Your JSON string here
JPath path = new JPath(jsonString);

List<Object> prices = (List<Object>) path.select('store.products[?(@.name == \'Laptop\')].price');
// Finds the price of the product named "Laptop": [1200]

Decimal laptopPrice = (Decimal) prices[0];
System.assertEquals(1, prices.size());
System.assertEquals(1200, laptopPrice);
```

#### 9. Filtering Based on a Boolean Property

To get the names of all products that are `inStock`.

**Apex Code:**

```apex
String jsonString = '...';
JPath path = new JPath(jsonString);

List<Object> inStockProducts = (List<Object>) path.select('store.products[?(@.inStock == true)].name');
// Returns the names of all products that are in stock: ["Laptop", "Mouse"]

System.assertEquals(new List<Object>{'Laptop', 'Mouse'}, inStockProducts);
```

#### 10. Filtering Based on "Greater Than" or "Less Than"

To get the names of all products with a price greater than 30.

**Apex Code:**

```apex
String jsonString = '...';
JPath path = new JPath(jsonString);

List<Object> expensiveProducts = (List<Object>) path.select('store.products[?(@.price > 30)].name');
// Gets the names of products with a price greater than 30: ["Laptop"]

System.assertEquals(new List<Object>{'Laptop'}, expensiveProducts);
```

## How?

- **JSONPath**: Main class for querying JSON data
- **JSONPathException**: Custom exception class for JSONPath-related errors
- **JSONPathTest**: Comprehensive test suite demonstrating usage

## Supported Operations

| Operation         | Syntax                    | Description                   |
| :---------------- | :------------------------ | :---------------------------- |
| Property Access   | `$.property`              | Access object property        |
| Array Indexing    | `$.array[0]`              | Access array element by index |
| Wildcard          | `$.array[*]`              | Select all elements           |
| Filter            | `$.array[?(@.prop > 10)]` | Filter elements               |
| Recursive Descent | `$..property`             | Find property at any level    |
| Slice             | `$.array[0:2]`            | Extract slice of array        |

## Limitations and Design Choices

This library is intentionally focused on the most common and essential JSONPath features that are safe and performant on the Salesforce platform. **This Apex version deliberately omits the following complex and platform-problematic features**:

**1. Script Expressions `(...)` and `eval()`**

- **What it is:** The original JSONPath proposal allowed for arbitrary script expressions (typically JavaScript) to be evaluated within brackets, like `$.store.book[(@.length-1)]` to get the last book, or `$.store.book[?(@.price > 10 && @.category === 'fiction')]`.
- **Why it's omitted:**
  - **Security Risk:** Executing arbitrary script expressions is equivalent to `eval()`, which is a massive security vulnerability. It is explicitly disallowed in Apex for this reason.
  - **Complexity:** Building a safe and efficient expression parser and evaluator from scratch in Apex is a monumental task that would make the library incredibly large and slow.

**2. Complex Filter Logic (`&&`, `||`, Grouping)**

- **What it is:** The ability to combine filter conditions, such as `[?(@.price < 10 && @.category == 'fiction')]`.
- **Why it's omitted:**
  - **Governor Limits:** A full-fledged logical expression parser can become very CPU-intensive, especially with nested logic and large arrays, posing a risk to Salesforce governor limits.
  - **Pragmatism:** While powerful, these queries can often be simplified. A developer can first filter by `[?(@.price < 10)]` and then use a simple Apex loop on the smaller result set to check the second condition (`category == 'fiction'`). This approach is more explicit and often safer from a performance standpoint.

**3. JSONPath Functions (`.length()`, `.avg()`, `.match()`, etc.)**

- **What it is:** The IETF RFC standardises functions that can be used within expressions, like `[?(@.title.length() > 10)]`.
- **Why it's omitted:**
  - **Implementation Complexity:** Each function would require custom logic to implement. Like complex filters, this adds significant overhead and potential performance issues. The logic for a function like `.match()` (regex matching) would be particularly complex in Apex.

**4. Accessing the Root (`$`) within Filters**

- **What it is:** The ability to compare an item against a value from the root of the document, like `[?(@.price > $.expensive)]`.
- **Why it's omitted:** The current simple filter parser is not designed to handle expressions that break out of the current context (`@`). Supporting this would require a more sophisticated evaluation engine that maintains a reference to the root node throughout the filter evaluation process.

By omitting features that rely on `eval()` or require highly complex, CPU-intensive parsing, the library remains secure and efficient, staying well within governor limits for all reasonable use cases. It provides a massive leap in functionality over parsing JSON manually with `JSON.deserializeUntyped` and nested loops, while avoiding the advanced edge cases that offer diminishing returns for their immense implementation cost and risk.

## Testing

Run all tests using:

```bash
sf force:apex:test:run -t JSONPathTest
```

<img width="843" height="547" alt="Screenshot 2025-10-04 at 16 42 10" src="https://github.com/user-attachments/assets/3c1601c8-717b-45a7-95db-fb8021c408c2" />

## License

MIT License

## Contributing

1.  Fork the repository
2.  Create a feature branch
3.  Commit your changes
4.  Push to the branch
5.  Create a Pull Request

## Support

Questions and feature requests? Please use the [Discussions tab](https://github.com/e3mandle6n1/apex-jpath/discussions). For bugs, open an issue.

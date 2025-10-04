# Salesforce Apex JPath Library

A native Apex implementation of JSONPath for querying JSON data in Salesforce applications.

## Overview

This library provides JSONPath functionality directly within Apex, allowing developers to query and filter JSON data using familiar JSONPath expressions. It's designed specifically for Salesforce environments and supports common JSONPath operations including:

-   Property access (`.property`)
-   Array indexing (`[0]`, `[-1]`)
-   Wildcard matching (`[*]`)
-   Filter expressions (`[?(@.property > 10)]`)
-   Recursive descent (`..property`)
-   Slice operations (`[0:2]`)

## Features

-   **Native Apex Implementation**: Pure Apex code with no external dependencies
-   **Full JSONPath Support**: Implements core JSONPath specification with Salesforce-specific enhancements
-   **Type Safety**: Robust type handling with automatic conversion between numeric types
-   **Filter Expressions**: Complex filtering with comparison operators and logical conditions
-   **Error Handling**: Comprehensive exception handling with descriptive error messages
-   **Performance Optimized**: Efficient parsing and evaluation of JSONPath expressions

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

## Usage Examples

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

## Key Classes

-   **JSONPath**: Main class for querying JSON data
-   **JSONPathException**: Custom exception class for JSONPath-related errors
-   **JSONPathTest**: Comprehensive test suite demonstrating usage

## Supported Operations

| Operation | Syntax | Description |
| :--- | :--- | :--- |
| Property Access | `$.property` | Access object property |
| Array Indexing | `$.array[0]` | Access array element by index |
| Wildcard | `$.array[*]` | Select all elements |
| Filter | `$.array[?(@.prop > 10)]` | Filter elements |
| Recursive Descent | `$..property` | Find property at any level |
| Slice | `$.array[0:2]` | Extract slice of array |

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

For issues and feature requests, please open an issue on the GitHub repository.

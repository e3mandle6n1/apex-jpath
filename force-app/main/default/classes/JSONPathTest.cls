/**
 * @name JSONPathTest
 * @version 0.2
 * @author Emandleni M
 * @description Test class for a native Apex implementation of JSONPath.
 */

 @isTest
private with sharing class JSONPathTest {

    private static final String TEST_JSON = '{' +
    '  "store": {' +
    '    "book": [' +
    '      { "category": "reference", "author": "Nigel Rees", "title": "Sayings of the Century", "price": 8.95 },' +
    '      { "category": "fiction", "author": "Evelyn Waugh", "title": "Sword of Honour", "price": 12.99 },' +
    '      { "category": "fiction", "author": "Herman Melville", "title": "Moby Dick", "isbn": "0-553-21311-3", "price": 8.99 },' +
    '      { "category": "fiction", "author": "J. R. R. Tolkien", "title": "The Lord of the Rings", "isbn": "0-395-19395-8", "price": 22.99 }' +
    '    ],' +
    '    "bicycle": { "color": "red", "price": 19.95 }' +
    '  },' +
    '  "tags": ["fiction", "classic", "epic", "adventure"]' +
    '}';

    // =========================================================================
    // Constructor and Input Validation Tests
    // =========================================================================

    @isTest
    static void testConstructor_Validations() {
        JSONPath jp = new JSONPath('{}');
        // Assert.areNotEqual(unexpected, actual, message) -> 3 arguments
        Assert.areNotEqual(null, jp, 'JSONPath object should not be null after creation with valid JSON.');
        
        try { 
            new JSONPath(null); 
            // Assert.areEqual(expected, actual, message) for forced failure -> 3 arguments
            Assert.areEqual(false, true, 'Expected JSONPathException for null JSON string.'); 
        } catch (JSONPathException e) { 
            Assert.areEqual('JSON string cannot be null or empty.', e.getMessage(), 'Incorrect exception message for null JSON string.'); 
        }
        
        try { 
            new JSONPath(''); 
            Assert.areEqual(false, true, 'Expected JSONPathException for empty JSON string.'); 
        } catch (JSONPathException e) { 
            Assert.areEqual('JSON string cannot be null or empty.', e.getMessage(), 'Incorrect exception message for empty JSON string.'); 
        }
        
        try { 
            new JSONPath('{bad json}'); 
            Assert.areEqual(false, true, 'Expected JSONPathException for malformed JSON string.'); 
        } catch (JSONPathException e) { 
            // Boolean check asserted against true/false to maintain the 3-argument pattern (expected, actual, message)
            Assert.areEqual(true, e.getMessage().contains('Failed to parse'), 'Exception message should indicate a parsing failure for bad JSON.'); 
        }
    }

    @isTest
    static void testSelectPath_PathValidations() {
        JSONPath jp = new JSONPath('{}');
        try { 
            jp.selectPath(null); 
            Assert.areEqual(false, true, 'Expected JSONPathException for null path.'); 
        } catch (JSONPathException e) { 
            Assert.areEqual('Path must start with the root element "$".', e.getMessage(), 'Incorrect exception message for null path.'); 
        }
        try { 
            jp.selectPath('store.book'); 
            Assert.areEqual(false, true, 'Expected JSONPathException for path not starting with $.'); 
        } catch (JSONPathException e) { 
            Assert.areEqual('Path must start with the root element "$".', e.getMessage(), 'Incorrect exception message for path not starting with $.'); 
        }
        List<Object> rootResult = jp.selectPath('$');
        Assert.areEqual(1, rootResult.size(), 'Root path "$" should return exactly one result (the root object).');
    }

    // =========================================================================
    // Operator Tests
    // =========================================================================

    @isTest
    static void testProcessPropertyAndIndex() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Access first and last book via index then property segment to avoid direct list deref when empty
        List<Object> firstAuthor = jp.selectPath('$.store.book[0].author');
        Assert.areEqual(1, firstAuthor.size(), 'Expected first author to be found');
        Assert.areEqual('Nigel Rees', (String) firstAuthor[0], 'First author name incorrect.');

        List<Object> lastAuthor = jp.selectPath('$.store.book[-1].author');
        Assert.areEqual(1, lastAuthor.size(), 'Expected last author to be found');
        Assert.areEqual('J. R. R. Tolkien', (String) lastAuthor[0], 'Last author name incorrect.');

        // Test non-existent property and out of bounds index
        Assert.areEqual(0, jp.selectPath('$.store.car').size(), 'Non-existent property should return 0 results.');
        Assert.areEqual(0, jp.selectPath('$.store.book[99]').size(), 'Out of bounds index should return 0 results.');
    }

    @isTest
    static void testProcessWildcard() {
        JSONPath jp = new JSONPath(TEST_JSON);
        Assert.areEqual(4, jp.selectPath('$.store.book[*]').size(), 'Wildcard on book list should return 4 books.');
        Assert.areEqual(2, jp.selectPath('$.store.bicycle[*]').size(), 'Wildcard on bicycle object should return 2 properties.');
    }

    @isTest
    static void testRecursiveDescent() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // This test has been simplified as the new implementation is more direct
        List<Object> allPrices = jp.selectPath('$..price');
        Assert.areNotEqual(0, allPrices.size(), 'Check that some prices were found with recursive descent.'); 
        Assert.areEqual(5, allPrices.size(), 'Should find all 5 price properties using recursive descent.');

        List<Object> allAuthors = jp.selectPath('$..author');
        Assert.areEqual(4, allAuthors.size(), 'Should find all 4 authors using recursive descent.');
    }

    @isTest
    static void testNormalizePathAndUnion() {
        JSONPath jp = new JSONPath(TEST_JSON);
        List<Object> results = jp.selectPath('$.store["book"][0,2].author');
        Assert.areEqual(2, results.size(), 'Union of indices [0, 2] should return 2 authors.');
    }
    
    // =========================================================================
    // Edge Case Tests
    // =========================================================================

    @IsTest
    static void testRootOnlyReturnsSingleton() {
        JSONPath jp = new JSONPath(TEST_JSON);
        List<Object> root = jp.selectPath('$');
        Assert.areEqual(1, root.size(), 'Root-only path should return the root wrapped in a single-element list.');
    }

    @IsTest
    static void testNormalizationBracketVsDotEquivalence() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Dot notation
        List<Object> dot = jp.selectPath('$.store.book[0].author');
        // Bracket property notation
        List<Object> bracket = jp.selectPath('$["store"]["book"][0]["author"]');
        Assert.areEqual(1, dot.size(), 'Dot notation should find 1 result.');
        Assert.areEqual(1, bracket.size(), 'Bracket notation should find 1 result.');
        Assert.areEqual((String)dot[0], (String)bracket[0], 'Dot and bracket property access should be equivalent.');
    }

    @IsTest
    static void testUnionMixIndicesDeDup() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Mix of indices with potential duplicates; implementation uses a Set to de-duplicate.
        List<Object> u = jp.selectPath('$.store.book[0,2,2,0].title');
        Assert.areEqual(2, u.size(), 'Union should de-duplicate results.');
        
        Set<String> titles = new Set<String>{ (String)u[0], (String)u[1] };
        // Refactored boolean checks to use Assert.areEqual(expected, actual, message) -> 3 arguments
        Assert.areEqual(true, titles.contains('Sayings of the Century'), 'Union results should contain "Sayings of the Century".');
        Assert.areEqual(true, titles.contains('Moby Dick'), 'Union results should contain "Moby Dick".');
    }

    @IsTest
    static void testSliceBasicAndNegative() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Basic slice 1:3 => indices 1,2
        List<Object> s1 = jp.selectPath('$.store.book[1:3].author');
        Assert.areEqual(2, s1.size(), 'Basic slice [1:3] should yield 2 results.');
        
        Set<String> authors1 = new Set<String>{ (String)s1[0], (String)s1[1] };
        Assert.areEqual(true, authors1.contains('Evelyn Waugh'), 'Slice [1:3] results should contain "Evelyn Waugh".');
        Assert.areEqual(true, authors1.contains('Herman Melville'), 'Slice [1:3] results should contain "Herman Melville".');

        // Negative indices -3:-1 => indices 1 and 2
        List<Object> s2 = jp.selectPath('$.store.book[-3:-1].author');
        Assert.areEqual(2, s2.size(), 'Negative slice [-3:-1] should yield 2 results.');
        
        Set<String> authors2 = new Set<String>{ (String)s2[0], (String)s2[1] };
        Assert.areEqual(true, authors2.contains('Evelyn Waugh'), 'Slice [-3:-1] results should contain "Evelyn Waugh".');
        Assert.areEqual(true, authors2.contains('Herman Melville'), 'Slice [-3:-1] results should contain "Herman Melville".');
    }

    @IsTest
    static void testSliceStepAndZeroStepException() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Step 2
        List<Object> s = jp.selectPath('$.store.book[::2].title');
        Assert.areEqual(2, s.size(), 'Step 2 should yield indices 0 and 2 (2 titles).');

        // Zero step -> exception "Slice step cannot be zero."
        try {
            jp.selectPath('$.store.book[1:3:0]');
            Assert.areEqual(false, true, 'Expected JSONPathException due to zero step.'); // Forced failure
        } catch (JSONPathException e) {
            Assert.areEqual(true, e.getMessage().contains('Slice step cannot be zero.'), 'Exception message should contain "Slice step cannot be zero."');
        }
    }

    @IsTest
    static void testFilterNumericVsStringFallback() {
        // Craft data where numeric appears as a string for one item
        String json = '{' +
        '  "items": [' +
        '    { "name": "A", "price": "12.99" },' +  // string numeric
        '    { "name": "B", "price": 12.99 },' +    // numeric
        '    { "name": "C", "price": 8 }' +
        '  ]' +
        '}';
        JSONPath jp = new JSONPath(json);

        // Comparison operators attempt numeric conversion; string "12.99" will convert via Decimal.valueOf in convertToDecimal(String)
        Assert.areEqual(2, jp.selectPath('$.items[?(@.price >= 12.99)].name').size(), 'Two items should match price >= 12.99.');

        // Equality should also match both due to numeric parity
        Assert.areEqual(2, jp.selectPath('$.items[?(@.price == 12.99)].name').size(), 'Two items should match price == 12.99.');
    }
    
    // =========================================================================
    // Filter Tests
    // =========================================================================

    @isTest
    static void testFilters() {
        JSONPath jp = new JSONPath(TEST_JSON);
        
        // Existence
        Assert.areEqual(2, jp.selectPath('$.store.book[?(@.isbn)]').size(), 'Expected 2 books with an ISBN.');

        // Operators on numbers
        Assert.areEqual(2, jp.selectPath('$.store.book[?(@.price < 10)]').size(), 'Expected 2 books with price < 10.');
        Assert.areEqual(1, jp.selectPath('$.store.book[?(@.price > 20)]').size(), 'Expected 1 book with price > 20.');
        Assert.areEqual(1, jp.selectPath('$.store.book[?(@.price <= 8.95)]').size(), 'Expected 1 book with price <= 8.95.');
        Assert.areEqual(2, jp.selectPath('$.store.book[?(@.price >= 12.99)]').size(), 'Expected 2 books with price >= 12.99.');
        
        // Operators on strings (item is a Map<String,Object>)
        Assert.areEqual(1, jp.selectPath('$.store.book[?(@.author == "Nigel Rees")]').size(), 'Expected 1 book with author "Nigel Rees".');
        Assert.areEqual(3, jp.selectPath('$.store.book[?(@.author != "Nigel Rees")]').size(), 'Expected 3 books with author not "Nigel Rees".');
        
        // Non-matching filter and missing property
        Assert.areEqual(0, jp.selectPath('$.store.book[?(@.price > 100)]').size(), 'Expected 0 results for price > 100.');
        Assert.areEqual(0, jp.selectPath('$.store.book[?(@.nonexistent > 100)]').size(), 'Expected 0 results for non-existent property.');
    }

    @isTest
    static void testFiltersOnPrimitives() {
        // Current implementation filters only on lists of objects with @.field semantics.
        // Ensure that applying a filter to primitives yields empty results rather than errors.
        String primitiveJson = '{"data": ["value", "other", 123, 99]}';
        JSONPath jp = new JSONPath(primitiveJson);
        Assert.areEqual(0, jp.selectPath('$.data[?(@.foo == "value")]').size(), 'Filtering on primitives list should return 0 results.');
    }
}
/**
 * @name JSONPathTest
 * @version 0.1
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
        System.assertNotEquals(null, jp);
        try { new JSONPath(null); System.assert(false, 'Expected exception.'); } catch (JSONPathException e) { System.assertEquals('JSON string cannot be null or empty.', e.getMessage()); }
        try { new JSONPath(''); System.assert(false, 'Expected exception.'); } catch (JSONPathException e) { System.assertEquals('JSON string cannot be null or empty.', e.getMessage()); }
        try { new JSONPath('{bad json}'); System.assert(false, 'Expected exception.'); } catch (JSONPathException e) { System.assert(e.getMessage().contains('Failed to parse')); }
    }

    @isTest
    static void testSelectPath_PathValidations() {
        JSONPath jp = new JSONPath('{}');
        try { jp.selectPath(null); System.assert(false, 'Expected exception.'); } catch (JSONPathException e) { System.assertEquals('Path must start with the root element "$".', e.getMessage()); }
        try { jp.selectPath('store.book'); System.assert(false, 'Expected exception.'); } catch (JSONPathException e) { System.assertEquals('Path must start with the root element "$".', e.getMessage()); }
        List<Object> rootResult = jp.selectPath('$');
        System.assertEquals(1, rootResult.size());
    }

    // =========================================================================
    // Operator Tests
    // =========================================================================

    @isTest
    static void testProcessPropertyAndIndex() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Access first and last book via index then property segment to avoid direct list deref when empty
        List<Object> firstAuthor = jp.selectPath('$.store.book[0].author');
        System.assertEquals(1, firstAuthor.size(), 'Expected first author to be found');
        System.assertEquals('Nigel Rees', (String) firstAuthor[0]);

        List<Object> lastAuthor = jp.selectPath('$.store.book[-1].author');
        System.assertEquals(1, lastAuthor.size(), 'Expected last author to be found');
        System.assertEquals('J. R. R. Tolkien', (String) lastAuthor[0]);

        // Test non-existent property and out of bounds index
        System.assertEquals(0, jp.selectPath('$.store.car').size());
        System.assertEquals(0, jp.selectPath('$.store.book[99]').size());
    }

    @isTest
    static void testProcessWildcard() {
        JSONPath jp = new JSONPath(TEST_JSON);
        System.assertEquals(4, jp.selectPath('$.store.book[*]').size());
        System.assertEquals(2, jp.selectPath('$.store.bicycle[*]').size());
    }

    @isTest
    static void testRecursiveDescent() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // This test has been simplified as the new implementation is more direct
        List<Object> allPrices = jp.selectPath('$..price');
        System.assertNotEquals(0, allPrices.size()); // Check that some prices were found
        System.assertEquals(5, allPrices.size(), 'Should find all 5 price properties.');

        List<Object> allAuthors = jp.selectPath('$..author');
        System.assertEquals(4, allAuthors.size(), 'Should find all 4 authors.');
    }

    @isTest
    static void testNormalizePathAndUnion() {
        JSONPath jp = new JSONPath(TEST_JSON);
        List<Object> results = jp.selectPath('$.store["book"][0,2].author');
        System.assertEquals(2, results.size());
    }
    
    // =========================================================================
    // Edge Case Tests
    // =========================================================================

    @IsTest
    static void testRootOnlyReturnsSingleton() {
        JSONPath jp = new JSONPath(TEST_JSON);
        List<Object> root = jp.selectPath('$');
        System.assertEquals(1, root.size(), 'Root-only path should return the root wrapped in a single-element list.');
    }

    @IsTest
    static void testNormalizationBracketVsDotEquivalence() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Dot notation
        List<Object> dot = jp.selectPath('$.store.book[0].author');
        // Bracket property notation
        List<Object> bracket = jp.selectPath('$["store"]["book"][0]["author"]');
        System.assertEquals(1, dot.size());
        System.assertEquals(1, bracket.size());
        System.assertEquals((String)dot[0], (String)bracket[0], 'Dot and bracket property access should be equivalent.');
    }

    @IsTest
    static void testUnionMixIndicesDeDup() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Mix of indices with potential duplicates; implementation uses a Set to de-duplicate.
        List<Object> u = jp.selectPath('$.store.book[0,2,2,0].title');
        System.assertEquals(2, u.size(), 'Union should de-duplicate results.');
        System.assert(new Set<String>{ (String)u[0], (String)u[1] }.contains('Sayings of the Century'));
        System.assert(new Set<String>{ (String)u[0], (String)u[1] }.contains('Moby Dick'));
    }

    @IsTest
    static void testSliceBasicAndNegative() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Basic slice 1:3 => indices 1,2
        List<Object> s1 = jp.selectPath('$.store.book[1:3].author');
        System.assertEquals(2, s1.size());
        System.assert(new Set<String>{ (String)s1[0], (String)s1[1] }.contains('Evelyn Waugh'));
        System.assert(new Set<String>{ (String)s1[0], (String)s1[1] }.contains('Herman Melville'));

        // Negative indices -3:-1 => indices 1 and 2
        List<Object> s2 = jp.selectPath('$.store.book[-3:-1].author');
        System.assertEquals(2, s2.size());
        System.assert(new Set<String>{ (String)s2[0], (String)s2[1] }.contains('Evelyn Waugh'));
        System.assert(new Set<String>{ (String)s2[0], (String)s2[1] }.contains('Herman Melville'));
    }

    @IsTest
    static void testSliceStepAndZeroStepException() {
        JSONPath jp = new JSONPath(TEST_JSON);
        // Step 2
        List<Object> s = jp.selectPath('$.store.book[::2].title');
        System.assertEquals(2, s.size(), 'Step 2 should yield indices 0 and 2');

        // Zero step -> exception "Slice step cannot be zero."
        try {
            jp.selectPath('$.store.book[1:3:0]');
            System.assert(false, 'Expected JSONPathException due to zero step.');
        } catch (JSONPathException e) {
            System.assert(e.getMessage().contains('Slice step cannot be zero.'));
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
        System.assertEquals(2, jp.selectPath('$.items[?(@.price >= 12.99)].name').size(), 'Two items with price >= 12.99');

        // Equality should also match both due to numeric parity
        System.assertEquals(2, jp.selectPath('$.items[?(@.price == 12.99)].name').size());
    }
    
    // =========================================================================
    // Filter Tests
    // =========================================================================

    @isTest
    static void testFilters() {
        JSONPath jp = new JSONPath(TEST_JSON);
        
        // Existence
        System.assertEquals(2, jp.selectPath('$.store.book[?(@.isbn)]').size());

        // Operators on numbers
        System.assertEquals(2, jp.selectPath('$.store.book[?(@.price < 10)]').size());
        System.assertEquals(1, jp.selectPath('$.store.book[?(@.price > 20)]').size());
        System.assertEquals(1, jp.selectPath('$.store.book[?(@.price <= 8.95)]').size());
        System.assertEquals(2, jp.selectPath('$.store.book[?(@.price >= 12.99)]').size());
        
        // Operators on strings (item is a Map<String,Object>)
        System.assertEquals(1, jp.selectPath('$.store.book[?(@.author == "Nigel Rees")]').size());
        System.assertEquals(3, jp.selectPath('$.store.book[?(@.author != "Nigel Rees")]').size());
        
        // Non-matching filter and missing property
        System.assertEquals(0, jp.selectPath('$.store.book[?(@.price > 100)]').size());
        System.assertEquals(0, jp.selectPath('$.store.book[?(@.nonexistent > 100)]').size());
    }

    @isTest
    static void testFiltersOnPrimitives() {
        // Current implementation filters only on lists of objects with @.field semantics.
        // Ensure that applying a filter to primitives yields empty results rather than errors.
        String primitiveJson = '{"data": ["value", "other", 123, 99]}';
        JSONPath jp = new JSONPath(primitiveJson);
        System.assertEquals(0, jp.selectPath('$.data[?(@.foo == "value")]').size());
    }
}

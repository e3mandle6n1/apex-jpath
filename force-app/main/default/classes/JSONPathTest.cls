/**
 * @name JSONPathTest
 * @version 1.2
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
        // Test property and index which are now unified
        System.assertEquals('Nigel Rees', ((Map<String, Object>)jp.selectPath('$.store.book[0]')[0]).get('author'));
        System.assertEquals('J. R. R. Tolkien', ((Map<String, Object>)jp.selectPath('$.store.book[-1]')[0]).get('author'));
        
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
        
        // Operators on strings
        System.assertEquals(1, jp.selectPath('$.store.book[?(@.author == "Nigel Rees")]').size());
        System.assertEquals(3, jp.selectPath('$.store.book[?(@.author != "Nigel Rees")]').size());
        
        // Non-matching filter and bad filter format
        System.assertEquals(0, jp.selectPath('$.store.book[?(@.price > 100)]').size());
        System.assertEquals(0, jp.selectPath('$.store.book[?(@.nonexistent > 100)]').size());
    }

    @isTest
    static void testFiltersOnPrimitives() {
        String primitiveJson = '{"data": ["value", "other", 123, 99]}';
        JSONPath jp = new JSONPath(primitiveJson);

        System.assertEquals(1, jp.selectPath('$.data[?(@ == "value")]').size());
        System.assertEquals(1, jp.selectPath('$.data[?(@ > 100)]').size());
        System.assertEquals(2, jp.selectPath('$.data[?(@ != "value")]').size()); // 'other', 123, 99 (numeric converted to string for !=)
    }
    
    // =========================================================================
    // Exception Class Coverage
    // =========================================================================

    @isTest
    static void testExceptionClass() {
        // Cover both constructors of the exception class
        Exception e1 = new JSONPathException();
        System.assertEquals(null, e1.getMessage());

        Exception e2 = new JSONPathException('test message');
        System.assertEquals('test message', e2.getMessage());
    }
}
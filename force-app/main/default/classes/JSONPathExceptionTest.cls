/**
 * @name JSONPathExceptionTest
 * @version 0.1
 * @author Emandleni M
 * @description Custom exception test class for JSONPath processing errors. Tests if appropriate errors are thrown when the JSON string is invalid or the JSONPath expression is malformed.
 */

@isTest
public with sharing class JSONPathExceptionTest {
    @isTest
    static void testExceptionClass() {
        Exception e1 = new JSONPathException();
        System.assertNotEquals(null, e1.getMessage());

        Exception e2 = new JSONPathException('test message');
        System.assertEquals('test message', e2.getMessage());
    }
}
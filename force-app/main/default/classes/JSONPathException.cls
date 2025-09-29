/**
 * @name JSONPathException
 * @version 1.0
 * @author Emandleni M
 * @description Custom exception for JSONPath processing errors. Thrown when the JSON string is invalid
 * or the JSONPath expression is malformed.
 * 
 */
public with sharing class JSONPathException extends Exception {
    public JSONPathException(String message) {
        super(message);
    }
    
    public JSONPathException(String message, Exception cause) {
        super(message + ' Caused by: ' + cause.getMessage());
    }
}
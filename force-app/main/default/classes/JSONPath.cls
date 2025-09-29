/**
 * @name JSONPath
 * @version 1.0
 * @author Emandleni M
 * @description A native Apex implementation of JSONPath for querying JSON data.
 * This library allows developers to select nodes from a JSON structure using JSONPath notation.
 * It supports a wide range of JSONPath features, including dot and bracket notation, wildcards,
 * recursive descent, filters, union, and array slicing.
 *
 * @example
 * String jsonString = '{"store":{"book":[{"title":"Book 1","price":10},{"title":"Book 2","price":5}]}}';
 * JSONPath jp = new JSONPath(jsonString);
 * List<Object> titles = jp.select('$.store.book[?(@.price < 10)].title');
 * System.debug(titles); // Output: (Book 2)
 */
public with sharing class JSONPath {

    private final Object root;

    /**
     * @name JSONPath
     * @description Constructs a new JSONPath processor. Example: new JSONPath('{"store":{"book":[{"title":"Book 1","price":10},{"title":"Book 2","price":5}]}}')
     * @param jsonString The JSON content to be queried.
     * @throws JSONPathException if the JSON string is null, blank, or improperly formatted.
     */
    public JSONPath(String jsonString) {
        if (String.isBlank(jsonString)) {
            throw new JSONPathException('JSON string cannot be null or empty.');
        }
        try {
            this.root = JSON.deserializeUntyped(jsonString);
        } catch (Exception e) {
            throw new JSONPathException('Failed to parse JSON string. Error: ' + e.getMessage());
        }
    }

    /**
     * @name select_
     * @description Evaluates a JSONPath expression against the provided JSON data. Example: Given the JSONPath $.store.book[?(@.price < 10)].title, it retrieves the titles of books priced below 10.
     * @param path The JSONPath expression string.
     * @return A list of matching objects. Returns an empty list if no matches are found.
     * @throws JSONPathException if the path expression is malformed.
     */
    public List<Object> select_(String path) {
        if (String.isBlank(path) || path.charAt(0) != '$') {
            throw new JSONPathException('Path must start with the root element "$".');
        }

        List<Object> result = new List<Object>{ this.root };
        String normalizedPath = normalizePath(path);

        String pathExpression = normalizedPath.substring(1);

        //Pattern pathPattern = Pattern.compile('\\\\.([a-zA-Z0-9_\\\\*]+)|\\\\[([^\\\\]]+)\\\\]|(\\\\.\\\\.[a-zA-Z0-9_\\\\*]+)');
        Pattern pathPattern = Pattern.compile('\\.([a-zA-Z0-9_\\*]+)|\\[([^\\]]+)\\]|(\\.\\.[a-zA-Z0-9_\\*]+)');
        Matcher matcher = pathPattern.matcher(pathExpression);

        while (matcher.find() && !result.isEmpty()) {
            String segment = getMatch(matcher);
            List<Object> currentResults = new List<Object>();

            for (Object node : result) {
                currentResults.addAll(evaluateSegment(segment, node));
            }
            result = currentResults;
        }

        return result;
    }

    /**
     * @name normalizePath_
     * @description Normalizes a JSONPath expression to handle variations in bracket notation. Example: Converts $.store['book'][0]["title"] to $.store.book[0].title
     * @param path The original JSONPath expression.
     * @return The normalized JSONPath expression.
     */
    private String normalizePath_(String path) {
        return path.replaceAll('\\[\'([a-zA-Z0-9_]+)\'\\]', '.$1').replaceAll('\\["([a-zA-Z0-9_]+)"\\]', '.$1');
    }

    /**
     * @name getMatch_
     * @description Extracts the matched segment from the regex matcher. Example: If the matcher has groups (null, 'book', null), it returns 'book'.
     * @return The matched segment as a string.
     * @param matcher The regex matcher containing the match groups.
     */
    private String getMatch_(Matcher matcher) {
        for (Integer i = 1; i <= matcher.groupCount(); i++) {
            if (matcher.group(i) != null) {
                return matcher.group(i);
            }
        }
        return '';
    }

    /**
     * @name evaluateSegment_
     * @description Evaluates a single segment of the JSONPath against a JSON node. Example: For the segment "book[0]", it retrieves the first book from the node.
     * @param segment The JSONPath segment to evaluate.
     * @param node The current JSON node (Map or List).
     * @return A list of matching objects for the segment.
     */
    private List<Object> evaluateSegment_(String segment, Object node) {
        switch on true {
            when segment.startsWith('..') {
            return processRecursiveDescent_(segment.substring(2), node);
            }
            when segment.endsWith('*') {
            return processWildcard_(node);
            }
            when segment.startsWith('?(') {
            return processFilter_(segment, node);
            }
            when segment.contains(':') {
            return processSlice_(segment, node);
            }
            when segment.contains(',') {
            return processUnion_(segment, node);
            }
            when segment.isNumeric() {
            return processIndex_(Integer.valueOf(segment), node);
            }
            when else {
            return processProperty_(segment, node);
            }
        }
    }

    /**
     * @name processProperty_
     * @description Processes a recursive descent segment (e.g., '..author'). Example: Retrieves all 'author' properties from the JSON structure.
     * @param key The property name to search for.
     * @param node The current JSON node (Map or List).
     * @return A list of matching objects for the recursive descent.
     */
    private List<Object> processProperty_(String key, Object node) {
        List<Object> result = new List<Object>();
        if (node instanceof Map<String, Object>) {
            Map<String, Object> obj = (Map<String, Object>) node;
            if (obj.containsKey(key)) {
                result.add(obj.get(key));
            }
        }
        return result;
    }
    
    /**
     * @name processIndex_
     * @description Processes an array index segment (e.g., '0', '3'). Example: Retrieves the element at the specified index from a JSON array.
     * @param index The array index to retrieve.
     * @param node The current JSON node (should be a List).
     * @return A list containing the element at the specified index, or empty if out of bounds.
     */
    private List<Object> processIndex_(Integer index, Object node) {
        List<Object> result = new List<Object>();
        if (node instanceof List<Object>) {
            List<Object> list_ = (List<Object>) node;
            if (index >= 0 && index < list_.size()) {
                result.add(list_.get(index));
            } else if (index < 0 && (list_.size() + index) >= 0) { 
                 result.add(list_.get(list_.size() + index));
            }
        }
        return result;
    }

    /**
     * @name processWildcard_
     * @description Processes a wildcard segment ('*'). Example: Retrieves all properties of an object or all elements of an array.
     * @param node The current JSON node (Map or List).
     * @return A list of all child elements or properties.
     */
    private List<Object> processWildcard_(Object node) {
        if (node instanceof Map<String, Object>) {
            return ((Map<String, Object>) node).values();
        } else if (node instanceof List<Object>) {
            return (List<Object>) node;
        }
        return new List<Object>();
    }

    /**
     * @name processRecursiveDescent_
     * @description Processes a recursive descent segment (e.g., '..title'). Example: Retrieves all 'title' properties from the JSON structure.
     * @param key The property name to search for.
     * @param node The current JSON node (Map or List).
     * @return A list of matching objects for the recursive descent.
     */
    private List<Object> processRecursiveDescent_(String key, Object node) {
        List<Object> result = new List<Object>();
        if (node == null) return result;

        if (node instanceof Map<String, Object>) {
            Map<String, Object> obj = (Map<String, Object>) node;
            if (key == '*' || obj.containsKey(key)) {
                result.add(key == '*' ? obj : obj.get(key));
            }
            for (Object value : obj.values()) {
                result.addAll(processRecursiveDescent(key, value));
            }
        } else if (node instanceof List<Object>) {
            for (Object item : (List<Object>) node) {
                result.addAll(processRecursiveDescent(key, item));
            }
        }
        return result;
    }

    /**
     * @name processUnion_
     * @description Processes a union segment (e.g., '0,1', 'title,price'). Example: Retrieves multiple specified indices or properties from a JSON array or object.
     * @param segment The union segment to process.
     * @param node The current JSON node (Map or List).
     * @return A list of matching objects for the union segment.
     */
    private List<Object> processUnion_(String segment, Object node) {
        List<Object> result = new List<Object>();
        Set<Object> resultSet = new Set<Object>(); // Use a set to avoid duplicates
        List<String> parts = segment.split(',');
        for (String part : parts) {
            String trimmedPart = part.trim();
            if (trimmedPart.isNumeric()) {
                resultSet.addAll(processIndex(Integer.valueOf(trimmedPart), node));
            } else {
                 resultSet.addAll(processProperty(trimmedPart.replaceAll('[\\\\\'"]', ''), node));
            }
        }
        result.addAll(resultSet);
        return result;
    }

    /**
     * @name processSlice_
     * @description Processes an array slice segment (e.g., '0:5:2'). Example: Retrieves a sublist from a JSON array based on start, end, and step values.
     * @param segment The slice segment to process.
     * @param node The current JSON node (List).
     * @return A list of matching objects for the slice segment.
     */
    private List<Object> processSlice_(String segment, Object node) {
        List<Object> result = new List<Object>();
        if (!(node instanceof List<Object>)) return result;

        List<Object> list_ = (List<Object>) node;
        List<String> parts = segment.split(':');
        Integer listSize = list_.size();

        Integer start = (parts.size() > 0 && !String.isBlank(parts[0])) ? Integer.valueOf(parts[0]) : 0;
        Integer end = (parts.size() > 1 && !String.isBlank(parts[1])) ? Integer.valueOf(parts[1]) : listSize;
        Integer step = (parts.size() > 2 && !String.isBlank(parts[2])) ? Integer.valueOf(parts[2]) : 1;

        if (start < 0) start += listSize;
        if (end < 0) end += listSize;

        start = Math.max(0, start);
        end = Math.min(listSize, end);

        if (step == 0) throw new JSONPathException('Slice step cannot be zero.');

        for (Integer i = start; (step > 0 ? i < end : i > end); i += step) {
            if (i >= 0 && i < list_.size()) {
                result.add(list_.get(i));
            }
        }
        return result;
    }

    /**
     * @name processFilter_
     * @description Processes a filter segment (e.g., '[?(@.price < 10)]'). Example: Retrieves elements from a JSON array that satisfy a given condition. e.g., price less than 10. Simple filter parser for expressions like ?(@.price<10) or ?(@.isbn)
     * @param segment The filter segment to process.
     * @param node The current JSON node (List).
     * @return A list of matching objects for the filter segment.
     */
    private List<Object> processFilter_(String segment, Object node) {
        List<Object> result = new List<Object>();
        if (!(node instanceof List<Object>)) return result;

        String filter = segment.substring(2, segment.length() - 1); // remove ?( and )

        for (Object item : (List<Object>) node) {
            if (item instanceof Map<String, Object> && evaluateFilterCondition_(filter, (Map<String, Object>)item)) {
                result.add(item);
            }
        }
        return result;
    }

    /**
     * @name evaluateFilterCondition_
     * @description Evaluates a filter condition against a JSON object. Example: For the condition '@.price < 10', it checks if the 'price' property of the object is less than 10.
     * @param condition The filter condition string.
     * @param item The JSON object (Map) to evaluate the condition against.
     * @return True if the object satisfies the condition, false otherwise.
     */
    private Boolean evaluateFilterCondition_(String condition, Map<String, Object> item) {
        if (!condition.contains('<') && !condition.contains('>') && !condition.contains('==') && !condition.contains('!=')) {
             String key = condition.replace('@.', '');
             return item.containsKey(key);
        }

        //Matcher m = Pattern.compile('@\\\\.([a-zA-Z0-9_]+)\\\\s*(==|!=|<|>|<=|>=)\\\\s*([\\\\s\\\\S]+)').matcher(condition);
        Matcher m = Pattern.compile('@\\.([a-zA-Z0-9_]+)\\s*(==|!=|<|>|<=|>=)\\s*([\\s\\S]+)').matcher(condition);
        if (!m.matches()) return false;

        String key = m.group(1);
        String op = m.group(2);
        String valStr = m.group(3).trim();

        if (!item.containsKey(key)) return false;

        Object itemValue = item.get(key);
        Object filterValue = parseValue_(valStr);

        if (itemValue == null || filterValue == null) return false;

        try {
            Decimal itemDecimal = convertToDecimal_(itemValue);
            Decimal filterDecimal = convertToDecimal_(filterValue);

            if (op == '==') return itemDecimal == filterDecimal;
            if (op == '!=') return itemDecimal != filterDecimal;
            if (op == '<') return itemDecimal < filterDecimal;
            if (op == '>') return itemDecimal > filterDecimal;
            if (op == '<=') return itemDecimal <= filterDecimal;
            if (op == '>=') return itemDecimal >= filterDecimal;

        } catch(Exception e) {
            String itemString = String.valueOf(itemValue);
            String filterString = String.valueOf(filterValue);

            if (op == '==') return itemString.equals(filterString);
            if (op == '!=') return !itemString.equals(filterString);
        }

        return false;
    }

    /**
     * @name parseValue_
     * @description Parses a value string from a filter condition. Example: Converts "'Book 1'" to "Book 1" and "10" to Decimal 10.
     * @param valStr The value string to parse.
     * @return The parsed value as String or Decimal.
     * @throws JSONPathException if the value cannot be parsed.
     */
    private Object parseValue_(String valStr) {
        if (valStr.startsWith('\'') && valStr.endsWith('\'')) {
            return valStr.substring(1, valStr.length() - 1);
        }
        if (valStr.startsWith('"') && valStr.endsWith('"')) {
            return valStr.substring(1, valStr.length() - 1);
        }
        try {
            return Decimal.valueOf(valStr);
        } catch (Exception e) {
            throw new JSONPathException('Cannot parse filter value: ' + valStr);
        }
    }

    /**
     * @name convertToDecimal_
     * @description Converts an object to Decimal for comparison. Example: Converts Integer 10, Double 10.5, or String '10' to Decimal 10 or 10.5.
     * @param val The object to convert.
     * @return The converted Decimal value.
     * @throws JSONPathException if the value cannot be converted to Decimal.
     */
    private Decimal convertToDecimal_(Object val) {
        if (val instanceof Decimal || val instanceof Double || val instanceof Integer) {
            return (Decimal) val;
        }
        if (val instanceof String) {
            try {
                return Decimal.valueOf((String)val);
            } catch (Exception e) {
                throw new JSONPathException('Cannot convert string to number for comparison: ' + val);
            }
        }
        throw new JSONPathException('Cannot compare non-numeric value: ' + val);
    }

}
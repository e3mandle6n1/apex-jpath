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

        Pattern pathPattern = Pattern.compile('\\\\.([a-zA-Z0-9_\\\\*]+)|\\\\[([^\\\\]]+)\\\\]|(\\\\.\\\\.[a-zA-Z0-9_\\\\*]+)');
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
     * @return The normalized JSONPath expression.
     * @param path The original JSONPath expression.
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
     * @return A list of matching objects for the segment.
     * @param segment The JSONPath segment to evaluate.
     * @param node The current JSON node (Map or List).
     */
    private List<Object> evaluateSegment_(String segment, Object node) {
        if (segment.startsWith('..')) {
            return processRecursiveDescent(segment.substring(2), node);
        } else if (segment.endsWith('*')) {
            return processWildcard(node);
        } else if (segment.startsWith('?(')) {
            return processFilter(segment, node);
        } else if (segment.contains(':')) {
            return processSlice(segment, node);
        } else if (segment.contains(',')) {
            return processUnion(segment, node);
        } else if (segment.isNumeric()) {
            return processIndex(Integer.valueOf(segment), node);
        } else { 
            return processProperty(segment, node);
        }
    }

    
}
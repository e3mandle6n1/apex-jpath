/**
 * @name JSONPath
 * @version 1.2
 * @author Emandleni M
 * @description A native Apex implementation of JSONPath for querying JSON data.
 */
public with sharing class JSONPath {

    private final Object root;

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
    
    // FIX: Renamed method to avoid trailing underscore. Let's call it selectPath for clarity.
    public List<Object> selectPath(String path) {
        // FIX: Replaced charAt(0) comparison with startsWith for type safety and clarity.
        if (String.isBlank(path) || !path.startsWith('$')) {
            throw new JSONPathException('Path must start with the root element "$".');
        }

        List<Object> result = new List<Object>{ this.root };
        String normalizedPath = normalizePath(path);
        
        String pathExpression = normalizedPath.substring(1);
        if(String.isBlank(pathExpression)) {
            return result;
        }
        
        // This is the correct regex. The commented out one was incorrect.
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

    private String normalizePath(String path) {
        return path.replaceAll('\\[\'([a-zA-Z0-9_]+)\'\\]', '.$1').replaceAll('\\["([a-zA-Z0-9_]+)"\\]', '.$1');
    }

    private String getMatch(Matcher matcher) {
        for (Integer i = 1; i <= matcher.groupCount(); i++) {
            if (matcher.group(i) != null) {
                return matcher.group(i);
            }
        }
        return '';
    }

    // FIX: Replaced the invalid 'switch on true' with a standard 'if-else-if' block.
    private List<Object> evaluateSegment(String segment, Object node) {
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

    private List<Object> processProperty(String key, Object node) {
        List<Object> result = new List<Object>();
        if (node instanceof Map<String, Object>) {
            Map<String, Object> obj = (Map<String, Object>) node;
            if (obj.containsKey(key)) {
                result.add(obj.get(key));
            }
        }
        return result;
    }
    
    private List<Object> processIndex(Integer index, Object node) {
        List<Object> result = new List<Object>();
        if (node instanceof List<Object>) {
            // FIX: Renamed variable 'list_' to 'nodeList' to avoid trailing underscore.
            List<Object> nodeList = (List<Object>) node;
            if (index >= 0 && index < nodeList.size()) {
                result.add(nodeList.get(index));
            } else if (index < 0 && (nodeList.size() + index) >= 0) { 
                 result.add(nodeList.get(nodeList.size() + index));
            }
        }
        return result;
    }

    private List<Object> processWildcard(Object node) {
        if (node instanceof Map<String, Object>) {
            return ((Map<String, Object>) node).values();
        } else if (node instanceof List<Object>) {
            return (List<Object>) node;
        }
        return new List<Object>();
    }

    private List<Object> processRecursiveDescent(String key, Object node) {
        List<Object> result = new List<Object>();
        if (node == null) return result;

        if (node instanceof Map<String, Object>) {
            Map<String, Object> obj = (Map<String, Object>) node;
            if (key.equals('*') || obj.containsKey(key)) {
                result.add(key.equals('*') ? obj : obj.get(key));
            }
            for (Object value : obj.values()) {
                // FIX: Correctly called itself without the underscore.
                result.addAll(processRecursiveDescent(key, value));
            }
        } else if (node instanceof List<Object>) {
            for (Object item : (List<Object>) node) {
                // FIX: Correctly called itself without the underscore.
                result.addAll(processRecursiveDescent(key, item));
            }
        }
        return result;
    }

    private List<Object> processUnion(String segment, Object node) {
        List<Object> result = new List<Object>();
        Set<Object> resultSet = new Set<Object>();
        List<String> parts = segment.split(',');
        for (String part : parts) {
            String trimmedPart = part.trim();
            if (trimmedPart.isNumeric()) {
                // FIX: Called correct method name.
                resultSet.addAll(processIndex(Integer.valueOf(trimmedPart), node));
            } else {
                 // FIX: Called correct method name.
                 resultSet.addAll(processProperty(trimmedPart.replaceAll('[\'"]', ''), node));
            }
        }
        result.addAll(resultSet);
        return result;
    }

    private List<Object> processSlice(String segment, Object node) {
        List<Object> result = new List<Object>();
        if (!(node instanceof List<Object>)) return result;

        List<Object> nodeList = (List<Object>) node;
        List<String> parts = segment.split(':');
        Integer listSize = nodeList.size();

        Integer start = (parts.size() > 0 && !String.isBlank(parts[0])) ? Integer.valueOf(parts[0]) : 0;
        // FIX: Renamed 'end' to 'endIndex' to avoid using a reserved keyword.
        Integer endIndex = (parts.size() > 1 && !String.isBlank(parts[1])) ? Integer.valueOf(parts[1]) : listSize;
        Integer step = (parts.size() > 2 && !String.isBlank(parts[2])) ? Integer.valueOf(parts[2]) : 1;

        if (start < 0) start += listSize;
        if (endIndex < 0) endIndex += listSize;

        start = Math.max(0, start);
        endIndex = Math.min(listSize, endIndex);

        if (step == 0) throw new JSONPathException('Slice step cannot be zero.');

        for (Integer i = start; (step > 0 ? i < endIndex : i > endIndex); i += step) {
            if (i >= 0 && i < nodeList.size()) {
                result.add(nodeList.get(i));
            }
        }
        return result;
    }

    private List<Object> processFilter(String segment, Object node) {
        List<Object> result = new List<Object>();
        if (!(node instanceof List<Object>)) return result;

        String filter = segment.substring(2, segment.length() - 1);

        for (Object item : (List<Object>) node) {
            if (item instanceof Map<String, Object> && evaluateFilterCondition(filter, (Map<String, Object>)item)) {
                result.add(item);
            }
        }
        return result;
    }

    private Boolean evaluateFilterCondition(String condition, Map<String, Object> item) {
        if (!condition.contains('<') && !condition.contains('>') && !condition.contains('==') && !condition.contains('!=')) {
             String key = condition.replace('@.', '');
             return item.containsKey(key);
        }
        
        Matcher m = Pattern.compile('@\\.([a-zA-Z0-9_]+)\\s*(==|!=|<|>|<=|>=)\\s*([\\s\\S]+)').matcher(condition);
        if (!m.matches()) return false;

        String key = m.group(1);
        String op = m.group(2);
        String valStr = m.group(3).trim();

        if (!item.containsKey(key)) return false;

        Object itemValue = item.get(key);
        Object filterValue = parseValue(valStr);

        if (itemValue == null || filterValue == null) return false;

        try {
            Decimal itemDecimal = convertToDecimal(itemValue);
            Decimal filterDecimal = convertToDecimal(filterValue);

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

    private Object parseValue(String valStr) {
        if (valStr.startsWith('\'') && valStr.endsWith('\'')) {
            return valStr.substring(1, valStr.length() - 1);
        }
        if (valStr.startsWith('"') && valStr.endsWith('"')) {
            return valStr.substring(1, valStr.length() - 1);
        }
        try {
            return Decimal.valueOf(valStr);
        } catch (Exception e) {
            // FIX: If it's not a number, it's a literal string. Don't throw an exception.
            return valStr; 
        }
    }

    private Decimal convertToDecimal(Object val) {
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
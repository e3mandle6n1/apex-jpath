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
    
    public List<Object> selectPath(String path) {
        if (String.isBlank(path) || !path.startsWith('$')) {
            throw new JSONPathException('Path must start with the root element "$".');
        }

        List<Object> result = new List<Object>{ this.root };
        String normalizedPath = normalizePath(path);
        
        String pathExpression = normalizedPath.substring(1);
        if(String.isBlank(pathExpression)) {
            return result;
        }

        // Order matters: match recursive descent '..key' first, then bracket segments, then dot segments.
        // Also allow '-' in bracket indices (e.g., [-1]).
        Pattern pathPattern = Pattern.compile('(\\.\\.[a-zA-Z0-9_\\*]+)|\\[([^\\]]+)\\]|\\.([a-zA-Z0-9_\\*]+)');
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
        return path
            .replaceAll('\\[\'([a-zA-Z0-9_]+)\'\\]', '.$1')
            .replaceAll('\\["([a-zA-Z0-9_]+)"\\]', '.$1')
            // Keep negative indices inside brackets intact by not normalizing numeric brackets.
            ;
    }

    private String getMatch(Matcher matcher) {
        // With the updated regex, group(1) = recursive '..key', group(2) = bracket content, group(3) = dot key.
        if (matcher.group(1) != null) return matcher.group(1);
        if (matcher.group(2) != null) return matcher.group(2);
        if (matcher.group(3) != null) return matcher.group(3);
        return '';
    }

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
        } else if (segment.isNumeric() || isSignedInteger(segment)) {
            return processIndex(Integer.valueOf(segment), node);
        } else {
            return processProperty(segment, node);
        }
    }

    // Detect signed integer strings like "-1"
    private Boolean isSignedInteger(String s) {
        if (String.isBlank(s)) return false;
        return Pattern.matches('^-?\\d+$', s);
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
                result.addAll(processRecursiveDescent(key, value));
            }
        } else if (node instanceof List<Object>) {
            for (Object item : (List<Object>) node) {
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
                resultSet.addAll(processIndex(Integer.valueOf(trimmedPart), node));
            } else {
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
        // Support filtering on a single object by treating it as a 1-element list.
        List<Object> iterable = new List<Object>();
        if (node instanceof List<Object>) {
            iterable = (List<Object>) node;
        } else if (node instanceof Map<String, Object>) {
            iterable.add(node);
        } else {
            return result;
        }

        String filter = segment.substring(2, segment.length() - 1);

        for (Object item : iterable) {
            if (item instanceof Map<String, Object> && evaluateFilterCondition(filter, (Map<String, Object>)item)) {
                result.add(item);
            }
        }
        return result;
    }

    // Attempt to coerce to Decimal; return null if not possible (no exception).
    private Decimal tryToDecimal(Object val) {
        if (val == null) return null;
        try {
            return convertToDecimal(val);
        } catch (Exception e) {
            return null;
        }
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

        // Try numeric comparison first, when both sides are numeric-coercible.
        Decimal leftNum = tryToDecimal(itemValue);
        Decimal rightNum = tryToDecimal(filterValue);

        // Relational operators require numeric comparison; if either side is non-numeric, return false.
        if (op == '<' || op == '>' || op == '<=' || op == '>=') {
            if (leftNum == null || rightNum == null) return false;
            if (op == '<') return leftNum < rightNum;
            if (op == '>') return leftNum > rightNum;
            if (op == '<=') return leftNum <= rightNum;
            if (op == '>=') return leftNum >= rightNum;
            return false;
        }

        // Equality/inequality: if both numeric, compare numerically; else fallback to string equality.
        if (op == '==' || op == '!=') {
            Boolean eq;
            if (leftNum != null && rightNum != null) {
                eq = (leftNum == rightNum);
            } else {
                String ls = String.valueOf(itemValue);
                String rs = String.valueOf(filterValue);
                eq = ls == rs;
            }
            return (op == '==') ? eq : !eq;
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
            return valStr; 
        }
    }

    private Decimal convertToDecimal(Object val) {
        if (val == null) throw new JSONPathException('Cannot compare null value.');
        if (val instanceof Decimal) {
            return (Decimal) val;
        }
        if (val instanceof Double || val instanceof Integer || val instanceof Long) {
            // Safe conversion route: go through String to avoid ClassCastException
            return Decimal.valueOf(String.valueOf(val));
        }
        if (val instanceof String) {
            String s = ((String) val).trim();
            return Decimal.valueOf(s);
        }
        throw new JSONPathException('Cannot compare non-numeric value: ' + String.valueOf(val));
    }
}

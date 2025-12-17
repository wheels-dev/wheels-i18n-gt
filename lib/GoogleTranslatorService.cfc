component output="false" {

    variables.config = {};
    variables.cache  = {};   // simple in-memory cache (html+lang hash → translated)

    public any function init(
        required string defaultLanguage,
        required string availableLanguages,
        required string apiKey,
        required boolean cacheEnabled
    ) {
        variables.config = arguments;
        return this;
    }
    
    /**
     * Public translate method – called from the plugin's whlsGt() function
     */
    public string function $whlsTranslate(
        required any text, 
        required string target, 
        string format = "text"
    ) {
        local.cacheKey = hash(arguments.text & "|" & arguments.target & "|" & arguments.format);

        // Return cached result when enabled
        if (variables.config.cacheEnabled && structKeyExists(variables.cache, local.cacheKey)) {
            return variables.cache[local.cacheKey];
        }

        local.result = $whlsTranslateViaGoogle(arguments.text, arguments.target, arguments.format);

        // Cache when enabled
        if (variables.config.cacheEnabled) {
            variables.cache[local.cacheKey] = local.result;
        }

        return local.result;
    }

    /**
     * Sends text to Google Translate API and returns translated output.
     *
     * Responsibilities:
     * - Makes a POST request to Google Translate v2 API
     * - Supports plain text or HTML translation via `format`
     * - Safely parses JSON response
     * - Falls back to original text on any error or invalid response
     */
    private string function $whlsTranslateViaGoogle(
        required any text, 
        required string target, 
        required string format
    ) {
        if (!len(variables.config.apiKey)) {
            return arguments.text;
        }

        local.url = "https://translation.googleapis.com/language/translate/v2";

        cfhttp(
            method      = "post",
            multipart   = "yes",
            url         = local.url,
            charset     = "utf-8",
            result      = "local.httpResp"
        ) {
            cfhttpparam(type="formfield", name="q",      value=arguments.text);
            cfhttpparam(type="formfield", name="target", value=arguments.target);
            cfhttpparam(type="formfield", name="format", value=arguments.format);
            cfhttpparam(type="formfield", name="key",    value=variables.config.apiKey);
        }

        if (isJSON(local.httpResp.filecontent)) {
            local.json = deserializeJSON(local.httpResp.filecontent);
            if (
                structKeyExists(local.json, "data") &&
                isArray(local.json.data.translations) &&
                arrayLen(local.json.data.translations)
            ) {
                return local.json.data.translations[1].translatedText;
            }
        }

        return arguments.text; // fallback
    }

    /**
     * Splits HTML into tokens and extracts translatable text segments.
     *
     * Returns:
     * - template: HTML string containing {{t_n}} placeholders
     * - translatables: ordered array of text segments to translate
     */
    public struct function $whlsTokenizeHtml(required string html) {
        local.tokens = reMatchNoCase("(<[^>]+>|[^<]+)", arguments.html);

        local.template      = [];
        local.translatables = [];
        local.counter       = 0;

        for (local.token in tokens) {

            // Keep HTML tags intact
            if (left(token, 1) == "<") {
                template.append(token);
                continue;
            }

            local.txt = trim(token);

            // Skip empty / numeric / symbols-only text
            if (!len(txt) || reFind("^[\d\s\W]+$", txt)) {
                template.append(token);
                continue;
            }

            counter++;
            local.key = "t_" & counter;

            translatables.append({
                key   = key,
                value = txt
            });

            template.append("{{" & key & "}}");
        }

        return {
            template      = arrayToList(template, ""),
            translatables = translatables
        };
    }

    /**
     * Builds a structured translation payload string in the format:
     * { key | {value} | key | {value} }
     *
     * This structure allows reliable parsing after translation.
     */
    public string function $whlsBuildTranslationPayload(required array translatables) {
        local.parts = [];

        for (local.item in arguments.translatables) {
            parts.append(item.key);
            parts.append("{" & item.value & "}");
        }

        return "{" & arrayToList(parts, " | ") & "}";
    }

    /**
     * Parses a translated payload back into a key/value map.
     *
     * Converts:
     *   { t_1 | {Hola} | t_2 | {Mundo} }
     * Into:
     *   { t_1 = "Hola", t_2 = "Mundo" }
     */
    public struct function $whlsParseTranslatedPayload(required string str) {
        local.clean = trim(arguments.str);

        // Strip outer { }
        clean = reReplace(clean, "^\{|\}$", "", "all");

        local.parts = listToArray(clean, "|");
        local.map   = {};

        for (local.i = 1; i <= arrayLen(parts); i += 2) {
            local.key   = trim(parts[i]);
            local.value = trim(parts[i + 1]);

            // Remove inner wrapping { }
            value = reReplace(value, "^\{(.*)\}$", "\1", "one");

            map[key] = value;
        }

        return map;
    }

    /**
     * Replaces {{t_n}} placeholders in the HTML template
     * with translated values from the map.
     */
    public string function $whlsApplyTranslations(
        required string html,
        required struct map
    ) {
        local.result = arguments.html;

        for (local.key in arguments.map) {
            result = replace(
                result,
                "{{" & key & "}}",
                map[key],
                "all"
            );
        }

        return result;
    }

}

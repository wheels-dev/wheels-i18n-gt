component output="false" {

    variables.config = {};
    variables.cache  = {};   // simple in-memory cache (html+lang hash → translated)

    public any function init(
        required string defaultLanguage,
        required string availableLanguages,
        required string provider,
        required string apiKey,
        required boolean cacheEnabled
    ) {
        variables.config = arguments;
        return this;
    }
    
    /**
     * Public translate method – called from the plugin's gt() function
     */
    public string function $translate(
        required any text, 
        required string target, 
        string format = "text"
    ) {
        local.cacheKey = hash(arguments.text & "|" & arguments.target & "|" & arguments.format);

        // Return cached result when enabled
        if (variables.config.cacheEnabled && structKeyExists(variables.cache, local.cacheKey)) {
            return variables.cache[local.cacheKey];
        }

        local.result = $translateViaGoogle(arguments.text, arguments.target, arguments.format);
        // Choose provider
        // switch(variables.config.provider) {
        //     case "google":
        //         local.result = $translateViaGoogle(arguments.text, arguments.target);
        //         break;
        //     case "mymemory":
        //     default:
        //         local.result = $translateViaMyMemory(arguments.text, arguments.target);
        //         break;
        // }

        // Cache when enabled
        if (variables.config.cacheEnabled) {
            variables.cache[local.cacheKey] = local.result;
        }

        return local.result;
    }

    private string function $translateViaGoogle(
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

    private string function $translateViaMyMemory(required string text, required string target) {
        local.source   = variables.config.defaultLanguage;
        local.endpoint = "https://api.mymemory.translated.net/get";

        cfhttp(
            method = "get",
            url    = local.endpoint,
            charset= "utf-8",
            result = "local.httpResp"
        ) {
            cfhttpparam(type="url", name="q",       value=urlEncodedFormat(arguments.text));
            cfhttpparam(type="url", name="langpair", value=local.source & "|" & arguments.target);
        }

        if (isJSON(local.httpResp.filecontent)) {
            local.json = deserializeJSON(local.httpResp.filecontent);
            if (structKeyExists(local.json, "responseData") && structKeyExists(local.json.responseData, "translatedText")) {
                return local.json.responseData.translatedText;
            }
        }

        return arguments.text; // fallback
    }

}

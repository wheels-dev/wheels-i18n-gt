component hint="wheels-googleTranslator" output="false" mixin="global" {

    /**
     * Plugin initializer.
     *
     * - Registers default configuration values
     * - Loads the translation service singleton
     */
    public any function init() {
        this.version = "3.0.0";

        // 1. Set default configuration settings
        $setDefaultSettings();

        // 2. Load the translation service singleton
        $loadService();

        return this;
    }

    /**
     * Sets default plugin configuration values in application scope.
     * Values are only set if they do not already exist, allowing
     * developers to override them in settings.cfm or environment configs.
     */
    private void function $setDefaultSettings() {
        local.appKey = application.wo.$appKey();

        if (!structKeyExists(application[local.appKey], "gt_defaultLanguage")) {
            application.wo.set(gt_defaultLanguage="en");
        }
        if (!structKeyExists(application[local.appKey], "gt_availableLanguages")) {
            application.wo.set(gt_availableLanguages="en");
        }
        if (!structKeyExists(application[local.appKey], "gt_provider")) {
            application.wo.set(gt_provider="google");           // configuration for future APIs 
        }
        if (!structKeyExists(application[local.appKey], "gt_apiKey")) {
            application.wo.set(gt_apiKey="");
        }
        if (!structKeyExists(application[local.appKey], "gt_cacheEnabled")) {
            application.wo.set(gt_cacheEnabled=false);
        }
    }

    /**
     * Creates and stores the GoogleTranslatorService singleton
     * in the current Wheels application namespace.
     */
    private void function $loadService() {
        local.appKey = application.wo.$appKey();

        application[local.appKey].googleTranslator = createObject(
            "component",
            "plugins.googleTranslator.lib.GoogleTranslatorService"
        ).init(
            defaultLanguage      = application.wo.get("gt_defaultLanguage"),
            availableLanguages   = application.wo.get("gt_availableLanguages"),
            provider             = application.wo.get("gt_provider"),
            apiKey               = application.wo.get("gt_apiKey"),
            cacheEnabled         = application.wo.get("gt_cacheEnabled")
        );
    }

    /**
     * Translate a plain string or template string to a target language.
     *
     * Supports variable interpolation via argumentCollection.
     *
     * Examples:
     *   gt("Hello world", "es", "text");
     */
    public string function gt(required string text, required string target, required string format) {
        local.appKey      = application.wo.$appKey();
        local.service     = application[local.appKey].googleTranslator;

        // Pass through all arguments so interpolation works inside the service if needed
        local.translation = local.service.$translate(
            text   = arguments.text,
            target = arguments.target,
            format = arguments.format,
            argumentCollection = arguments
        );

        return local.translation;
    }

    /**
     * Translate HTML content while preserving markup.
     *
     * - HTML tags are kept intact
     * - Only readable text nodes are translated
     * - Prevents Google API from breaking markup structure
     *
     * Intended for full-page or large HTML blocks.
     */
    public string function gtTranslate(
        required string text,
        required string target
    ) {
        local.appKey  = application.wo.$appKey();
        local.service = application[local.appKey].googleTranslator;

        // 1. Split HTML into translatable tokens
        local.tokensData = tokenizeHtml(arguments.text);

        if (!arrayLen(tokensData.translatables)) {
            return arguments.text;
        }

        // 2. Build payload for translator
        local.payload = buildTranslationPayload(tokensData.translatables);

        // 3. Translate
        local.translation = local.service.$translate(
            text   = payload,
            target = arguments.target,
            format = "text",
            argumentCollection = arguments
        );

        // 4. Parse + rebuild final HTML
        local.map = parseTranslatedPayload(local.translation);
        return applyTranslations(tokensData.template, local.map);
    }

    /**
     * Splits HTML into tokens and extracts translatable text segments.
     *
     * Returns:
     * - template: HTML string containing {{t_n}} placeholders
     * - translatables: ordered array of text segments to translate
     */
    public struct function tokenizeHtml(required string html) {
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
    public string function buildTranslationPayload(required array translatables) {
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
    public struct function parseTranslatedPayload(required string str) {
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
    public string function applyTranslations(
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

    /**
     * Get current application language from Session,
     * or return the default language if not set.
     */
    public string function currentLanguage() {
        if (structKeyExists(session, "lang") && len(session.lang)) {
            return session.lang;
        }
        return get("gt_defaultLanguage");
    }

    /**
     * Updates the current session language.
     *
     * Returns:
     * - true  → language was valid and updated
     * - false → language not supported
     */
    public boolean function changeLanguage(required string language) {
        if (listFindNoCase(get("gt_availableLanguages"), arguments.language)) {
            session.lang = arguments.language;
            return true;
        }
        return false;
    }

    /**
     * Returns all configured available languages as an array.
     */
    public array function availableLanguages() {
        return listToArray(get("gt_availableLanguages"));
    }

}

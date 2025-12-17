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
        local.tokensData = local.service.$tokenizeHtml(arguments.text);

        if (!arrayLen(tokensData.translatables)) {
            return arguments.text;
        }

        // 2. Build payload for translator
        local.payload = local.service.$buildTranslationPayload(tokensData.translatables);

        // 3. Translate
        local.translation = local.service.$translate(
            text   = payload,
            target = arguments.target,
            format = "text",
            argumentCollection = arguments
        );

        // 4. Parse + rebuild final HTML
        local.map = local.service.$parseTranslatedPayload(local.translation);
        return local.service.$applyTranslations(tokensData.template, local.map);
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
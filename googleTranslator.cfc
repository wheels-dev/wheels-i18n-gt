component hint="wheels-googleTranslator" output="false" mixin="global" {

    public any function init() {
        this.version = "3.0.0";

        // 1. Set default configuration settings
        $setDefaultSettings();

        // 2. Load the translation service singleton
        $loadService();

        return this;
    }

    private void function $setDefaultSettings() {
        local.appKey = application.wo.$appKey();

        if (!structKeyExists(application[local.appKey], "gt_defaultLanguage")) {
            application.wo.set(gt_defaultLanguage="en");
        }
        if (!structKeyExists(application[local.appKey], "gt_availableLanguages")) {
            application.wo.set(gt_availableLanguages="en");
        }
        if (!structKeyExists(application[local.appKey], "gt_provider")) {
            application.wo.set(gt_provider="google");        // configuration for future APIs 
        }
        if (!structKeyExists(application[local.appKey], "gt_apiKey")) {
            application.wo.set(gt_apiKey="");
        }
        if (!structKeyExists(application[local.appKey], "gt_cacheEnabled")) {
            application.wo.set(gt_cacheEnabled=false);
        }
    }
    
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
     * Translate a piece of text (or HTML) to the target language
     * Usage: gt("Hello world", "es") or gt(text="Hello {name}", target="fr", name="John")
     */
    public string function gt(required string text, required string target) {
        local.appKey      = application.wo.$appKey();
        local.service     = application[local.appKey].googleTranslator;

        // Pass through all arguments so interpolation works inside the service if needed
        local.translation = local.service.$translate(
            text   = arguments.text,
            target = arguments.target,
            argumentCollection = arguments
        );

        return local.translation;
    }

    /**
     * Get current application lang from Session, or default if not set
     */
    public string function currentLanguage() {
        if (structKeyExists(session, "lang") && len(session.lang)) {
            return session.lang;
        }
        return get("gt_defaultLanguage");
    }

    /**
     * Change application lang
     * Returns true if successful, false if lang not supported
     */
    public boolean function changeLanguage(required string language) {
        if (listFindNoCase(get("gt_availableLanguages"), arguments.language)) {
            session.lang = arguments.language;
            return true;
        }
        return false;
    }

    /**
     * Get all available languages as an array
     */
    public array function availableLanguages() {
        return listToArray(get("gt_availableLanguages"));
    }
    
}

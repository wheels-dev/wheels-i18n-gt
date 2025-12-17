# Wheels Internationalization via Google Translator

**Runtime HTML & text translation plugin for Wheels 3.x using Google Translate API**

Translate entire pages on-the-fly without JSON files or database tables.

---

## Features

- Full page HTML translation (markup-safe)
- Plain text translation
- Session-based language switching
- Optional in-memory caching
- Zero schema / zero migration
- Works with Wheels + BoxLang

___Use case:___ __Perfect when you need instant multilingual pages without managing translation files.__

---

## Installation

```bash
wheels plugin install wheels-googleTranslator
```

---

## Configuration

Add the following settings to `config/settings.cfm`:

```cfml
set(gt_defaultLanguage="en");
set(gt_availableLanguages="en,es,fr");
set(gt_apiKey="YOUR_GOOGLE_API_KEY");
set(gt_cacheEnabled=false); // set true in production
```

To obtain a Google Cloud Translation API key, follow the official setup guide: https://cloud.google.com/translate/docs/setup

___Note:___  __You will need a Google Cloud project with billing enabled. New users get free credits to start.__

### Configuration Options

| Setting | Default | Description |
|-------|---------|-------------|
| gt_defaultLanguage | en | Default / fallback language |
| gt_availableLanguages | en | Comma-separated allowed languages |
| gt_apiKey | empty | Google Translate API key |
| gt_cacheEnabled | false | Cache translated output in memory |

---

## Plugin Functions

- `#gt("text", "language", "format")#` → Translate Single Text
- `#gtTranslate("text", "language")#` → Translate Full Page
- `#currentLanguage()#` → Get current language
- `#changeLanguage("es")#` → Switch language
- `#availableLanguages()#` → Array of supported languages

---
## Usage: Key Functions

### Translate Single Text - `gt()`

The core function to translate a single text to the destination language, with parameter interpolation and fallback logic.

```cfml
// Basic Usage
#gt("Welcome to the application", "es", "text")#      // (Output: Bienvenido a la aplicación)

// With parameter interpolation
#gt("Hello, Mr John Doe!", "fr", "text")#   // (Output: "Bonjour, Monsieur John Doe!")
```

### Translate Full HTML (Recommended)

Translates a full HTML block or page while `preserving the original markup`. Only readable text nodes are sent to the translation provider, ensuring that HTML tags, attributes, and structure remain untouched.

This function is ideal for translating:

```cfml
// Translate full HTML content
#gtTranslate(includeContent(), "es")#

// Translate a raw HTML string
#gtTranslate(
    text   = "<h1>Hello World</h1><p>Welcome to our site</p>",
    target = "fr"
)#
```

___Tip:___ __Wrap your full page output with gtTranslate() to translate everything at once.__

### Get Current Language - `currentLanguage()`

Gets the current application language from the Session, or the default language if not set.

```cfml
language = currentLanguage();       // "en"
```

### Change Language - `changeLanguage()`

Sets the application language in Session and returns a boolean based on success.

```cfml
// Change to Spanish
changeLanguage("es");

// Unsupported language
changeLanguage("jp");       // false
```

### Get All Available Languages - `availableLanguages()`

Returns an array of all configured available languages.

```cfml
languages = availableLanguages();       // ["en", "es", "fr"]
```
---

## Best Practices

- Translate **once per page**, not per component
- Always use `gtTranslate()` for full-page output
- Enable caching in production to reduce API usage
- Avoid translating dynamic fragments repeatedly

---

## License

[MIT](https://github.com/wheels-dev/wheels-i18n-gt/blob/main/LICENSE)

## Author

[Wheels-dev](https://forgebox.io/@wheels%2Ddev)

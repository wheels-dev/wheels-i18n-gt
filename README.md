# wheels-googleTranslator

**Runtime HTML & text translation plugin for Wheels 3.x using Google Translate API**

Translate entire pages on-the-fly without JSON files or database tables.

---

## Features

- Full page HTML translation (markup-safe)
- Plain text translation
- Session-based language switching
- Google Translate API support
- Optional in-memory caching
- Zero schema / zero migration
- Works with Wheels + BoxLang

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
set(gt_provider="google");
set(gt_apiKey="YOUR_GOOGLE_API_KEY");
set(gt_cacheEnabled=false); // set true in production
```

### Configuration Options

| Setting | Default | Description |
|-------|---------|-------------|
| gt_defaultLanguage | en | Default / fallback language |
| gt_availableLanguages | en | Comma-separated allowed languages |
| gt_provider | google | Translation provider |
| gt_apiKey | empty | Google Translate API key |
| gt_cacheEnabled | false | Cache translated output in memory |

---

## Usage

### Translate Plain Text

```cfml
#gt("Hello World", "es", "text")#
```

### Translate Full HTML (Recommended)

```cfml
#gtTranslate(renderView(), "fr")#
```

This safely translates only readable text and preserves all HTML markup.

---

## Language Helpers

```cfml
changeLanguage("es");      // switch session language
currentLanguage();         // get current language
availableLanguages();      // array of supported languages
```

---

## Best Practices

- Translate **once per page**, not per component
- Always use `gtTranslate()` for full-page output
- Enable caching in production to reduce API usage
- Avoid translating dynamic fragments repeatedly

---

## License

MIT License

---

## Author

**wheels-dev**  
https://github.com/wheels-dev

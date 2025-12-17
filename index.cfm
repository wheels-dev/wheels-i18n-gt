<style>
    body {font-family: "Segoe UI", Arial, sans-serif; line-height: 1.7; color: #222; background: #fdfdfd;}
    h1, h3, h4 {color: #1976d2;}
    h1 {font-size: 36px; border-bottom: 4px solid #eee; padding-bottom: 15px;}
    h2 {color: #333; border-bottom: 2px solid #2196F3; padding-bottom: 8px;}
    code {background: #f0f7ff; padding: 3px 8px; border-radius: 4px; font-size: 92%; color: #d63384;}
    pre {background: #f8f9fa; padding: 16px; border-radius: 8px; overflow-x: auto; border: 1px solid #e0e0e0; font-size: 14px;}
    .highlight {background: #e8f5e8; padding: 16px; border-left: 5px solid #4caf50; border-radius: 0 8px 8px 0; margin: 20px 0;}
    .pro {background: #fff8e1; padding: 16px; border-left: 5px solid #ff9800; border-radius: 0 8px 8px 0; margin: 25px 0;}
    .note {background: #e3f2fd; padding: 14px; border-left: 4px solid #1976d2; margin: 20px 0; border-radius: 4px;}
    table {width: 100%; border-collapse: collapse; margin: 20px 0;}
    th, td {padding: 12px; border: 1px solid #ddd; text-align: left;}
    th {background: #f5f5f5;}
    hr {border: none; height: 1px; background: #ddd; margin: 20px 0;}
    ul {padding-left: 20px;}
    a {color: #1976d2; text-decoration: none;}
    a:hover {text-decoration: underline;}
</style>

<h1>wheels-googleTranslator v1.0.0</h1>
<p><strong>Runtime page & HTML translation plugin for Wheels using Google Translate API.</strong></p>

<hr>

<h2>Why wheels-googleTranslator?</h2>
<ul>
<li>No database or JSON files required</li>
<li>Translates full HTML pages safely</li>
<li>Preserves markup & structure</li>
<li>Session-based language switching</li>
<li>Optional in-memory caching</li>
</ul>

<div class="note">
<strong>Use case:</strong> Perfect when you need instant multilingual pages without managing translation files.
</div>

<hr>

<h2>Installation</h2>
<pre>wheels plugin install wheels-googleTranslator</pre>

<hr>

<h2>Configuration</h2>
<p>Add these settings to <code>config/settings.cfm</code>:</p>
<pre>
set(gt_defaultLanguage="en");
set(gt_availableLanguages="en,es,fr");
set(gt_apiKey="YOUR_GOOGLE_API_KEY");
set(gt_cacheEnabled=false);
</pre>

<p>To obtain a Google Cloud Translation API key, follow the official setup guide: <a href="https://cloud.google.com/translate/docs/setup" target="_blank">https://cloud.google.com/translate/docs/setup</a></p>

<div class="note">
<strong>Note:</strong> You will need a Google Cloud project with billing enabled. New users get free credits to start.
</div>

<p>Below is a description of all available configuration settings and their default values:</p>

<table>
    <thead>
        <tr>
            <th>Setting Name</th>
            <th>Default Value</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><strong>gt_defaultLanguage</strong></td>
            <td><code>"en"</code></td>
            <td>The default language (language code) to use if no session language is set.</td>
        </tr>
        <tr>
            <td><strong>gt_availableLanguages</strong></td>
            <td><code>"en"</code></td>
            <td>A comma-separated list of all supported languages (e.g., <code>"en,es,fr"</code>).</td>
        </tr>
        <tr>
            <td><strong>gt_apiKey</strong></td>
            <td><code>empty</code></td>
            <td>Google Translation API Key for your application translations.</td>
        </tr>
        <tr>
            <td><strong>gt_cacheEnabled</strong></td>
            <td><code>false</code></td>
            <td>Set true to cache translations in memory (recommended for production).</td>
        </tr>
    </tbody>
</table>

<div class="note">
    <strong>Pro Tip:</strong> Set <code>gt_cacheEnabled=true</code> in production for fast performance.
</div>

<hr>

<h2>Plugin Functions</h2>
<ul>
    <li><code>#whlsGt("text", "language", "format")#</code> → Translate Single Text</li>
    <li><code>#whlsGtTranslate("text", "language")#</code> → Translate Full Page</li>
    <li><code>#whlsChangeLanguage("es")#</code> → Switch language</li>
    <li><code>#whlsCurrentLanguage()#</code> → Get current language</li>
    <li><code>#whlsAvailableLanguages()#</code> → Array of supported languages</li>
</ul>

<hr>

<h3>Usage: Key Functions</h3>

<h4>Translate Single Text - <code>whlsGt()</code></h4>
<p>The core function to translate a single text to the destination language, with parameter interpolation and fallback logic.</p>

<pre>
// Basic Usage
#whlsGt("Welcome to the application", "es", "text")#      // (Output: Bienvenido a la aplicación)

// With parameter interpolation
#whlsGt("Hello, Mr John Doe!", "fr", "text")#   // (Output: "Bonjour, Monsieur John Doe!")
</pre>

<h4>Translate Full HTML Content – <code>whlsGtTranslate()</code></h4> 
<p>
    Translates a full HTML block or page while <strong>preserving the original markup</strong>.
    Only readable text nodes are sent to the translation provider, ensuring that
    HTML tags, attributes, and structure remain untouched.
</p>

<p>
    This function is ideal for translating:
</p>

<pre>
// Translate full HTML content
#whlsGtTranslate(includeContent(), "es")#

// Translate a raw HTML string
#whlsGtTranslate(
    text   = "&lt;h1&gt;Hello World&lt;/h1&gt;&lt;p&gt;Welcome to our site&lt;/p&gt;",
    target = "fr"
)#
</pre>

<div class="highlight">
<strong>Tip:</strong> Wrap your full page output with <code>whlsGtTranslate()</code> to translate everything at once.
</div>

<h4>Current Language - <code>whlsCurrentLanguage()</code></h4>
<p>Gets the current application language from the Session, or the default language if not set.</p>

<pre>
language = whlsCurrentLanguage(); // "en"
</pre>

<h4>Change Language - <code>whlsChangeLanguage()</code></h4>
<p>Sets the application language in Session and returns a boolean based on success.</p>

<pre>
// Change to Spanish
whlsChangeLanguage("es");

// Unsupported language
whlsChangeLanguage("jp"); // false
</pre>

<h4>Available Languages - <code>whlsAvailableLanguages()</code></h4>
<p>Returns an array of all configured available languages.</p>

<pre>
languages = whlsAvailableLanguages(); // ["en", "es", "fr"]
</pre>

<hr>

<div class="highlight">
    Made with love by <strong>wheels-dev</strong><br>
    MIT License • Works with Wheels 3.0+<br>
    GitHub: <a href="https://github.com/wheels-dev/wheels-i18n-gt">github.com/wheels-dev/wheels-i18n-gt</a>
</div>
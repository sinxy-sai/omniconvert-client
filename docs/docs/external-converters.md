# Desktop external converters

OmniConvert keeps document conversion local and does not bundle third-party
converters.

## DOCX to PDF

Install LibreOffice and make `soffice` (or `libreoffice`) available on `PATH`.
OmniConvert records the converter version and runs it with headless arguments:

```text
soffice --headless --convert-to pdf --outdir <temporary-directory> <input.docx>
```

The output must be a non-empty PDF. Password-protected or damaged documents,
missing fonts, and converter failures are reported as conversion errors. The
LibreOffice license and notices remain the responsibility of the installation;
the client does not redistribute it.

## MOBI to PDF

Install Calibre and make `ebook-convert` available on `PATH`. DRM-protected,
password-protected, damaged, or unsupported books may fail. The adapter does
not promise universal MOBI compatibility; supported behavior must be checked
against representative samples before release.

## Process safety

Executables are invoked with argument arrays and no shell interpolation. Each
conversion uses a restricted temporary directory, has a bounded timeout, checks
that a non-empty output exists, and publishes the result through the same
atomic-output path as image tools.

# KDropover 🗂️✨

> **Estantería flotante de archivos (macOS Dropover) + Quick Look con Resumen IA local para KDE Plasma 6.8 sobre Wayland en CachyOS Linux.**

KDropover combina dos de las experiencias más productivas del ecosistema macOS:
- **Dropover Floating File Shelf**: Arrastra y suelta archivos de distintas carpetas de Dolphin, el navegador o el escritorio en una estantería flotante anclada en Wayland (`LayerShellQt`) con estética **Liquid Glass**. Después puedes copiar todas sus rutas, empaquetarlos en un archivo `.zip`, añadirlos a la base de conocimiento RAG de Kiri (`~/.local/share/kiri/knowledge/`) o abrir su ubicación.
- **Quick Look + AI Executive Summary**: Selecciona cualquier archivo de la estantería para previsualizar su contenido al instante (texto, código, Markdown, PDF mediante `pdftotext` o imágenes con OCR `tesseract`) y generar un resumen ejecutivo con **Ollama (`qwen2.5:7b`)** en local.

---

## 🚀 Compilación e Instalación

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
cmake --install build
```

Para ejecutar:
```bash
~/.local/bin/kdropover
```

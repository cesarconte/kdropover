# KDropover 🗂️✨

> **Estantería de archivos (Dropover) + Quick Look con Resumen IA local para KDE Plasma 6.8 sobre Wayland en CachyOS Linux.**

KDropover combina dos potentes herramientas de productividad:
- **Estantería de Archivos**: Arrastra y suelta archivos de distintas carpetas de Dolphin, el navegador o el escritorio en una ventana flotante Liquid Glass (CachyOS.UI). Permite copiar todas sus rutas, empaquetarlos en un archivo `.zip`, añadirlos a la base de conocimiento de Kity o abrir su ubicación.
- **Quick Look + AI Executive Summary**: Selecciona cualquier archivo de la estantería para previsualizar su contenido al instante (texto, código, Markdown, PDF mediante `pdftotext` o imágenes con OCR `tesseract`) y generar un resumen ejecutivo con **Ollama (`qwen2.5:7b`)** en local.

---

## 🚀 Compilación e Instalación

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
sudo -n cmake --install build --prefix /usr
```

Para ejecutar:
```bash
kdropover
```

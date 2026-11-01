/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "dropovercontroller.h"

#include <QClipboard>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMimeData>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QStandardPaths>

DropoverController::DropoverController(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

QVariantList DropoverController::shelfFiles() const { return m_shelfFiles; }
int DropoverController::count() const { return m_shelfFiles.size(); }
QString DropoverController::quickLookTitle() const { return m_quickLookTitle; }
QString DropoverController::quickLookPreview() const { return m_quickLookPreview; }
QString DropoverController::aiSummary() const { return m_aiSummary; }
bool DropoverController::summarizing() const { return m_summarizing; }
QString DropoverController::statusMessage() const { return m_statusMessage; }

void DropoverController::setStatus(const QString &msg)
{
    if (m_statusMessage != msg) {
        m_statusMessage = msg;
        Q_EMIT statusMessageChanged();
    }
}

QString DropoverController::formatFileSize(qint64 bytes)
{
    if (bytes < 1024) {
        return QStringLiteral("%1 B").arg(bytes);
    } else if (bytes < 1024 * 1024) {
        return QStringLiteral("%1 KiB").arg(QString::number(bytes / 1024.0, 'f', 1));
    } else if (bytes < 1024LL * 1024LL * 1024LL) {
        return QStringLiteral("%1 MiB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 1));
    }
    return QStringLiteral("%1 GiB").arg(QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 2));
}

QString DropoverController::iconForExtension(const QString &suffix)
{
    const QString s = suffix.toLower();
    if (s == QStringLiteral("pdf")) return QStringLiteral("application-pdf");
    if (s == QStringLiteral("png") || s == QStringLiteral("jpg") || s == QStringLiteral("jpeg") || s == QStringLiteral("webp") || s == QStringLiteral("svg")) {
        return QStringLiteral("image-x-generic");
    }
    if (s == QStringLiteral("md") || s == QStringLiteral("txt")) return QStringLiteral("text-x-generic");
    if (s == QStringLiteral("cpp") || s == QStringLiteral("h") || s == QStringLiteral("py") || s == QStringLiteral("qml") || s == QStringLiteral("sh") || s == QStringLiteral("json")) {
        return QStringLiteral("text-x-script");
    }
    if (s == QStringLiteral("zip") || s == QStringLiteral("tar") || s == QStringLiteral("gz") || s == QStringLiteral("xz")) {
        return QStringLiteral("package-x-generic");
    }
    return QStringLiteral("unknown");
}

QString DropoverController::extractFileTextPreview(const QString &path, int maxChars)
{
    QFileInfo fi(path);
    if (!fi.exists() || !fi.isFile()) {
        return QString();
    }

    const QString ext = fi.suffix().toLower();
    if (ext == QStringLiteral("pdf")) {
        const QString pdftotext = QStandardPaths::findExecutable(QStringLiteral("pdftotext"));
        if (!pdftotext.isEmpty()) {
            QProcess proc;
            proc.start(pdftotext, {path, QStringLiteral("-")});
            if (proc.waitForFinished(3000) && proc.exitCode() == 0) {
                return QString::fromUtf8(proc.readAllStandardOutput()).left(maxChars).trimmed();
            }
        }
    } else if (ext == QStringLiteral("png") || ext == QStringLiteral("jpg") || ext == QStringLiteral("jpeg") || ext == QStringLiteral("webp")) {
        const QString tesseract = QStandardPaths::findExecutable(QStringLiteral("tesseract"));
        if (!tesseract.isEmpty()) {
            QProcess proc;
            proc.start(tesseract, {path, QStringLiteral("stdout"), QStringLiteral("--psm"), QStringLiteral("3")});
            if (proc.waitForFinished(3500) && proc.exitCode() == 0) {
                const QString ocr = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
                return ocr.isEmpty() ? QStringLiteral("[Imagen sin texto OCR detectado]") : ocr.left(maxChars);
            }
        }
        return QStringLiteral("[Imagen %1 — %2]").arg(fi.fileName(), formatFileSize(fi.size()));
    }

    QFile f(path);
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString::fromUtf8(f.read(maxChars * 2)).left(maxChars).trimmed();
    }
    return QStringLiteral("[Archivo binario: %1 (%2)]").arg(fi.fileName(), formatFileSize(fi.size()));
}

void DropoverController::addUrls(const QList<QUrl> &urls)
{
    for (const QUrl &u : urls) {
        if (u.isLocalFile()) {
            addFilePath(u.toLocalFile());
        }
    }
}

void DropoverController::openNativeFileDialog()
{
    // Al usar QApplication en KDE Plasma 6, QFileDialog delega automáticamente
    // en plasma-integration / KIOFileWidgets (o xdg-desktop-portal-kde), mostrando
    // exactamente el mismo selector nativo estilo Dolphin que usan los navegadores.
    const QStringList selectedPaths = QFileDialog::getOpenFileNames(
        nullptr,
        QStringLiteral("Añadir archivos a KDropover"),
        QDir::homePath(),
        QStringLiteral("Todos los archivos (*)"));

    for (const QString &path : selectedPaths) {
        addFilePath(path);
    }
}

void DropoverController::addFilePath(const QString &path)
{
    QFileInfo fi(path);
    if (!fi.exists()) return;

    const QString absPath = fi.absoluteFilePath();
    for (const QVariant &v : m_shelfFiles) {
        if (v.toMap().value(QStringLiteral("path")).toString() == absPath) {
            return; // Avoid duplicates
        }
    }

    QVariantMap item;
    item[QStringLiteral("path")] = absPath;
    item[QStringLiteral("name")] = fi.fileName();
    item[QStringLiteral("sizeText")] = fi.isDir() ? QStringLiteral("Carpeta") : formatFileSize(fi.size());
    item[QStringLiteral("iconName")] = fi.isDir() ? QStringLiteral("folder") : iconForExtension(fi.suffix());

    m_shelfFiles.append(item);
    Q_EMIT shelfFilesChanged();
    setStatus(QStringLiteral("%1 archivo(s) en la estantería").arg(m_shelfFiles.size()));

    if (m_shelfFiles.size() == 1 && fi.isFile()) {
        inspectFileQuickLook(absPath);
    }
}

void DropoverController::removeAt(int index)
{
    if (index >= 0 && index < m_shelfFiles.size()) {
        m_shelfFiles.removeAt(index);
        Q_EMIT shelfFilesChanged();
        setStatus(QStringLiteral("%1 archivo(s) en la estantería").arg(m_shelfFiles.size()));
    }
}

void DropoverController::clearShelf()
{
    m_shelfFiles.clear();
    m_quickLookTitle.clear();
    m_quickLookPreview.clear();
    m_aiSummary.clear();
    Q_EMIT shelfFilesChanged();
    Q_EMIT quickLookChanged();
    Q_EMIT aiSummaryChanged();
    setStatus(QStringLiteral("Estantería vaciada"));
}

void DropoverController::copyAllPathsToClipboard()
{
    if (m_shelfFiles.isEmpty()) return;

    QList<QUrl> urls;
    QStringList paths;
    for (const QVariant &v : m_shelfFiles) {
        const QString p = v.toMap().value(QStringLiteral("path")).toString();
        paths << p;
        urls << QUrl::fromLocalFile(p);
    }

    if (QClipboard *cb = QGuiApplication::clipboard()) {
        auto *mime = new QMimeData();
        mime->setUrls(urls);
        mime->setText(paths.join(QLatin1Char('\n')));
        cb->setMimeData(mime);
        setStatus(QStringLiteral("Copiados %1 archivo(s) al portapapeles de Wayland").arg(paths.size()));
    }
}

void DropoverController::exportShelfToKiriKnowledge()
{
    if (m_shelfFiles.isEmpty()) return;

    const QString kbDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/kiri/knowledge");
    QDir().mkpath(kbDir);

    int copied = 0;
    for (const QVariant &v : m_shelfFiles) {
        const QString src = v.toMap().value(QStringLiteral("path")).toString();
        QFileInfo fi(src);
        if (fi.isFile()) {
            const QString dst = kbDir + QLatin1Char('/') + fi.fileName();
            QFile::remove(dst);
            if (QFile::copy(src, dst)) {
                ++copied;
            }
        }
    }
    setStatus(QStringLiteral("Exportados %1 archivo(s) a Kiri RAG (~/.local/share/kiri/knowledge)").arg(copied));
}

void DropoverController::createZipInDownloads()
{
    if (m_shelfFiles.isEmpty()) return;

    const QString zipBin = QStandardPaths::findExecutable(QStringLiteral("zip"));
    const QString bsdtar = QStandardPaths::findExecutable(QStringLiteral("bsdtar"));
    const QString downloads = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString outZip = downloads + QStringLiteral("/KDropover_%1.zip").arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss")));

    QStringList paths;
    for (const QVariant &v : m_shelfFiles) {
        paths << v.toMap().value(QStringLiteral("path")).toString();
    }

    QProcess proc;
    if (!zipBin.isEmpty()) {
        QStringList args = {QStringLiteral("-r"), outZip};
        args.append(paths);
        proc.start(zipBin, args);
        proc.waitForFinished(10000);
    } else if (!bsdtar.isEmpty()) {
        QStringList args = {QStringLiteral("-a"), QStringLiteral("-cf"), outZip};
        args.append(paths);
        proc.start(bsdtar, args);
        proc.waitForFinished(10000);
    }

    if (QFileInfo::exists(outZip)) {
        setStatus(QStringLiteral("Creado %1").arg(QFileInfo(outZip).fileName()));
    } else {
        setStatus(QStringLiteral("No se pudo crear el archivo ZIP"));
    }
}

void DropoverController::inspectFileQuickLook(const QString &path)
{
    QFileInfo fi(path);
    if (!fi.exists()) return;

    m_quickLookTitle = QStringLiteral("%1 (%2)").arg(fi.fileName(), formatFileSize(fi.size()));
    m_quickLookPreview = extractFileTextPreview(path, 3500);
    m_aiSummary.clear();
    Q_EMIT quickLookChanged();
    Q_EMIT aiSummaryChanged();
}

void DropoverController::summarizeFileWithAi(const QString &path)
{
    inspectFileQuickLook(path);
    if (m_quickLookPreview.isEmpty()) return;

    m_summarizing = true;
    m_aiSummary = QStringLiteral("Generando resumen ejecutivo con Ollama (qwen2.5:7b)…");
    Q_EMIT aiSummaryChanged();

    QJsonObject reqObj;
    reqObj[QStringLiteral("model")] = QStringLiteral("qwen2.5:7b");
    reqObj[QStringLiteral("stream")] = false;

    QJsonArray msgs;
    QJsonObject sys;
    sys[QStringLiteral("role")] = QStringLiteral("system");
    sys[QStringLiteral("content")] = QStringLiteral(
        "Eres el motor Quick Look AI de KDropover en KDE Plasma 6. "
        "Resume en español de España en 3 o 4 viñetas concisas el contenido de este archivo.");
    msgs.append(sys);

    QJsonObject usr;
    usr[QStringLiteral("role")] = QStringLiteral("user");
    usr[QStringLiteral("content")] = QStringLiteral("Archivo: %1\n\nContenido:\n\"\"\"\n%2\n\"\"\"")
                                         .arg(m_quickLookTitle, m_quickLookPreview.left(3500));
    msgs.append(usr);
    reqObj[QStringLiteral("messages")] = msgs;

    QNetworkRequest req(QUrl(QStringLiteral("http://127.0.0.1:11434/api/chat")));
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    QNetworkReply *reply = m_nam->post(req, QJsonDocument(reqObj).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_summarizing = false;
        if (reply->error() != QNetworkReply::NoError) {
            m_aiSummary = QStringLiteral("No se pudo conectar con Ollama local.");
            Q_EMIT aiSummaryChanged();
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        m_aiSummary = doc.object()
                          .value(QStringLiteral("message"))
                          .toObject()
                          .value(QStringLiteral("content"))
                          .toString()
                          .trimmed();
        Q_EMIT aiSummaryChanged();
    });
}

void DropoverController::openFileExternally(const QString &path) const
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QStringList>
#include <QUrl>
#include <QVariantList>

class DropoverController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList shelfFiles READ shelfFiles NOTIFY shelfFilesChanged)
    Q_PROPERTY(int count READ count NOTIFY shelfFilesChanged)
    Q_PROPERTY(QString quickLookTitle READ quickLookTitle NOTIFY quickLookChanged)
    Q_PROPERTY(QString quickLookPreview READ quickLookPreview NOTIFY quickLookChanged)
    Q_PROPERTY(QString aiSummary READ aiSummary NOTIFY aiSummaryChanged)
    Q_PROPERTY(bool summarizing READ summarizing NOTIFY aiSummaryChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit DropoverController(QObject *parent = nullptr);
    ~DropoverController() override = default;

    QVariantList shelfFiles() const;
    int count() const;
    QString quickLookTitle() const;
    QString quickLookPreview() const;
    QString aiSummary() const;
    bool summarizing() const;
    QString statusMessage() const;

    Q_INVOKABLE void addUrls(const QList<QUrl> &urls);
    Q_INVOKABLE void addFilePath(const QString &path);
    Q_INVOKABLE void openNativeFileDialog();
    Q_INVOKABLE void removeAt(int index);
    Q_INVOKABLE void clearShelf();
    Q_INVOKABLE void copyAllPathsToClipboard();
    Q_INVOKABLE void exportShelfToKiriKnowledge();
    Q_INVOKABLE void createZipInDownloads();
    Q_INVOKABLE void inspectFileQuickLook(const QString &path);
    Q_INVOKABLE void summarizeFileWithAi(const QString &path);
    Q_INVOKABLE void openFileExternally(const QString &path) const;

    // Static helpers for unit testing
    static QString formatFileSize(qint64 bytes);
    static QString extractFileTextPreview(const QString &path, int maxChars = 3500);
    static QString iconForExtension(const QString &suffix);

Q_SIGNALS:
    void shelfFilesChanged();
    void quickLookChanged();
    void aiSummaryChanged();
    void statusMessageChanged();

private:
    void setStatus(const QString &msg);

    QVariantList m_shelfFiles;
    QString m_quickLookTitle;
    QString m_quickLookPreview;
    QString m_aiSummary;
    bool m_summarizing = false;
    QString m_statusMessage = QStringLiteral("Arrastra archivos aquí para guardarlos en la estantería");
    QNetworkAccessManager *m_nam = nullptr;
};

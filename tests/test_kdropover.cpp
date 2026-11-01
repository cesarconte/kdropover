/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "dropovercontroller.h"

#include <QDir>
#include <QFile>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QTest>

class TestKDropover : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testFileSizeFormatting()
    {
        QCOMPARE(DropoverController::formatFileSize(512), QStringLiteral("512 B"));
        QCOMPARE(DropoverController::formatFileSize(2048), QStringLiteral("2.0 KiB"));
        QCOMPARE(DropoverController::formatFileSize(5 * 1024 * 1024), QStringLiteral("5.0 MiB"));
    }

    void testShelfAddRemoveAndQuickLookPreview()
    {
        const QString tmpFile = QDir::tempPath() + QStringLiteral("/test_kdropover_sample.md");
        QFile f(tmpFile);
        QVERIFY(f.open(QIODevice::WriteOnly | QIODevice::Text));
        f.write("# Documento de prueba\nContenido para Quick Look AI en KDropover.");
        f.close();

        DropoverController ctrl;
        QCOMPARE(ctrl.count(), 0);

        ctrl.addFilePath(tmpFile);
        QCOMPARE(ctrl.count(), 1);
        // Adding duplicate should be ignored
        ctrl.addFilePath(tmpFile);
        QCOMPARE(ctrl.count(), 1);

        QVERIFY(ctrl.quickLookPreview().contains(QStringLiteral("Quick Look AI")));

        // Verify native KDE file dialog and Dolphin invokables are exposed to QML
        const QMetaObject *mo = ctrl.metaObject();
        QVERIFY(mo->indexOfMethod("openNativeFileDialog()") >= 0);
        QVERIFY(mo->indexOfMethod("openDolphinWindow()") >= 0);

        ctrl.removeAt(0);
        QCOMPARE(ctrl.count(), 0);
        QFile::remove(tmpFile);
    }

    void testDropoverQmlSyntax()
    {
        QQmlEngine engine;
        const QString qmlPath = QStringLiteral(KDROPOVER_SOURCE_DIR) + QStringLiteral("/src/qml/main.qml");
        QVERIFY(QFile::exists(qmlPath));
        QQmlComponent comp(&engine, QUrl::fromLocalFile(qmlPath));
        QVERIFY2(!comp.isError(), qPrintable(comp.errorString()));
    }
};

QTEST_MAIN(TestKDropover)
#include "test_kdropover.moc"

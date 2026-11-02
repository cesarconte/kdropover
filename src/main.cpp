/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "dropovercontroller.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kdropover"));
    app.setApplicationDisplayName(QStringLiteral("KDropover"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));

    DropoverController controller;

    // Allow passing initial files from command line or Dolphin "Open With"
    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        controller.addFilePath(args.at(i));
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Dropover"), &controller);
    engine.load(QUrl(QStringLiteral("qrc:/org/cesar/kdropover/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}

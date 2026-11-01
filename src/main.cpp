/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "dropovercontroller.h"

#include <LayerShellQt/Window>

#include <QApplication>
#include <QMargins>
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

    if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
        if (auto *layerWin = LayerShellQt::Window::get(win)) {
            layerWin->setLayer(LayerShellQt::Window::LayerTop);
            layerWin->setAnchors(LayerShellQt::Window::AnchorRight);
            layerWin->setMargins(QMargins(0, 0, 18, 0));
            layerWin->setExclusiveZone(0);
            layerWin->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
            layerWin->setScope(QStringLiteral("kdropover"));
        }
    }

    return app.exec();
}

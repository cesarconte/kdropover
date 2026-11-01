/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Window {
    id: rootWindow
    width: 440
    height: 520
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    QtDialogs.FileDialog {
        id: addFilesDialog
        title: "Añadir archivos a KDropover"
        fileMode: QtDialogs.FileDialog.OpenFiles
        onAccepted: {
            Dropover.addUrls(selectedFiles);
        }
    }

    Rectangle {
        id: glassCard
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        radius: Kirigami.Units.largeSpacing
        color: Qt.rgba(0.08, 0.09, 0.13, 0.88)
        border.width: dropArea.containsDrag ? 2 : 1
        border.color: dropArea.containsDrag ? "#00e5ff" : Qt.rgba(1.0, 1.0, 1.0, 0.22)

        // Liquid Glass Specular Sheen
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, glassCard.radius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1.0, 1.0, 1.0, 0.14) }
                GradientStop { position: 0.35; color: Qt.rgba(1.0, 1.0, 1.0, 0.02) }
                GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.0, 0.0, 0.14) }
            }
        }

        DropArea {
            id: dropArea
            anchors.fill: parent
            onDropped: drop => {
                if (drop.hasUrls) {
                    Dropover.addUrls(drop.urls);
                    drop.acceptProposedAction();
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "folder-stash-symbolic"
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    color: "#00e5ff"
                }

                QQC2.Label {
                    text: "KDropover · Estantería + Quick Look AI"
                    font.bold: true
                    color: "#ffffff"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                QQC2.ToolButton {
                    icon.name: "list-add-symbolic"
                    onClicked: addFilesDialog.open()
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Añadir archivos"
                }

                QQC2.ToolButton {
                    icon.name: "edit-clear-all-symbolic"
                    enabled: Dropover.count > 0
                    onClicked: Dropover.clearShelf()
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Vaciar estantería"
                }

                QQC2.ToolButton {
                    icon.name: "window-close-symbolic"
                    onClicked: Qt.quit()
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Cerrar KDropover"
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: Dropover.statusMessage
                color: "#90a4ae"
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                elide: Text.ElideRight
            }

            // Drop Zone / Shelf List
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 175
                radius: Kirigami.Units.mediumSpacing
                color: Qt.rgba(0.0, 0.0, 0.0, 0.28)
                border.width: 1
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: Dropover.count === 0
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "document-import-symbolic"
                        implicitWidth: Kirigami.Units.iconSizes.large
                        implicitHeight: Kirigami.Units.iconSizes.large
                        color: "#78909c"
                    }

                    QQC2.Label {
                        text: "Suelta aquí archivos desde Dolphin o el navegador"
                        color: "#b0bec5"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }
                }

                QQC2.ScrollView {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    visible: Dropover.count > 0
                    clip: true

                    ListView {
                        anchors.fill: parent
                        spacing: 4
                        model: Dropover.shelfFiles

                        delegate: Rectangle {
                            id: fileRow
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 36
                            radius: 6
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.07)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Kirigami.Icon {
                                    source: fileRow.modelData.iconName
                                    implicitWidth: 18
                                    implicitHeight: 18
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: fileRow.modelData.name + " (" + fileRow.modelData.sizeText + ")"
                                    color: "#ffffff"
                                    elide: Text.ElideMiddle
                                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                }

                                QQC2.ToolButton {
                                    icon.name: "view-preview-symbolic"
                                    onClicked: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                    QQC2.ToolTip.visible: hovered
                                    QQC2.ToolTip.text: "Quick Look (Vista rápida)"
                                }

                                QQC2.ToolButton {
                                    icon.name: "sparkles-symbolic"
                                    onClicked: Dropover.summarizeFileWithAi(fileRow.modelData.path)
                                    QQC2.ToolTip.visible: hovered
                                    QQC2.ToolTip.text: "Resumir con IA (Ollama)"
                                }

                                QQC2.ToolButton {
                                    icon.name: "document-open-symbolic"
                                    onClicked: Dropover.openFileExternally(fileRow.modelData.path)
                                    QQC2.ToolTip.visible: hovered
                                    QQC2.ToolTip.text: "Abrir archivo"
                                }

                                QQC2.ToolButton {
                                    icon.name: "list-remove-symbolic"
                                    onClicked: Dropover.removeAt(fileRow.index)
                                }
                            }
                        }
                    }
                }
            }

            // Batch Shelf Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    Layout.fillWidth: true
                    icon.name: "edit-copy-symbolic"
                    text: "Copiar todos"
                    enabled: Dropover.count > 0
                    onClicked: Dropover.copyAllPathsToClipboard()
                }

                QQC2.Button {
                    Layout.fillWidth: true
                    icon.name: "package-x-generic-symbolic"
                    text: "Crear ZIP"
                    enabled: Dropover.count > 0
                    onClicked: Dropover.createZipInDownloads()
                }

                QQC2.Button {
                    Layout.fillWidth: true
                    icon.name: "folder-bookmark-symbolic"
                    text: "Enviar a Kiri RAG"
                    enabled: Dropover.count > 0
                    onClicked: Dropover.exportShelfToKiriKnowledge()
                }
            }

            // Quick Look & AI Executive Summary Panel
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Kirigami.Units.mediumSpacing
                color: Qt.rgba(0.0, 0.0, 0.0, 0.34)
                border.width: 1
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 4

                    QQC2.Label {
                        Layout.fillWidth: true
                        font.bold: true
                        color: "#80d8ff"
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        elide: Text.ElideRight
                        text: Dropover.quickLookTitle.length > 0
                            ? ("👁️ Quick Look: " + Dropover.quickLookTitle)
                            : "👁️ Quick Look + AI Summary (selecciona un archivo)"
                    }

                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextEdit {
                            width: parent.width
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: "#eceff1"
                            font.family: Dropover.aiSummary.length > 0 ? Kirigami.Theme.defaultFont.family : "monospace"
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            text: Dropover.aiSummary.length > 0
                                ? ("✨ RESUMEN EJECUTIVO IA:\n" + Dropover.aiSummary + "\n\n─── VISTA PREVIA ───\n" + Dropover.quickLookPreview)
                                : Dropover.quickLookPreview
                        }
                    }
                }
            }
        }
    }
}

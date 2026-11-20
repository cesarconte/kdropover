/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: rootWindow

    title: CachyI18n.i18n("KDropover — Estantería de Archivos")
    width: 520
    height: 580
    minimumWidth: 440
    minimumHeight: 460

    showTrafficLights: true
    showTitleBarDivider: true
    showWindowFrame: true
    cornerRadius: CachyTheme.radiusWindow

    contentData: [
        DropArea {
            id: dropArea
            anchors.fill: parent

            onDropped: drop => {
                if (drop.hasUrls) {
                    Dropover.addUrls(drop.urls);
                    drop.acceptProposedAction();
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Header Info Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CachyIcon {
                        name: "archive-insert"
                        size: 22
                        color: CachyTheme.accentColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: CachyI18n.i18n("Estantería Temporal")
                            font.pixelSize: 15
                            font.bold: true
                            color: CachyTheme.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Dropover.statusMessage.length > 0
                                ? Dropover.statusMessage
                                : CachyI18n.i18n("Arrastra y mantén archivos a mano")
                            font.pixelSize: 11
                            color: CachyTheme.textSecondary
                            wrapMode: Text.WordWrap
                        }
                    }

                    CachyButton {
                        iconName: "list-add"
                        text: CachyI18n.i18n("Añadir")
                        onClicked: Dropover.openNativeFileDialog()
                    }

                    CachyButton {
                        iconName: "edit-clear"
                        text: CachyI18n.i18n("Vaciar")
                        destructive: true
                        enabled: Dropover.count > 0
                        onClicked: Dropover.clearShelf()
                    }
                }

                // Drop Zone / Shelf List (CachyCard)
                CachyCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200

                    contentItem: Item {
                        anchors.fill: parent

                        MouseArea {
                            anchors.fill: parent
                            enabled: Dropover.count === 0
                            cursorShape: Dropover.count === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: Dropover.openNativeFileDialog()
                        }

                        // Empty State View
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: Dropover.count === 0
                            spacing: 8

                            CachyIcon {
                                name: "folder-download"
                                size: 40
                                color: CachyTheme.accentColor
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: CachyI18n.i18n("Suelta aquí archivos para la estantería")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: CachyTheme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: CachyI18n.i18n("o haz clic aquí para seleccionar")
                                font.pixelSize: 11
                                color: CachyTheme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // Files List View
                        ListView {
                            id: shelfListView
                            anchors.fill: parent
                            spacing: 6
                            visible: Dropover.count > 0
                            clip: true
                            model: Dropover.shelfFiles

                            delegate: Rectangle {
                                id: fileRow
                                required property var modelData
                                required property int index

                                width: shelfListView.width
                                height: 38
                                radius: CachyTheme.radiusSmall
                                color: CachyTheme.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                                border.width: 1
                                border.color: CachyTheme.specularBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    CachyIcon {
                                        name: fileRow.modelData.iconName && fileRow.modelData.iconName.length > 0
                                            ? fileRow.modelData.iconName
                                            : "application-octet-stream"
                                        size: 18
                                        colored: false
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: fileRow.modelData.name + " (" + fileRow.modelData.sizeText + ")"
                                        color: CachyTheme.textPrimary
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 12
                                    }

                                    // Quick Look preview
                                    CachyToolbarButton {
                                        iconName: "view-preview"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        tooltipText: CachyI18n.i18n("Vista previa rápida")
                                        onClicked: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                    }

                                    // AI Summarize
                                    CachyToolbarButton {
                                        iconName: "kity-symbolic"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        tooltipText: CachyI18n.i18n("Resumen IA con Kity")
                                        onClicked: Dropover.summarizeFileWithAi(fileRow.modelData.path)
                                    }

                                    // Open file
                                    CachyToolbarButton {
                                        iconName: "document-open"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        tooltipText: CachyI18n.i18n("Abrir externamente")
                                        onClicked: Dropover.openFileExternally(fileRow.modelData.path)
                                    }

                                    // Delete from shelf
                                    CachyToolbarButton {
                                        iconName: "edit-delete"
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        tooltipText: CachyI18n.i18n("Quitar de la estantería")
                                        onClicked: Dropover.removeAt(fileRow.index)
                                    }
                                }
                            }
                        }
                    }
                }

                // Batch Actions Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CachyButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        iconName: "edit-copy"
                        text: CachyI18n.i18n("Copiar todos")
                        enabled: Dropover.count > 0
                        onClicked: Dropover.copyAllPathsToClipboard()
                    }

                    CachyButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        iconName: "archive-insert"
                        text: CachyI18n.i18n("Crear ZIP")
                        primary: true
                        enabled: Dropover.count > 0
                        onClicked: Dropover.createZipInDownloads()
                    }

                    CachyButton {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        iconName: "kity-symbolic"
                        text: CachyI18n.i18n("Enviar a Kity")
                        enabled: Dropover.count > 0
                        onClicked: Dropover.exportShelfToKityKnowledge()
                    }
                }

                // Quick Look & AI Summary Card
                CachyCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    contentItem: ColumnLayout {
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            CachyIcon {
                                name: Dropover.aiSummary.length > 0 ? "kity-symbolic" : "view-preview"
                                size: 14
                                color: CachyTheme.accentColor
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: Dropover.quickLookTitle.length > 0
                                    ? Dropover.quickLookTitle
                                    : CachyI18n.i18n("Vista Previa & Resumen IA (Selecciona un archivo)")
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: CachyTheme.accentColor
                                elide: Text.ElideRight
                            }
                        }

                        CachyDivider {
                            Layout.fillWidth: true
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: previewText.implicitHeight

                            TextEdit {
                                id: previewText
                                width: parent.width
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                color: CachyTheme.textPrimary
                                font.pixelSize: 12
                                text: Dropover.aiSummary.length > 0
                                    ? (CachyI18n.i18n("RESUMEN IA (Kity / Ollama):\n") + Dropover.aiSummary + "\n\n─── VISTA PREVIA ───\n" + Dropover.quickLookPreview)
                                    : (Dropover.quickLookPreview.length > 0
                                        ? Dropover.quickLookPreview
                                        : CachyI18n.i18n("Arrastra archivos a la estantería para previsualizarlos o generar resúmenes con IA."))
                            }
                        }
                    }
                }
            }
        }
    ]
}

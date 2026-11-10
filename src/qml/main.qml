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

    width: 480
    height: 600
    title: "KDropover — Estantería de Archivos"
    showTrafficLights: true

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

                    Text {
                        text: "📦"
                        font.pixelSize: 18
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Estantería Temporal"
                            font.pixelSize: 15
                            font.bold: true
                            color: CachyTheme.textPrimary
                        }

                        Text {
                            text: Dropover.statusMessage.length > 0
                                ? Dropover.statusMessage
                                : "Arrastra y mantén archivos a mano"
                            font.pixelSize: 11
                            color: CachyTheme.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    CachyButton {
                        text: "Añadir"
                        onClicked: Dropover.openNativeFileDialog()
                    }

                    CachyButton {
                        text: "Vaciar"
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

                            Text {
                                text: "📥"
                                font.pixelSize: 32
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Suelta aquí archivos para la estantería"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: CachyTheme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "o haz clic aquí para seleccionar"
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

                                    Text {
                                        text: "📄"
                                        font.pixelSize: 15
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: fileRow.modelData.name + " (" + fileRow.modelData.sizeText + ")"
                                        color: CachyTheme.textPrimary
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 12
                                    }

                                    // Quick Look preview
                                    CachyButton {
                                        text: "👁️"
                                        flat: true
                                        implicitWidth: 32
                                        implicitHeight: 26
                                        onClicked: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                    }

                                    // AI Summarize
                                    CachyButton {
                                        text: "✨"
                                        flat: true
                                        implicitWidth: 32
                                        implicitHeight: 26
                                        onClicked: Dropover.summarizeFileWithAi(fileRow.modelData.path)
                                    }

                                    // Open file
                                    CachyButton {
                                        text: "↗"
                                        flat: true
                                        implicitWidth: 32
                                        implicitHeight: 26
                                        onClicked: Dropover.openFileExternally(fileRow.modelData.path)
                                    }

                                    // Delete from shelf
                                    CachyButton {
                                        text: "✕"
                                        flat: true
                                        destructive: true
                                        implicitWidth: 26
                                        implicitHeight: 26
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
                        text: "Copiar todos"
                        enabled: Dropover.count > 0
                        onClicked: Dropover.copyAllPathsToClipboard()
                    }

                    CachyButton {
                        Layout.fillWidth: true
                        text: "Crear ZIP"
                        primary: true
                        enabled: Dropover.count > 0
                        onClicked: Dropover.createZipInDownloads()
                    }

                    CachyButton {
                        Layout.fillWidth: true
                        text: "Enviar a Kity"
                        enabled: Dropover.count > 0
                        onClicked: Dropover.exportShelfToKiriKnowledge()
                    }
                }

                // Quick Look & AI Summary Card
                CachyCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    contentItem: ColumnLayout {
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: Dropover.quickLookTitle.length > 0
                                ? ("👁️ " + Dropover.quickLookTitle)
                                : "👁️ Vista Previa & Resumen IA (Selecciona un archivo)"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: CachyTheme.accentColor
                            elide: Text.ElideRight
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
                                    ? ("✨ RESUMEN IA:\n" + Dropover.aiSummary + "\n\n─── VISTA PREVIA ───\n" + Dropover.quickLookPreview)
                                    : (Dropover.quickLookPreview.length > 0 ? Dropover.quickLookPreview : "Arrastra archivos a la estantería para previsualizarlos o generar resúmenes con IA.")
                            }
                        }
                    }
                }
            }
        }
    ]
}

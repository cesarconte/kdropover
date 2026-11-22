/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * KDropover — Estantería temporal de archivos Dropover adaptada a la estética
 * Liquid Glass de macOS 27 Golden Gate.
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
    showTitle: false
    showTitleBarDivider: false         // Barra continua Liquid Glass sin divisor duro
    showWindowFrame: true              // Liquid Glass: blur KWin + rim especular
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // Margen perimetral de 18 px

    // =========================================================================
    // CABECERA — IZQUIERDA: Píldora de estado con contador de archivos
    // =========================================================================
    headerLeading: [
        Rectangle {
            id: shelfCountPill
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            implicitWidth: countRow.implicitWidth + 18
            radius: 14
            color: CachyPalette.surfacePill
            border.width: 1
            border.color: CachyPalette.specularBorder

            RowLayout {
                id: countRow
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 7

                CachyIcon {
                    name: "folder"
                    size: 14
                    color: Dropover.count > 0 ? CachyTheme.accentColor : CachyPalette.textSecondary
                }

                CachyLabel {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumWidth: 200
                    text: Dropover.count > 0
                        ? CachyI18n.i18n("Estantería (%1)", Dropover.count)
                        : CachyI18n.i18n("Estantería vacía")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyPalette.textSecondary
                    elide: Text.ElideRight
                }
            }
        }
    ]

    // =========================================================================
    // CABECERA — DERECHA: Cápsula de acciones rápidas Golden Gate
    // =========================================================================
    headerActions: [
        CachyToolbarGroup {
            anchors.verticalCenter: parent.verticalCenter

            // Añadir archivos
            CachyToolbarButton {
                pillStyle: false
                iconName: "add"
                tooltipText: CachyI18n.i18n("Añadir archivos...")
                onClicked: Dropover.openNativeFileDialog()
            }

            // Copiar todas las rutas
            CachyToolbarButton {
                pillStyle: false
                iconName: "copy"
                tooltipText: CachyI18n.i18n("Copiar todas las rutas al portapapeles")
                enabled: Dropover.count > 0
                onClicked: Dropover.copyAllPathsToClipboard()
            }

            // Empaquetar en ZIP en Descargas
            CachyToolbarButton {
                pillStyle: false
                iconName: "download"
                tooltipText: CachyI18n.i18n("Crear archivo ZIP en Descargas")
                enabled: Dropover.count > 0
                onClicked: Dropover.createZipInDownloads()
            }

            // Enviar a la base de conocimiento de Kity
            CachyToolbarButton {
                pillStyle: false
                iconName: "sparkles"
                tooltipText: CachyI18n.i18n("Enviar a la base de conocimiento de Kity")
                enabled: Dropover.count > 0
                onClicked: Dropover.exportShelfToKityKnowledge()
            }

            // Vaciar la estantería
            CachyToolbarButton {
                pillStyle: false
                iconName: "trash"
                tooltipText: CachyI18n.i18n("Vaciar estantería")
                enabled: Dropover.count > 0
                onClicked: Dropover.clearShelf()
            }
        }
    ]

    // =========================================================================
    // CONTENIDO PRINCIPAL: Zona de arrastre y estantería de archivos
    // =========================================================================
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
                spacing: CachyTheme.spacingMedium

                // Mensaje de estado superior
                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 8

                    CachyIcon {
                        name: "info"
                        size: 14
                        color: CachyTheme.accentColor
                    }

                    CachyLabel {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: Dropover.statusMessage.length > 0
                            ? Dropover.statusMessage
                            : CachyI18n.i18n("Arrastra y mantén archivos a mano. Pulsa Espacio para vista previa.")
                        font.pixelSize: 11
                        color: CachyPalette.textSecondary
                        elide: Text.ElideRight
                    }
                }

                // Zona de arrastre y lista de la estantería (CachyCard Liquid Glass reactiva)
                CachyCard {
                    id: shelfCard
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 220

                    // Reacción visual reactiva al arrastrar y soltar
                    border.color: dropArea.containsDrag
                        ? CachyTheme.accentColor
                        : CachyPalette.specularBorder
                    border.width: dropArea.containsDrag ? 2 : 1

                    Behavior on border.color {
                        ColorAnimation { duration: CachyTheme.animFast }
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        MouseArea {
                            anchors.fill: parent
                            enabled: Dropover.count === 0
                            cursorShape: Dropover.count === 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: Dropover.openNativeFileDialog()
                        }

                        // Estado vacío
                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: Dropover.count === 0
                            spacing: 8

                            CachyIcon {
                                name: "folder"
                                size: 42
                                color: dropArea.containsDrag ? CachyTheme.accentColor : CachyPalette.textMuted
                                Layout.alignment: Qt.AlignHCenter
                                scale: dropArea.containsDrag ? 1.15 : 1.0

                                Behavior on scale {
                                    NumberAnimation { duration: CachyTheme.animFast; easing.type: Easing.OutBack }
                                }
                            }

                            CachyLabel {
                                text: dropArea.containsDrag
                                    ? CachyI18n.i18n("¡Suelta los archivos aquí!")
                                    : CachyI18n.i18n("Suelta aquí archivos para la estantería")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: dropArea.containsDrag ? CachyTheme.accentColor : CachyPalette.text
                                Layout.alignment: Qt.AlignHCenter
                            }

                            CachyLabel {
                                text: CachyI18n.i18n("o haz clic aquí para seleccionar desde el explorador")
                                font.pixelSize: 11
                                color: CachyPalette.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // Lista de archivos en la estantería
                        ListView {
                            id: shelfListView
                            anchors.fill: parent
                            spacing: 6
                            visible: Dropover.count > 0
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: Dropover.shelfFiles

                            delegate: Rectangle {
                                id: fileRow
                                required property var modelData
                                required property int index

                                width: shelfListView.width
                                height: 38
                                radius: CachyTheme.radiusSmall
                                color: itemHover.hovered
                                    ? CachyPalette.cardBackgroundHover
                                    : (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03))
                                border.width: 1
                                border.color: itemHover.hovered ? CachyPalette.specularBorder : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: CachyTheme.animFast }
                                }

                                HoverHandler {
                                    id: itemHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                }

                                TapHandler {
                                    acceptedButtons: Qt.RightButton
                                    onTapped: fileContextMenu.popup()
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    CachyIcon {
                                        name: fileRow.modelData.iconName && fileRow.modelData.iconName.length > 0
                                            ? fileRow.modelData.iconName
                                            : "file"
                                        size: 18
                                        color: CachyTheme.accentColor
                                    }

                                    CachyLabel {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: fileRow.modelData.name + " (" + fileRow.modelData.sizeText + ")"
                                        color: CachyPalette.text
                                        elide: Text.ElideMiddle
                                        font.pixelSize: 12
                                    }

                                    // Acciones sobre el archivo individual
                                    Row {
                                        spacing: 4
                                        visible: itemHover.hovered

                                        // Vista previa rápida (Quick Look)
                                        CachyToolbarButton {
                                            iconName: "eye"
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            tooltipText: CachyI18n.i18n("Vista previa rápida")
                                            onClicked: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                        }

                                        // Resumen IA con Kity
                                        CachyToolbarButton {
                                            iconName: "sparkles"
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            tooltipText: CachyI18n.i18n("Resumen IA con Kity")
                                            onClicked: Dropover.summarizeFileWithAi(fileRow.modelData.path)
                                        }

                                        // Abrir externamente
                                        CachyToolbarButton {
                                            iconName: "external-link"
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            tooltipText: CachyI18n.i18n("Abrir con la aplicación predeterminada")
                                            onClicked: Dropover.openFileExternally(fileRow.modelData.path)
                                        }

                                        // Quitar de la estantería
                                        CachyToolbarButton {
                                            iconName: "close"
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            tooltipText: CachyI18n.i18n("Quitar de la estantería")
                                            onClicked: Dropover.removeAt(fileRow.index)
                                        }
                                    }
                                }

                                // Menú contextual CachyMenu
                                CachyMenu {
                                    id: fileContextMenu

                                    CachyMenuItem {
                                        text: CachyI18n.i18n("Vista previa rápida")
                                        iconName: "eye"
                                        onTriggered: Dropover.inspectFileQuickLook(fileRow.modelData.path)
                                    }

                                    CachyMenuItem {
                                        text: CachyI18n.i18n("Resumen ejecutivo IA (Kity)")
                                        iconName: "sparkles"
                                        onTriggered: Dropover.summarizeFileWithAi(fileRow.modelData.path)
                                    }

                                    CachyMenuItem {
                                        text: CachyI18n.i18n("Abrir con app predeterminada")
                                        iconName: "external-link"
                                        onTriggered: Dropover.openFileExternally(fileRow.modelData.path)
                                    }

                                    CachyMenuItem {
                                        text: CachyI18n.i18n("Copiar ruta del archivo")
                                        iconName: "copy"
                                        onTriggered: Dropover.copyAllPathsToClipboard()
                                    }

                                    CachyMenuSeparator {}

                                    CachyMenuItem {
                                        text: CachyI18n.i18n("Quitar de la estantería")
                                        iconName: "trash"
                                        destructive: true
                                        onTriggered: Dropover.removeAt(fileRow.index)
                                    }
                                }
                            }
                        }
                    }
                }

                // Tarjeta de Vista Previa & Resumen IA (CachyCard Liquid Glass)
                CachyCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0

                    contentItem: ColumnLayout {
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 6

                            CachyIcon {
                                name: Dropover.aiSummary.length > 0 ? "sparkles" : "eye"
                                size: 14
                                color: CachyTheme.accentColor
                            }

                            CachyLabel {
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
                            Layout.minimumWidth: 0
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 0
                            clip: true
                            contentWidth: width
                            contentHeight: previewText.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            TextEdit {
                                id: previewText
                                width: parent.width
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                color: CachyPalette.text
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

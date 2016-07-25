// Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
// The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2

import UM 1.2 as UM

UM.Dialog
{
    id: dialog

    title: catalog.i18nc("@title:window", "Post Processing Plugin")
    width: 700 * Screen.devicePixelRatio;
    height: 500 * Screen.devicePixelRatio;
    minimumWidth: 400 * Screen.devicePixelRatio;
    minimumHeight: 250 * Screen.devicePixelRatio;

    Item
    {
        UM.I18nCatalog{id: catalog; name:"cura"}
        id: base
        property int columnWidth: (base.width / 2) - UM.Theme.getSize("default_margin").width
        property int textMargin: UM.Theme.getSize("default_margin").width / 2
        property string activeScriptName
        SystemPalette{ id: palette }
        SystemPalette{ id: disabledPalette; colorGroup: SystemPalette.Disabled }
        anchors.fill: parent

        ExclusiveGroup
        {
            id: selectedScriptGroup
        }
        Rectangle
        {
            id: activeScripts
            anchors.left: parent.left
            width: base.columnWidth
            height: parent.height
            color: "transparent"
            Label
            {
                id: activeScriptsHeader
                text: catalog.i18nc("@label", "Post Processing Scripts")
                anchors.top: parent.top
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                font: UM.Theme.getFont("large")
            }
            ListView
            {
                id: activeScriptsList
                anchors.top: activeScriptsHeader.bottom
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("default_margin").width
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                height: childrenRect.height
                model: manager.scriptList
                delegate: Rectangle
                {
                    width: parent.width
                    height: activeScriptButton.height
                    color: "transparent"
                    Button
                    {
                        id: activeScriptButton
                        text: manager.getScriptLabelByKey(modelData.toString())
                        exclusiveGroup: selectedScriptGroup
                        checkable: true
                        checked: {
                            if (manager.selectedScriptIndex == index)
                            {
                                base.activeScriptName = manager.getScriptLabelByKey(modelData.toString())
                                return true
                            }
                            else
                            {
                                return false
                            }
                        }
                        onClicked:
                        {
                            forceActiveFocus()
                            manager.setSelectedScriptIndex(index)
                            base.activeScriptName = manager.getScriptLabelByKey(modelData.toString())
                        }
                        width: parent.width
                        height: UM.Theme.getSize("setting").height
                        style: ButtonStyle
                        {
                            background: Rectangle
                            {
                                color: activeScriptButton.checked ? palette.highlight : "transparent"
                                width: parent.width
                                height: parent.height
                            }
                            label: Label
                            {
                                wrapMode: Text.Wrap
                                text: control.text
                                color: activeScriptButton.checked ? palette.highlightedText : palette.text
                            }
                        }
                    }
                    Button
                    {
                        id: removeButton
                        text: "x"
                        width: 20
                        height: 20
                        anchors.right:parent.right
                        anchors.rightMargin: base.textMargin
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: manager.removeScriptByIndex(index)
                        style: ButtonStyle
                        {
                            label: Item
                            {
                                UM.RecolorImage
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width / 2.7
                                    height: control.height / 2.7
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: palette.text
                                    source: UM.Theme.getIcon("cross1")
                                }
                            }
                        }
                    }
                    Button
                    {
                        id: downButton
                        text: ""
                        anchors.right: removeButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: index != manager.scriptList.length - 1
                        width: 20
                        height: 20
                        onClicked:
                        {
                            if (manager.selectedScriptIndex == index)
                            {
                                manager.setSelectedScriptIndex(index + 1)
                            }
                            return manager.moveScript(index, index + 1)
                        }
                        style: ButtonStyle
                        {
                            label: Item
                            {
                                UM.RecolorImage
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width / 2.5
                                    height: control.height / 2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: control.enabled ? palette.text : disabledPalette.text
                                    source: UM.Theme.getIcon("arrow_bottom")
                                }
                            }
                        }
                    }
                    Button
                    {
                        id: upButton
                        text: ""
                        enabled: index != 0
                        width: 20
                        height: 20
                        anchors.right: downButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked:
                        {
                            if (manager.selectedScriptIndex == index)
                            {
                                manager.setSelectedScriptIndex(index - 1)
                            }
                            return manager.moveScript(index, index - 1)
                        }
                        style: ButtonStyle
                        {
                            label: Item
                             {
                                UM.RecolorImage
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width / 2.5
                                    height: control.height / 2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: control.enabled ? palette.text : disabledPalette.text
                                    source: UM.Theme.getIcon("arrow_top")
                                }
                            }
                        }
                    }
                }
            }
            Button
            {
                id: addButton
                text: "Add a script"
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin
                anchors.top: activeScriptsList.bottom
                anchors.topMargin: base.textMargin
                menu: scriptsMenu
                style: ButtonStyle
                {
                    label: Label
                    {
                        text: control.text
                    }
                }
            }
            Menu
            {
                id: scriptsMenu

                Instantiator
                {
                    model: manager.loadedScriptList

                    MenuItem
                    {
                        text: manager.getScriptLabelByKey(modelData.toString())
                        onTriggered: manager.addScriptToList(modelData.toString())
                    }

                    onObjectAdded: scriptsMenu.insertItem(index, object);
                    onObjectRemoved: scriptsMenu.removeItem(object);
                }
            }
        }

        Rectangle
        {
            color: UM.Theme.getColor("sidebar")
            anchors.left: activeScripts.right
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            width: base.columnWidth
            height: parent.height
            id:background

            Label
            {
                id: scriptSpecsHeader
                text: manager.selectedScriptIndex == -1 ? catalog.i18nc("@label", "Settings") : base.activeScriptName
                anchors.top: parent.top
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                height: 20
                font: UM.Theme.getFont("large")
                color: UM.Theme.getColor("text")
            }

            ScrollView
            {
                id: scrollView
                anchors.top: scriptSpecsHeader.bottom
                anchors.topMargin: background.textMargin
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: background.textMargin
                anchors.bottom: parent.bottom
                visible: manager.selectedScriptDefinitionId != ""

                ListView
                {
                    id: listview
                    spacing: UM.Theme.getSize("default_lining").height
                    model: UM.SettingDefinitionsModel
                    {
                        id: definitionsModel;
                        containerId: manager.selectedScriptDefinitionId
                        showAll: true
                    }
                    delegate:Loader
                    {
                        id: settingLoader

                        width: parent.width
                        height: model.type != undefined ? UM.Theme.getSize("section").height : 0;

                        property var definition: model
                        property var settingDefinitionsModel: definitionsModel
                        property var propertyProvider: provider

                        //Qt5.4.2 and earlier has a bug where this causes a crash: https://bugreports.qt.io/browse/QTBUG-35989
                        //In addition, while it works for 5.5 and higher, the ordering of the actual combo box drop down changes,
                        //causing nasty issues when selecting different options. So disable asynchronous loading of enum type completely.
                        asynchronous: model.type != "enum" && model.type != "extruder"

                        onLoaded: {
                            settingLoader.item.showRevertButton = true
                            settingLoader.item.showInheritButton = false
                            settingLoader.item.showLinkedSettingIcon = false
                            settingLoader.item.doDepthIndentation = true
                            settingLoader.item.doQualityUserSettingEmphasis = false
                        }

                        source:
                        {
                            switch(model.type) // TODO: This needs to be fixed properly. Got frustrated with it not working, so this is the patch job!
                            {
                                case "int":
                                    return "../../resources/qml/Settings/SettingTextField.qml"
                                case "float":
                                    return "../../resources/qml/Settings/SettingTextField.qml"
                                case "enum":
                                    return "../../resources/qml/Settings/SettingComboBox.qml"
                                case "bool":
                                    return "../../resources/qml/Settings/SettingCheckBox.qml"
                                case "str":
                                    return "../../resources/qml/Settings/SettingTextField.qml"
                                case "category":
                                    return "../../resources/qml/Settings/SettingCategory.qml"
                                default:
                                    return "../../resources/qml/Settings/SettingUnknown.qml"
                            }
                        }

                        UM.SettingPropertyProvider
                        {
                            id: provider
                            containerStackId: manager.selectedScriptStackId
                            key: model.key ? model.key : "None"
                            watchedProperties: [ "value", "enabled", "state", "validationState" ]
                            storeIndex: 0
                        }
                    }
                }
            }
        }

        Tooltip
        {
            id:tooltip
        }
    }
    rightButtons: Button
    {
        text: catalog.i18nc("@action:button", "Close")
        iconName: "dialog-close"
        onClicked: dialog.accept()
    }
}
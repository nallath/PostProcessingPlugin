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
    width: 1000 * Screen.devicePixelRatio;
    height: 500 * Screen.devicePixelRatio;
    minimumWidth: 500 * Screen.devicePixelRatio;
    minimumHeight: 250 * Screen.devicePixelRatio;

    Item
    {
        UM.I18nCatalog{id: catalog; name:"PostProcessingPlugin"}
        id: base
        property int widthUnity: (base.width / 3) - (UM.Theme.getSize("default_margin").width * 2) - (doneButton.width/3)
        property int textMargin: UM.Theme.getSize("default_margin").width / 2
        property int arrowMargin: UM.Theme.getSize("default_margin").width * 2
        property string activeScript
        SystemPalette{ id: palette }
        anchors.fill: parent
        ExclusiveGroup
        {
            id: selected_loaded_script_group
        }
        Rectangle
        {
            id: scripts
            color: "white"
            width: base.widthUnity
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            Label
            {
                id: scriptsHeader
                text: catalog.i18nc("@label", "Scripts")
                anchors.top: parent.top
                anchors.topMargin: base.textMargin + 6
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin + 6
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                color: UM.Theme.styles.setting_item.controlTextColor;
                font: UM.Theme.fonts.default_header
            }
            ListView
            {
                anchors.top: scriptsHeader.bottom
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("default_margin").width
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                anchors.bottom: parent.bottom
                model: manager.loadedScriptList
                delegate: Rectangle
                {
                    color:"transparent"
                    width: parent.width
                    height: loaded_script_button.height
                    Button
                    {
                        id: loaded_script_button
                        text: manager.getScriptLabelByKey(modelData.toString())
                        exclusiveGroup: selected_loaded_script_group
                        checkable: true
                        width: parent.width
                        height: UM.Theme.getSize("setting").height
                        style: ButtonStyle
                        {
                            background:Rectangle
                            {
                                color: loaded_script_button.checked ? UM.Theme.getColor("setting_category_active") : "transparent"
                                width: parent.width
                                height: parent.height
                            }
                            label: Text
                            {
                                wrapMode: Text.Wrap
                                text: control.text
                                color: UM.Theme.styles.setting_item.controlTextColor;
                                font: UM.Theme.styles.setting_item.controlFont;
                            }
                        }
                        Button
                        {
                            text: "+"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: UM.Theme.getSize("default_margin").width/2
                            width: 20
                            height: 20
                            onClicked:
                            {
                                loaded_script_button.checked = true
                                manager.addScriptToList(modelData.toString())
                            }
                        }
                    }
                }
            }
        }

        ExclusiveGroup
        {
            id: selected_script_group
        }
        Rectangle{
            anchors.left: scripts.right
            height: parent.height
            width: base.arrowMargin
            color: "transparent"
            UM.RecolorImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width/2
                height: parent.width/2
                sourceSize.width: width
                sourceSize.height: width
                color: palette.text
                source: UM.Theme.icons.arrow_right
            }
        }
        Rectangle
        {
            id: activeScripts
            anchors.left: scripts.right
            anchors.leftMargin: base.arrowMargin
            width: base.widthUnity
            height: parent.height
            Label
            {
                id: activeScriptsHeader
                text: catalog.i18nc("@label", "Active Scripts")
                anchors.top: parent.top
                anchors.topMargin: base.textMargin + 6
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin + 6
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                color: UM.Theme.styles.setting_item.controlTextColor;
                font: UM.Theme.fonts.default_header
            }
            ListView
            {
                anchors.top: activeScriptsHeader.bottom
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: UM.Theme.getSize("default_margin").width
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                anchors.bottom: parent.bottom
                model: manager.scriptList
                delegate: Rectangle
                {
                    width: parent.width
                    height: active_script_button.height
                    Button
                    {
                        id: active_script_button
                        text: manager.getScriptLabelByKey(modelData.toString())
                        exclusiveGroup: selected_script_group
                        checkable: true
                        checked: {
                            if (manager.selectedScriptIndex == index)
                            {
                                base.activeScript = manager.getScriptLabelByKey(modelData.toString())
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
                            base.activeScript = manager.getScriptLabelByKey(modelData.toString())
                        }
                        width: parent.width
                        height: UM.Theme.getSize("setting").height
                        style: ButtonStyle
                        {
                            background: Rectangle
                            {
                                color: active_script_button.checked ? UM.Theme.getColor("setting_category_active") : "transparent"
                                width: parent.width
                                height: parent.height
                            }
                            label: Text
                            {
                                wrapMode: Text.Wrap
                                text: control.text
                                color: UM.Theme.styles.setting_item.controlTextColor;
                                font: UM.Theme.styles.setting_item.controlFont;
                            }
                        }
                    }
                    Button
                    {
                        id: remove_button
                        text: "x"
                        width: 20
                        height:20
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
                                    width: control.width/2.7
                                    height: control.height/2.7
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor;
                                    source: UM.Theme.getIcon("cross1")
                                }
                            }
                        }
                    }
                    Button
                    {
                        id: down_button
                        text: ""
                        anchors.right: remove_button.left
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: index != manager.scriptList.length-1
                        opacity: enabled ? 1.0 : 0.3
                        width: 20
                        height:20
                        onClicked:
                        {
                            if (manager.selectedScriptIndex == index)
                            {
                                manager.setSelectedScriptIndex(index+1)
                            }
                            return manager.moveScript(index,index+1)
                        }
                        style: ButtonStyle
                        {
                            label: Item
                            {
                                UM.RecolorImage
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width/2.5
                                    height: control.height/2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor
                                    source: UM.Theme.getIcon("arrow_bottom")
                                }
                            }
                        }
                    }
                    Button
                    {
                        id: up_button
                        text:""
                        enabled: index != 0
                        opacity: enabled ? 1.0 : 0.3
                        width: 20
                        height: 20
                        anchors.right: down_button.left
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked:
                        {
                            if (manager.selectedScriptIndex == index)
                            {
                                manager.setSelectedScriptIndex(index-1)
                            }
                            return manager.moveScript(index,index-1)
                        }
                        style: ButtonStyle
                        {
                            label: Item
                             {
                                UM.RecolorImage
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width/2.5
                                    height: control.height/2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor;
                                    source: UM.Theme.getIcon("arrow_top")
                                }
                            }
                        }
                    }
                }
            }
        }
        Rectangle
        {
            anchors.left: activeScripts.right
            height: parent.height
            width: base.arrowMargin
            color: "transparent"
            UM.RecolorImage
            {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width/2
                height: parent.width/2
                sourceSize.width: width
                sourceSize.height: width
                color: palette.text
                source: UM.Theme.getIcon("arrow_right")
            }
        }
        Rectangle
        {
            color: "white"
            anchors.left: activeScripts.right
            anchors.leftMargin: base.arrowMargin
            width: base.widthUnity
            height: parent.height
            id:background

            Label
            {
                id: scriptSpecsHeader
                visible: manager.selectedScriptIndex != -1
                text: manager.selectedScriptIndex == -1 ? "" : base.activeScriptName
                anchors.top: parent.top
                anchors.topMargin: base.textMargin + 6
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin + 6
                anchors.right: parent.right
                anchors.rightMargin: base.textMargin
                height: 20
                color: UM.Theme.styles.setting_item.controlTextColor;
                font: UM.Theme.getFont("default_bold")
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

                ListView
                {
                    id: listview
                    model: UM.SettingDefinitionsModel
                    {
                        id: definitionsModel;
                        containerId: manager.selectedScriptDefinitionId
                        showAll: true
                    }
                    delegate:Loader
                    {
                        id: loader

                        width: parent.width
                        height: model.type != undefined ? UM.Theme.getSize("section").height : 0;

                        property var definition: model
                        property var settingDefinitionsModel: definitionsModel
                        property var propertyProvider: provider

                        asynchronous: true
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

        Rectangle
        {
            id: doneButtonId
            anchors.left: settings.right
            height: parent.height
            width: doneButton.width + UM.Theme.getSize("default_margin").width
            color: "transparent"
            Button
            {
                id: doneButton
                text:catalog.i18nc("@label", "Done")
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                onClicked: {
                    dialog.visible = false;
                }
            }
        }
        Tooltip
        {
            id:tooltip
        }
    }
}
// Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
// The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2

import UM 1.1 as UM

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
        property int widthUnity: (base.width / 3) - (UM.Theme.sizes.default_margin.width * 2) - (doneButton.width/3)
        property int textMargin: UM.Theme.sizes.default_margin.width / 2
        property int arrowMargin: UM.Theme.sizes.default_margin.width * 2
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
            anchors.leftMargin: UM.Theme.sizes.default_margin.width
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
                anchors.leftMargin: UM.Theme.sizes.default_margin.width
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
                        height: UM.Theme.sizes.setting.height
                        style: ButtonStyle
                        {
                            background:Rectangle
                            {
                                color: loaded_script_button.checked ? UM.Theme.colors.setting_category_active : "transparent"
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
                            anchors.rightMargin: UM.Theme.sizes.default_margin.width/2
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
        /*Button
        {
            text:"Execute"
            width: 250
            height: 30
            onClicked:manager.execute()
        }*/
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
                anchors.leftMargin: UM.Theme.sizes.default_margin.width
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
                            if (manager.selectedScriptIndex == index){
                                base.activeScript = manager.getScriptLabelByKey(modelData.toString())
                                return true
                            }
                            else {
                                return false
                            }
                        }
                        onClicked: {
                            manager.setSelectedScriptIndex(index)
                            base.activeScript = manager.getScriptLabelByKey(modelData.toString())
                        }
                        width: parent.width
                        height: UM.Theme.sizes.setting.height
                        style: ButtonStyle
                        {
                            background: Rectangle
                            {
                                color: active_script_button.checked ? UM.Theme.colors.setting_category_active : "transparent"
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
                        style: ButtonStyle {
                            label: Item {
                                UM.RecolorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width/2.7
                                    height: control.height/2.7
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor;
                                    source: UM.Theme.icons.cross1
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
                        onClicked: {
                            if (manager.selectedScriptIndex == index){
                                manager.setSelectedScriptIndex(index+1)
                            }
                            return manager.moveScript(index,index+1)
                        }
                        style: ButtonStyle {
                            label: Item {
                                UM.RecolorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width/2.5
                                    height: control.height/2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor
                                    source: UM.Theme.icons.arrow_bottom
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
                        onClicked: {
                            if (manager.selectedScriptIndex == index){
                                manager.setSelectedScriptIndex(index-1)
                            }
                            return manager.moveScript(index,index-1)
                        }
                        style: ButtonStyle {
                            label: Item {
                                UM.RecolorImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: control.width/2.5
                                    height: control.height/2.5
                                    sourceSize.width: width
                                    sourceSize.height: width
                                    color: UM.Theme.styles.setting_item.controlTextColor;
                                    source: UM.Theme.icons.arrow_top
                                }
                            }
                        }
                    }
                }
            }
        }
        Rectangle{
            anchors.left: activeScripts.right
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
        SingleCategorySettingPanel
        {
            id: settings
            anchors.left: activeScripts.right
            anchors.leftMargin: base.arrowMargin
            setting_model: manager.selectedScriptSettingsModel
            panelWidth: base.widthUnity
            panelHeight: parent.height
            activeScriptName: base.activeScript
        }

        Rectangle{
            id: doneButtonId
            anchors.left: settings.right
            height: parent.height
            width: doneButton.width + UM.Theme.sizes.default_margin.width
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
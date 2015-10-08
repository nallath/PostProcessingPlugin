// Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
// The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2

import UM 1.0 as UM

UM.Dialog
{
    id: dialog

    width: 1000 * Screen.devicePixelRatio;
    height: 500 * Screen.devicePixelRatio;
    minimumWidth: 500 * Screen.devicePixelRatio;
    minimumHeight: 250 * Screen.devicePixelRatio;

    Item
    {
        id: base
        property int widthUnity: (base.width / 3) - (UM.Theme.sizes.default_margin.width * 2) - (doneButton.width/3)
        property int textMargin: UM.Theme.sizes.default_margin.height / 2
        property int arrowMargin: UM.Theme.sizes.default_margin.width * 2
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
            ScrollView
            {
                anchors.fill: parent
                ListView
                {
                    anchors.top: parent.top
                    anchors.topMargin: base.textMargin
                    anchors.left: parent.left
                    anchors.leftMargin: base.textMargin
                    anchors.right: parent.right
                    anchors.rightMargin: base.textMargin
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
                                    font: UM.Theme.styles.setting_item.labelFont;
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
            ListView
            {
                anchors.top: parent.top
                anchors.topMargin: base.textMargin
                anchors.left: parent.left
                anchors.leftMargin: base.textMargin
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
                        checked: manager.selectedScriptIndex == index ? true : false
                        onClicked: manager.setSelectedScriptIndex(index)
                        width: parent.width
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
                                renderType: Text.NativeRendering
                                text: control.text
                                color: UM.Theme.styles.setting_item.controlTextColor;
                                font: UM.Theme.styles.setting_item.labelFont;
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
                    }
                    Button
                    {
                        id: down_button
                        text: "-"
                        anchors.right: remove_button.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height:20
                        onClicked: manager.moveScript(index,index+1)
                    }
                    Button
                    {
                        id: up_button
                        text:"+"
                        width: 20
                        height: 20
                        anchors.right: down_button.left
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: manager.moveScript(index,index-1)
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
                text:"Done!"
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                onClicked: {
                    dialog.visible = false;
                    manager.execute()
                }
            }
        }
        Tooltip
        {
            id:tooltip
        }
    }
}
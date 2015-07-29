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
    width: 500 * Screen.devicePixelRatio;
    height: 500 * Screen.devicePixelRatio;
    Item
    {
        id: base
        anchors.fill: parent
        ExclusiveGroup
        {
            id: selected_loaded_script_group
        }
        Row 
        {
            Column
            {
                Rectangle 
                {
                    color: "white"
                    border.width: 1
                    border.color: "black"
                    width: 250
                    height: 100
                    ScrollView
                    {
                        anchors.fill: parent
                        ListView
                        {
                            anchors.top: parent.top
                            anchors.topMargin: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.right: parent.right
                            anchors.rightMargin: 2
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            model: manager.loadedScriptList 
                            delegate: Rectangle 
                            {
                                color:"transparent"
                                width:parent.width
                                height:20
                                Button
                                {
                                    id: script_button
                                    text: manager.getScriptLabelByKey(modelData.toString())
                                    exclusiveGroup: selected_loaded_script_group
                                    checkable: true
                                    width: parent.width
                                    style: ButtonStyle 
                                    {
                                        background:Rectangle 
                                        {
                                            color: script_button.checked ? "blue":"white"
                                            implicitWidth: parent.width
                                            implicitHeight: parent.height
                                        }
                                    }
                                    Button
                                    {
                                        text: "+"
                                        anchors.right: parent.right
                                        width: 20
                                        height: 20
                                        onClicked: 
                                        {
                                            manager.addScriptToList(modelData.toString())
                                        }
                                    }
                                }

                            }
                        }
                    }
                }
                Item 
                {
                    width: UM.Theme.sizes.default_margin.width
                    height: UM.Theme.sizes.default_margin.height
                }
                SingleCategorySettingPanel
                {
                    //Component.onCompleted: console.log(manager.getSettingModel(0))
                    setting_model: manager.selectedScriptSettingsModel  
                    width: 250
                    height: 300
                    //model:manager.getSettingModel(0)
                }
            }
            Item 
            {
                width: UM.Theme.sizes.default_margin.width
                height: UM.Theme.sizes.default_margin.height
            }
            ExclusiveGroup
            {
                id: selected_script_group
            }
            Rectangle 
            {
                width: 150
                height: 500
                ListView
                {
                    anchors.fill:parent
                    model: manager.scriptList 
                    delegate: Rectangle 
                    {
                        width: 150
                        height:50
                        Button
                        {
                            text: manager.getScriptLabelByKey(modelData.toString())
                            exclusiveGroup: selected_script_group
                            checkable: true
                            checked: manager.selectedScriptIndex == index ? true : false
                            onClicked: manager.setSelectedScriptIndex(index)
                        }
                        Button
                        {
                            id: down_button
                            text: "-"
                            anchors.right:parent.right
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
                            onClicked: manager.moveScript(index,index-1)
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
}
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
                            anchors.fill: parent
                            model: manager.scriptList 
                            delegate: Rectangle 
                            {
                                x:2
                                color:"transparent"
                                width:50
                                height:20
                                Text 
                                {
                                    text: manager.getScriptLabelByKey(modelData.toString())
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
            Rectangle 
            {
                width: 150
                height: 500
            }
        }
        Tooltip
        {
            id:tooltip
        }
    }
}
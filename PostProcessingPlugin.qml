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
    width: 250 * Screen.devicePixelRatio;
    height: 110 * Screen.devicePixelRatio;
    ListView
    {
        width: 100
        height: 250
        model:manager.scriptList
        delegate:Rectangle {
            color:"transparent"
            width:50
            height:20
            Text {
                text: manager.getScriptLabelByKey(modelData.toString())
            }
        }
    }
    //Instantiator 
    //{
    //    model: manager.scriptList
       
    //}
}
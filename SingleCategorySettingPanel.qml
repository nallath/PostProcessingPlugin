// Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
// The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.1

import UM 1.0 as UM
Rectangle
{
    Layout.maximumWidth: parent.width
    Layout.minimumWidth: parent.width
    color: "#D8DEE6"
    height: 326
    id: background
    property variant setting_model
    property variant base_item: base;
    ScrollView 
    {
        id: scrollview_base;

        style: UM.Theme.styles.scrollview;

        property Action configureSettings;
        //signal showTooltip(Item item, point location, string text);
        //signal hideTooltip();
        
        function showTooltip(item, position, text) 
        {
            tooltip.text = text;
            position = item.mapToItem(base_item, position.x, position.y);
            tooltip.show(position);
        }

        function hideTooltip() 
        {
            tooltip.hide();
        }
        anchors.topMargin: 5
        anchors.leftMargin: 5
        anchors.bottomMargin: 5
        anchors.rightMargin: 5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        Column
        {
            
            property real childrenHeight: 
            {
                var h = 0.0;
                for(var i in children) 
                {
                    var item = children[i];
                    h += children[i].height;   
                    if(item.settingVisible) 
                    {
                        if(i > 0) 
                        {
                            h += spacing;
                        }
                    }
                }
                return h;
            }
            height: childrenHeight;

            Repeater 
            {
                model: setting_model

                delegate: UM.SettingItem 
                {
                    id: item;

                    width: background.parent.width / 1.2;
                    height: model.visible ? UM.Theme.sizes.setting.height : 0;
                    Behavior on height { NumberAnimation { duration: 75; } }
                    //Component.onCompleted :{console.log(height)}
                    opacity: model.visible ? 1 : 0;
                    Behavior on opacity { NumberAnimation { duration: 75; } }
                    enabled: model.visible;

                    property bool settingVisible: model.visible;

                    name: model.name;
                    description: model.description;
                    value: model.value;
                    unit: model.unit;
                    valid: model.valid;
                    type: model.type;
                    options: model.type == "enum" ? model.options : null;
                    key: model.key;

                    style: UM.Theme.styles.setting_item;

                    onItemValueChanged: 
                    { 
                        //background.setting_model.setSettingValue(index, model.key, value);
                        manager.setSettingValue(model.key,value)
                    }
                    onContextMenuRequested: contextMenu.popup();

                    onShowTooltip: 
                    {
                        position = Qt.point(0, item.height);
                        scrollview_base.showTooltip(item, position, model.description)
                    }
                    onHideTooltip: scrollview_base.hideTooltip()
                    Menu 
                    {
                        id: contextMenu;

                        MenuItem 
                        {
                            //: Settings context menu action
                            text: qsTr("Hide this setting");
                            onTriggered: background.setting_model.hideSetting(model.key);
                        }
                        MenuItem 
                        {
                            //: Settings context menu action
                            text: qsTr("Configure setting visiblity...");
                            onTriggered: if(base.configureSettings) base.configureSettings.trigger();
                        }
                    }
                }
            }  
        }
    }
}
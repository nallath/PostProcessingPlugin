// Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
// The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.1

import UM 1.1 as UM
Rectangle
{
    //color: "#D8DEE6"
    color: "white"
    id: background
    property variant setting_model
    property variant base_item: base;
    property int panelWidth
    property int panelHeight
    property int textMargin: UM.Theme.sizes.default_margin.height / 2

    width: background.panelWidth
    height: background.panelHeight
    UM.I18nCatalog { id: catalog; name:"cura"}
    ScrollView
    {
        id: scrollview_base;

        style: UM.Theme.styles.scrollview;
        width: parent.width
        height: background.panelHeight

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
        Column
        {
            anchors.top: parent.top
            anchors.topMargin: background.textMargin
            anchors.left: parent.left
            anchors.leftMargin: background.textMargin
            anchors.right: parent.right
            anchors.rightMargin: background.textMargin

            Repeater
            {
                model: setting_model

                delegate: UM.SettingItem
                {
                    id: item;
                    width: background.width - UM.Theme.sizes.default_margin.width
                    height: model.visible && model.enabled ? UM.Theme.sizes.setting.height : 0;
                    Behavior on height { NumberAnimation { duration: 75; } }
                    //Component.onCompleted :{console.log(height)}
                    opacity: model.visible && model.enabled ? 1 : 0;
                    Behavior on opacity { NumberAnimation { duration: 75; } }
                    enabled: model.visible && model.enabled;

                    property bool settingVisible: model.visible;

                    Rectangle{
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: parent.height
                        color: "transparent"
                    }

                    name: model.name;
                    description: model.description;
                    value: model.value;
                    unit: model.unit;
                    valid: model.valid;
                    type: model.type;
                    options: model.type == "enum" ? model.options : null;
                    key: model.key;

                    label.anchors.leftMargin: 0

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
                            text: catalog.i18nc("@action:menu","Hide this setting");
                            onTriggered: background.setting_model.hideSetting(model.key);
                        }
                        MenuItem
                        {
                            //: Settings context menu action
                            text: catalog.i18nc("@action:menu","Configure setting visiblity...");
                            onTriggered: if(base.configureSettings) base.configureSettings.trigger();
                        }
                    }
                }
            }
        }
    }
}
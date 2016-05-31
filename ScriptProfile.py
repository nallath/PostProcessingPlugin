# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.

from UM.Signal import Signal, signalemitter

@signalemitter
class ScriptProfile():
    def __init__(self, script):
        super().__init__()
        self._changed_settings = {}
        self._script = script
        pass

    def setSettingValue(self, key, value):
        if key in self._changed_settings and self._changed_settings[key] == value:
            return

        self._changed_settings[key] = value
        self.settingValueChanged.emit(key)

    settingValueChanged = Signal()

    def isReadOnly(self):
        return False

    def hasSettingValue(self, key, filter_defaults = True):
        return key in self._changed_settings

    def getSettingValue(self, key):
        setting = self._script.getSettingByKey(key)
        if not setting:
            return None

        if key in self._changed_settings:
            return setting.parseValue(self._changed_settings[key])
        return setting.getDefaultValue()

    settingValueUnusedChanged = Signal()

    def checkValueUnused(self, setting):
        return False

    def updateUnusedValues(self, setting):
        return
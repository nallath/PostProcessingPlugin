# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
from UM.Logger import Logger
from UM.Signal import Signal, signalemitter
from UM.i18n import i18nCatalog
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.ContainerStack import ContainerStack
from UM.Settings.ContainerRegistry import ContainerRegistry
from UM.Settings.InstanceContainer import InstanceContainer

import json

import re
i18n_catalog = i18nCatalog("PostProcessingPlugin")


## Base class for scripts. All scripts should inherit the script class.
@signalemitter
class Script():
    def __init__(self):
        super().__init__()
        self._stack = None
        self._definition = None

        try:
            setting_data = self.getSettingData()
            if "key" in setting_data:
                self._stack = ContainerStack(id(self))
                self._definition = DefinitionContainer(str(id(self)) + "_definition")
                self._definition.deserialize(json.dumps(setting_data))
                self._stack.addContainer(self._definition)
                self._stack.addContainer(InstanceContainer(str(id(self)) + "_instance"))
                ContainerRegistry.getInstance().addContainer(self._definition)
                ContainerRegistry.getInstance().addContainer(self._stack)
                # Emit the event before the settings model is sorted, but after settings is created.
                #self.activeProfileChanged.emit()
                #self._settings_model = SettingsFromCategoryModel(self._settings, machine_manager = self)
                #self._settings_model.sort(lambda t: t["key"])
                #self.settingsLoaded.emit()
            else:
                Logger.log("e", "Script has no key in meta data. Unable to use.")
        except NotImplementedError:
            pass 

    settingsLoaded = Signal()
    activeProfileChanged = Signal()

    ##  Needs to return a dict that can be used to construct a settingcategory file. 
    #   See the example script for an example.
    #   It follows the same style / guides as the Uranium settings.
    def getSettingData(self):
        raise NotImplementedError()
    
    def getValue(self, line, key, default = None):
        if not key in line or (';' in line and line.find(key) > line.find(';')):
            return default
        sub_part = line[line.find(key) + 1:]
        m = re.search('^[0-9]+\.?[0-9]*', sub_part)
        if m is None:
            return default
        try:
            return float(m.group(0))
        except:
            return default

    def getDefinitionId(self):
        return self._definition.getId()

    def getStackId(self):
        return self._stack.getId()


    ##  Get setting by key. (convenience function)
    #   \param key Key to select setting by (string)
    #   \return Setting or none if no setting was found.
    def getSettingByKey(self, key):
        pass
    
    ##  Set the value of a setting by key.
    #   \param key Key of setting to change.
    #   \param value value to set.
    def setSettingValueByKey(self, key, value):
        pass

    ##  Get the value of setting by key.
    #   \param key Key of the setting to get value from
    #   \return value (or none)
    def getSettingValueByKey(self, key):
        pass
    
    ##  This is called when the script is executed. 
    #   It gets a list of g-code strings and needs to return a (modified) list.
    def execute(self, data):
        raise NotImplementedError()
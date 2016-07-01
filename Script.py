# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
from UM.Logger import Logger
from UM.Signal import Signal, signalemitter
from UM.i18n import i18nCatalog

# Setting stuff import
from UM.Settings.ContainerStack import ContainerStack
from UM.Settings.InstanceContainer import InstanceContainer
from UM.Settings.DefinitionContainer import DefinitionContainer
from UM.Settings.ContainerRegistry import ContainerRegistry

import re
import json
i18n_catalog = i18nCatalog("PostProcessingPlugin")


## Base class for scripts. All scripts should inherit the script class.
@signalemitter
class Script:
    def __init__(self):
        super().__init__()
        self._settings = None
        self._stack = None

        setting_data = self.getSettingData()
        self._stack = ContainerStack(stack_id=id(self))
        self._stack.setDirty(False)  # This stack does not need to be saved.


        ## Check if the definition of this script already exists. If not, add it to the registry.
        if "key" in setting_data:
            definitions = ContainerRegistry.getInstance().findDefinitionContainers(id = setting_data["key"])
            if definitions:
                # Definition was found
                self._definition = definitions[0]
            else:
                self._definition = DefinitionContainer(setting_data["key"])
                self._definition.deserialize(json.dumps(setting_data))
                ContainerRegistry.getInstance().addContainer(self._definition)
        self._stack.addContainer(self._definition)
        self._instance = InstanceContainer(container_id="ScriptInstanceContainer")
        self._instance.setDefinition(self._definition)
        self._stack.addContainer(self._instance)

        ContainerRegistry.getInstance().addContainer(self._stack)

    settingsLoaded = Signal()

    ##  Needs to return a dict that can be used to construct a settingcategory file. 
    #   See the example script for an example.
    #   It follows the same style / guides as the Uranium settings.
    def getSettingData(self):
        raise NotImplementedError()

    def getDefinitionId(self):
        if self._stack:
            return self._stack.getBottom().getId()

    def getStackId(self):
        if self._stack:
            return self._stack.getId()
    
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

    ##  This is called when the script is executed. 
    #   It gets a list of g-code strings and needs to return a (modified) list.
    def execute(self, data):
        raise NotImplementedError()
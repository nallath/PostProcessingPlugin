# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.

## Base class for scripts. All scripts should inherit the script class. 
class Script():
    def __init__(self):
        super().__init__()
    
    ##  Needs to return a dict of settings. 
    #   See the example script for an example.
    #   It follows the same style / guides as the Uranium settings.
    def getSettingData(self):
        raise NotImplementedError()
    
    ##  This is called when the script is executed. 
    #   It gets a list of g-code strings and needs to return a (modified) list.
    def execute(self, data):
        raise NotImplementedError()
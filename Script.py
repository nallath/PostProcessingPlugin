# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
class Script():
    def __init__(self):
        super().__init__()
        
    def getSettingData(self):
        raise NotImplementedError()
    
    def execute(self, data):
        raise NotImplementedError()
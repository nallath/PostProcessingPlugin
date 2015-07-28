class Script():
    def __init__(self):
        super().__init__()
        
    def getSettingData(self):
        raise NotImplementedError()
    
    def execute(self, data):
        raise NotImplementedError()
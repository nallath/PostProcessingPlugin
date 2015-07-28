from ..Script import Script

class ExampleScript(Script):
    def __init__(self):
        super().__init__()
        
    def getSettingData(self):
        return 
        { 
            "label":"Example script",
            "settings": 
            {
                "test": 
                {
                    "label": "Test",
                    "description": "None",
                    "unit": "mm",
                    "type": "float",
                    "default": 0.5,
                    "min_value": 0,
                    "min_value_warning": 0.1,
                    "max_value_warning": 1,
                    "visible": True
                }
            }
        }
    
    def execute(self, data):
        return data
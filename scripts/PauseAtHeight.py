from ..Script import Script
class PauseAtHeight(Script):
    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name":"Pause at height",
            "key": "PauseAtHeight",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "pause_height":
                {
                    "label": "Pause height",
                    "description": "At what height should the pause occur",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 5.0
                },
                "head_park_x":
                {
                    "label": "Head park X",
                    "description": "What x location does the head move to when pausing.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 190
                },
                "head_park_y":
                {
                    "label": "Head park Y",
                    "description": "What y location does the head move to when pausing.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 190
                },
                "retraction_ammount":
                {
                    "label": "Retraction",
                    "description": "How much fillament must be retracted at pause.",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0
                }
            }
        }"""

    def execute(self, data):
        x = 0.
        y = 0.
        current_z = 0.
        pause_z = self.getSettingValueByKey("pause_height")
        retraction_ammount = self.getSettingValueByKey("retraction_ammount")
        park_x = self.getSettingValueByKey("head_park_x")
        park_y = self.getSettingValueByKey("head_park_y")
        layers_started = False
        for layer in data: 
            lines = layer.split("\n")
            for line in lines:
                if ";LAYER:0" in line:
                    layers_started = True
                    continue

                if not layers_started:
                    continue

                if self.getValue(line, 'G') == 1 or self.getValue(line, 'G') == 0:
                    current_z = self.getValue(line, 'Z')
                    x = self.getValue(line, 'X', x)
                    y = self.getValue(line, 'Y', y)
                    if current_z != None:
                        if current_z >= pause_z:
                            prepend_gcode = ";TYPE:CUSTOM\n"
                            
                            #Retraction
                            prepend_gcode += "M83\n"
                            prepend_gcode += "G1 E-%f F6000\n" % (retraction_ammount)
                            
                            #Move the head away
                            prepend_gcode += "G1 X%f Y%f F9000\n" % (park_x, park_y) 
                            if current_z < 15:
                                prepend_gcode += "G1 Z15 F300\n"
                            
                            #Disable the E steppers
                            prepend_gcode += "M84 E0\n"
                            #Wait till the user continues printing
                            prepend_gcode += "M0 ;Do the actual pause\n"
                            
                            #Push the filament back, and retract again, the properly primes the nozzle when changing filament.
                            prepend_gcode += "G1 E%f F6000\n" % (retraction_ammount)
                            prepend_gcode += "G1 E-%f F6000\n" % (retraction_ammount)
                            #Move the head back
                            if current_z < 15:
                                prepend_gcode += "G1 Z%f F300\n" % (current_z + 1)
                            prepend_gcode +="G1 X%f Y%f F9000\n" % (x, y)
                            prepend_gcode +="G1 E%f F6000\n" % (retraction_ammount)
                            prepend_gcode +="G1 F9000\n"
                            prepend_gcode +="M82\n"
                            index = data.index(layer) 
                            layer = prepend_gcode + layer
                            data[index] = layer #Override the data of this layer with the modified data
                            return data
                        break
        return data

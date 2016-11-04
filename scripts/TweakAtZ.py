# TweakAtZ script - Change printing parameters at a given height
# This script is the successor of the TweakAtZ plugin for legacy Cura.
# It contains code from the TweakAtZ plugin V1.0-V4.x and from the ExampleScript by Jaime van Kessel, Ultimaker B.V.
# It runs with the PostProcessingPlugin which is released under the terms of the AGPLv3 or higher.
# This script is licensed under the Creative Commons - Attribution - Share Alike (CC BY-SA) terms

#Authors of the TweakAtZ plugin / script:
# Written by Steven Morlock, smorloc@gmail.com
# Modified by Ricardo Gomez, ricardoga@otulook.com, to add Bed Temperature and make it work with Cura_13.06.04+
# Modified by Stefan Heule, Dim3nsioneer@gmx.ch since V3.0 (see changelog below)
# Modified by Jaime van Kessel (Ultimaker), j.vankessel@ultimaker.com to make it work for 15.10 / 2.x

##history / changelog:
##V3.0.1: TweakAtZ-state default 1 (i.e. the plugin works without any TweakAtZ comment)
##V3.1:   Recognizes UltiGCode and deactivates value reset, fan speed added, alternatively layer no. to tweak at,
##        extruder three temperature disabled by "#Ex3"
##V3.1.1: Bugfix reset flow rate
##V3.1.2: Bugfix disable TweakAtZ on Cool Head Lift
##V3.2:   Flow rate for specific extruder added (only for 2 extruders), bugfix parser,
##        added speed reset at the end of the print
##V4.0:   Progress bar, tweaking over multiple layers, M605&M606 implemented, reset after one layer option,
##        extruder three code removed, tweaking print speed, save call of Publisher class,
##        uses previous value from other plugins also on UltiGCode
##V4.0.1: Bugfix for doubled G1 commands
##V4.0.2: uses Cura progress bar instead of its own
##V4.0.3: Bugfix for cool head lift (contributed by luisonoff)
##V4.9.91: First version for Cura 15.06.x and PostProcessingPlugin
##V4.9.92: Modifications for Cura 15.10
##V4.9.93: Minor bugfixes (input settings) / documentation
##V4.9.94: Bugfix Combobox-selection; remove logger
##V5.0:   Bugfix for fall back after one layer and doubled G0 commands when using print speed tweak, Initial version for Cura 2.x
##V5.0.1: Bugfix for calling unknown property 'bedTemp' of previous settings storage and unkown variable 'speed'
##V5.1:   API Changes included for use with Cura 2.2

## Uses -
## M220 S<factor in percent> - set speed factor override percentage
## M221 S<factor in percent> - set flow factor override percentage
## M221 S<factor in percent> T<0-#toolheads> - set flow factor override percentage for single extruder
## M104 S<temp> T<0-#toolheads> - set extruder <T> to target temperature <S>
## M140 S<temp> - set bed target temperature
## M106 S<PWM> - set fan speed to target speed <S>
## M605/606 to save and recall material settings on the UM2

from ..Script import Script
#from UM.Logger import Logger
import re


class TweakAtZ(Script):
    version = "5.1"

    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name":"TweakAtZ """ + self.version + """",
            "key":"TweakAtZ",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "a_trigger":
                {
                    "label": "Trigger type",
                    "description": "Trigger at height or at layer number",
                    "type": "enum",
                    "options":
                    {
                        "height":"Height",
                        "layer_no":"Layer Number"
                    },
                    "default_value": "height"
                },
                "b_targetZ":
                {
                    "label": "Tweak Height",
                    "description": "Z height to tweak at",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 5.0,
                    "minimum_value": "0",
                    "minimum_value_warning": "0.1",
                    "maximum_value_warning": "230",
                    "enabled": "a_trigger == 'height'"
                },
                "b_targetL":
                {
                    "label": "Tweak Layer",
                    "description": "Layer no. to tweak at",
                    "unit": "",
                    "type": "int",
                    "default_value": 1,
                    "minimum_value": "-100",
                    "minimum_value_warning": "-1",
                    "enabled": "a_trigger == 'layer_no'"
                },
                "c_behavior":
                {
                    "label": "Behavior",
                    "description": "Select behavior: Tweak value and keep it for the rest, Tweak value for single layer only",
                    "type": "enum",
                    "options":
                    {
                        "keep_value": "Keep value",
                        "single_layer":"Single Layer"
                    },
                    "default_value": "keep_value"
                },
                "d_num_tweak_Layers":
                {
                    "label": "Number Layers",
                    "description": "Number of layers used to tweak",
                    "unit": "",
                    "type": "int",
                    "default_value": 1,
                    "minimum_value": "1",
                    "maximum_value_warning": "50",
                    "enabled": "c_behavior == 'keep_value'"
                },
                "e1_tweak_speed":
                {
                    "label": "Tweak Speed",
                    "description": "Select if total speed (print and travel) has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "e2_speed":
                {
                    "label": "Speed",
                    "description": "New total speed (print and travel)",
                    "unit": "%",
                    "type": "int",
                    "default_value": 100,
                    "minimum_value": "1",
                    "minimum_value_warning": "10",
                    "maximum_value_warning": "200",
                    "enabled": "e1_tweak_speed"
                },
                "f1_tweak_print_speed":
                {
                    "label": "Tweak Print Speed",
                    "description": "Select if print speed has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "f2_print_speed":
                {
                    "label": "Print Speed",
                    "description": "New print speed",
                    "unit": "%",
                    "type": "int",
                    "default_value": 100,
                    "minimum_value": "1",
                    "minimum_value_warning": "10",
                    "maximum_value_warning": "200",
                    "enabled": "f1_tweak_print_speed"
                },
                "g1_tweak_flowrate":
                {
                    "label": "Tweak Flow Rate",
                    "description": "Select if flow rate has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "g2_flowrate":
                {
                    "label": "Flow Rate",
                    "description": "New Flow rate",
                    "unit": "%",
                    "type": "int",
                    "default_value": 100,
                    "minimum_value": "1",
                    "minimum_value_warning": "10",
                    "maximum_value_warning": "200",
                    "enabled": "g1_tweak_flowrate"
                },
                "g3_tweak_flowrate_one":
                {
                    "label": "Tweak Flow Rate 1",
                    "description": "Select if first extruder flow rate has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "g4_flowrate_one":
                {
                    "label": "Flow Rate One",
                    "description": "New Flow rate Extruder 1",
                    "unit": "%",
                    "type": "int",
                    "default_value": 100,
                    "minimum_value": "1",
                    "minimum_value_warning": "10",
                    "maximum_value_warning": "200",
                    "enabled": "g3_tweak_flowrate_one"
                },
                "g5_tweak_flowrate_Two":
                {
                    "label": "Tweak Flow Rate 2",
                    "description": "Select if second extruder flow rate has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "g6_flowrate_two":
                {
                    "label": "Flow Rate two",
                    "description": "New Flow rate Extruder 2",
                    "unit": "%",
                    "type": "int",
                    "default_value": 100,
                    "minimum_value": "1",
                    "minimum_value_warning": "10",
                    "maximum_value_warning": "200",
                    "enabled": "g5_tweak_flowrate_two"
                },
                "h1_tweak_bed_temp":
                {
                    "label": "Tweak Bed Temp",
                    "description": "Select if Bed Temperature has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "h2_bed_temp":
                {
                    "label": "Bed Temp",
                    "description": "New Bed Temperature",
                    "unit": "C",
                    "type": "float",
                    "default_value": 60,
                    "minimum_value": "0",
                    "minimum_value_warning": "30",
                    "maximum_value_warning": "120",
                    "enabled": "h1_Tweak_bed_temp"
                },
                "i1_tweak_extruder_one":
                {
                    "label": "Tweak Extruder 1 Temp",
                    "description": "Select if First Extruder Temperature has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "i2_extruder_one":
                {
                    "label": "Extruder 1 Temp",
                    "description": "New First Extruder Temperature",
                    "unit": "C",
                    "type": "float",
                    "default_value": 190,
                    "minimum_value": "0",
                    "minimum_value_warning": "160",
                    "maximum_value_warning": "250",
                    "enabled": "i1_tweak_extruder_one"
                },
                "i3_tweak_extruder_two":
                {
                    "label": "Tweak Extruder 2 Temp",
                    "description": "Select if Second Extruder Temperature has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "i4_extruder_two":
                {
                    "label": "Extruder 2 Temp",
                    "description": "New Second Extruder Temperature",
                    "unit": "C",
                    "type": "float",
                    "default_value": 190,
                    "minimum_value": "0",
                    "minimum_value_warning": "160",
                    "maximum_value_warning": "250",
                    "enabled": "i3_tweak_extruder_two"
                },
                "j1_tweak_fan_speed":
                {
                    "label": "Tweak Fan Speed",
                    "description": "Select if Fan Speed has to be tweaked",
                    "type": "bool",
                    "default_value": false
                },
                "j2_fan_speed":
                {
                    "label": "Fan Speed",
                    "description": "New Fan Speed (0-255)",
                    "unit": "PWM",
                    "type": "int",
                    "default_value": 255,
                    "minimum_value": "0",
                    "minimum_value_warning": "15",
                    "maximum_value_warning": "255",
                    "enabled": "j1_tweak_fan_speed"
                }
            }
        }"""

    # Replace default getValue due to comment-reading feature
    def getValue(self, line, key, default = None):
        if key not in line or (";" in line and line.find(key) > line.find(";") and ";TweakAtZ" not in key and ";LAYER:" not in key):
            return default

        sub_part = line[line.find(key) + len(key):] # Allows for string lengths larger than 1
        if ";TweakAtZ" in key:
            m = re.search("^[0-4]", sub_part)
        elif ";LAYER:" in key:
            m = re.search("^[+-]?[0-9]*", sub_part)
        else:
            # The minus at the beginning allows for negative values, e.g. for delta printers
            m = re.search("^[-]?[0-9]+\.?[0-9]*", sub_part)

        if m is None:
            return default
        try:
            return float(m.group(0))
        except:
            return default

    def execute(self, data):
        # Check which tweaks should apply
        tweak_properties = {"speed": self.getSettingValueByKey("e1_tweak_speed"),
                            "flowrate": self.getSettingValueByKey("g1_tweak_flowrate"),
                            "flowrate_one": self.getSettingValueByKey("g3_tweak_flowrate_one"),
                            "flowrate_two": self.getSettingValueByKey("g5_tweak_flowrate_two"),
                            "bed_temperature": self.getSettingValueByKey("h1_tweak_bed_temp"),
                            "extruder_one": self.getSettingValueByKey("i1_tweak_extruder_one"),
                            "extruder_two": self.getSettingValueByKey("i3_tweak_extruder_two"),
                            "fan_speed": self.getSettingValueByKey("j1_tweak_fan_speed")}

        tweak_print_speed = self.getSettingValueByKey("f1_tweak_print_speed")
        tweak_gcodes = {"speed": "M220 S%f\n",
                         "flowrate": "M221 S%f\n",
                         "flowrate_one": "M221 T0 S%f\n",
                         "flowrate_two": "M221 T1 S%f\n",
                         "bed_temperature": "M140 S%f\n",
                         "extruder_one": "M104 S%f T0\n",
                         "extruder_two": "M104 S%f T1\n",
                         "fan_speed": "M106 S%d\n"}

        target_values = {"speed": self.getSettingValueByKey("e2_speed"),
                         "flowrate": self.getSettingValueByKey("g2_flowrate"),
                         "flowrate_one": self.getSettingValueByKey("g4_flowrate_one"),
                         "flowrate_two": self.getSettingValueByKey("g6_flowrate_two"),
                         "bed_temperature": self.getSettingValueByKey("h2_bed_temp"),
                         "extruder_one": self.getSettingValueByKey("i2_extruder_one"),
                         "extruder_two": self.getSettingValueByKey("i4_extruder_two"),
                         "fan_speed": self.getSettingValueByKey("j2_fan_speed")}

        # Fill dict with -1 (indicated undefined) old values
        old = {key: -1 for key, value in target_values.items()}

        tweak_layers = self.getSettingValueByKey("d_num_tweak_Layers")
        if self.getSettingValueByKey("c_behavior") == "single_layer":
            behavior = 1
        else:
            behavior = 0

        try:
            tweak_layers = max(int(tweak_layers), 1)  # For the case someone entered something as "funny" as -1
        except:
            tweak_layers = 1

        pres_ext = 0
        done_layers = 0
        z = 0
        x = None
        y = None
        layer = -100000  # layer number may be negative (raft) but never that low
        # state 0: deactivated, state 1: activated, state 2: active, but below z,
        # state 3: active and partially executed (multi layer), state 4: active and passed z
        state = 1
        # is_um2: Used for reset of values (ok for Marlin/Sprinter),
        # has to be set to 1 for UltiGCode (work-around for missing default values)
        is_um2 = False
        is_old_value_unknown = False
        num_tweaker_instances = 0

        if self.getSettingValueByKey("a_trigger") == "layer_no":
            target_layer = int(self.getSettingValueByKey("b_targetL"))
            target_height = 100000
        else:
            target_layer = -100000
            target_height = self.getSettingValueByKey("b_targetZ")
        index = 0
        for active_layer in data:
            modified_gcode = ""
            lines = active_layer.split("\n")
            for line in lines:
                if ";Generated with Cura_SteamEngine" in line:
                    num_tweaker_instances += 1
                    modified_gcode += ";TweakAtZ instances: %d\n" % num_tweaker_instances
                if not ("M84" in line or "M25" in line or ("G1" in line and tweak_print_speed and (state == 3 or state == 4)) or ";TweakAtZ instances:" in line):
                    modified_gcode += line + "\n"
                is_um2 = ("FLAVOR:UltiGCode" in line) or is_um2  # Flavor is Ulti-GCode!
                if ";TweakAtZ-state" in line:  # Checks for state change comment
                    state = self.getValue(line, ";TweakAtZ-state", state)
                if ";TweakAtZ instances:" in line:
                    try:
                        temp_num_tweaker_instances = int(line[20:])
                    except:
                        temp_num_tweaker_instances = num_tweaker_instances
                    num_tweaker_instances = temp_num_tweaker_instances
                if ";Small layer" in line:  # Checks for begin of Cool Head Lift
                    old["state"] = state
                    state = 0
                if ";LAYER:" in line:  # New layer number found
                    if state == 0:
                        state = old["state"]
                    layer = int(self.getValue(line, ";LAYER:", layer))
                    if target_layer > -100000:  # Target selected by layer number
                        if (state == 1 or target_layer == 0) and layer == target_layer:  # Determine target_height from layer no.; checks for tweak on layer 0
                            state = 2
                            target_height = z + 0.001
                if self.getValue(line, "T", None) is not None and self.getValue(line, "M", None) is None:  # Looking for single T-command
                    pres_ext = self.getValue(line, "T", pres_ext)
                if "M190" in line or "M140" in line and state < 3:  # Looking for bed temp, stops after target z is passed
                    old["bed_temperature"] = self.getValue(line, "S", old["bed_temperature"])
                if "M109" in line or "M104" in line and state < 3:  # Looking for extruder temp, stops after target z is passed
                    if self.getValue(line, "T", pres_ext) == 0:
                        old["extruder_one"] = self.getValue(line, "S", old["extruder_one"])
                    elif self.getValue(line, "T", pres_ext) == 1:
                        old["extruder_two"] = self.getValue(line, "S", old["extruder_two"])
                if "M107" in line:  # Fan is stopped; is always updated in order not to miss switch off for next object
                    old["fan_speed"] = 0
                if "M106" in line and state < 3:  # Looking for fan speed
                    old["fan_speed"] = self.getValue(line, "S", old["fan_speed"])
                if "M221" in line and state < 3:  # Looking for flow rate
                    target_extruder = self.getValue(line, "T", None)
                    if target_extruder is None:  # Check if extruder is specified
                        old["flowrate"] = self.getValue(line, "S", old["flowrate"])
                    elif target_extruder == 0:  # First extruder
                        old["flowrate_one"] = self.getValue(line, "S", old["flowrate_one"])
                    elif target_extruder == 1:  # Second extruder
                        old["flowrate_two"] = self.getValue(line, "S", old["flowrate_two"])
                if "M84" in line or "M25" in line:
                    if state > 0 and tweak_properties["speed"]:  # "finish" commands for UM Original and UM2
                        modified_gcode += "M220 S100 ; speed reset to 100% at the end of print\n"
                        modified_gcode += "M117                     \n"
                    modified_gcode += line + "\n"
                if "G1" in line or "G0" in line:
                    new_z = self.getValue(line, "Z", z)
                    x = self.getValue(line, "X", None)
                    y = self.getValue(line, "Y", None)
                    e = self.getValue(line, "E", None)
                    f = self.getValue(line, "F", None)
                    if 'G1' in line and tweak_print_speed and (state == 3 or state == 4):
                        # check for pure print movement in target range:
                        if x is not None and y is not None and f is not None and e is not None and new_z == z:
                            # TODO: fix printspeed. what should it be?
                            modified_gcode += "G1 F%d X%1.3f Y%1.3f E%1.5f\n" % (int(f / 100.0 * float(printspeed)), self.getValue(line, "X"),
                                                                          self.getValue(line, "Y"), self.getValue(line, "E"))
                        else:  # G1 command but not a print movement
                            modified_gcode += line + "\n"
                    # no tweaking on retraction hops which have no x and y coordinate:
                    if new_z != z and x is not None and y is not None:
                        z = new_z
                        if z < target_height and state == 1:
                            state = 2
                        if z >= target_height and state == 2:
                            state = 3
                            done_layers = 0
                            for key in tweak_properties:
                                if tweak_properties[key] and old[key] == -1:  # old value is not known
                                    is_old_value_unknown = True
                            if is_old_value_unknown:  # The tweaking has to happen within one layer
                                tweak_layers = 1
                                if is_um2:  # Parameters have to be stored in the printer (UltiGCode=UM2)
                                    modified_gcode += "M605 S%d;stores parameters before tweaking\n" % (num_tweaker_instances - 1)
                            if behavior == 1:  # Single layer tweak only and then reset
                                tweak_layers = 1
                            if tweak_print_speed and behavior == 0:
                                tweak_layers = done_layers + 1
                        if state == 3:
                            if tweak_layers - done_layers > 0: # Still layers to go?
                                if target_layer > -100000:
                                    modified_gcode += ";TweakAtZ V%s: executed at Layer %d\n" % (self.version, layer)
                                    modified_gcode += "M117 Printing... tw@L%4d\n" % layer
                                else:
                                    modified_gcode += ";TweakAtZ V%s: executed at %1.2f mm\n" % (self.version, z)
                                    modified_gcode += "M117 Printing... tw@%5.1f\n" % z
                                for key in tweak_properties:
                                    if tweak_properties[key]:
                                        modified_gcode += tweak_gcodes[key] % float(old[key] + (float(target_values[key]) - float(old[key])) / float(tweak_layers) * float(done_layers + 1))
                                done_layers += 1
                            else:
                                state = 4
                                if behavior == 1:  # Reset values after one layer
                                    if target_layer > -100000:
                                        modified_gcode += ";TweakAtZ V%s: reset on Layer %d\n" % (self.version, layer)
                                    else:
                                        modified_gcode += ";TweakAtZ V%s: reset at %1.2f mm\n" % (self.version, z)
                                    if is_um2 and is_old_value_unknown:  # Executes on UM2 with Ulti-GCode and machine setting
                                        modified_gcode += "M606 S%d ;recalls saved settings\n" % (num_tweaker_instances - 1)
                                    else:  # Executes on RepRap, UM2 with Ulti-GCode and Cura setting
                                        for key in tweak_properties:
                                            if tweak_properties[key]:
                                                modified_gcode += tweak_gcodes[key] % float(old[key])
                        # Re-activates the plugin if executed by pre-print G-command, resets settings:
                        if (z < target_height or layer == 0) and state >= 3:  # Resets if below tweak level or at level 0
                            state = 2
                            done_layers = 0
                            if target_layer > -100000:
                                modified_gcode += ";TweakAtZ V%s: reset below Layer %d\n" % (self.version, target_layer)
                            else:
                                modified_gcode += ";TweakAtZ V%s: reset below %1.2f mm\n" % (self.version, target_height)
                            if is_um2 and is_old_value_unknown:  # Executes on UM2 with Ulti-GCode and machine setting
                                modified_gcode += "M606 S%d;recalls saved settings\n" % (num_tweaker_instances - 1)
                            else:  # executes on RepRap, UM2 with Ulti-GCode and Cura setting
                                for key in tweak_properties:
                                    if tweak_properties[key]:
                                        modified_gcode += tweak_gcodes[key] % float(old[key])
            data[index] = modified_gcode
            index += 1
        return data

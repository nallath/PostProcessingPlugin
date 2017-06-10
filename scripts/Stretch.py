# This PostProcessingPlugin script is released under the terms of the AGPLv3 or higher.
"""
Copyright (c) 2017 Christophe Baribaud 2017
Python implementation of https://github.com/electrocbd/post_stretch
Correction of hole sizes, cylinder diameters and curves

WARNING This script has never been tested with several extruders
"""
from ..Script import Script
import numpy as np
from UM.Logger import Logger
from UM.Application import Application
import re

class GCodeStep():
    """
    Class to store the current value of each G_Code parameter
    for any G-Code step
    """
    def __init__(self, step, x, y, z, e, f, comment):
        self.step = step
        self.step_x = x
        self.step_y = y
        self.step_z = z
        self.step_e = e
        self.step_f = f
        self.comment = comment


def _getValue(line, key, default=None):
    """
    Convenience function that finds the value in a line of g-code.
    When requesting key = x from line "G1 X100" the value 100 is returned.
    It is a copy of Stript's method, so it is no DontRepeatYourself, but
    I split the class into setup part (Stretch) and execution part (Strecher)
    and only the setup part inherits from Script
    """
    if not key in line or (";" in line and line.find(key) > line.find(";")):
        return default
    sub_part = line[line.find(key) + 1:]
    number = re.search(r"^-?[0-9]+\.?[0-9]*", sub_part)
    if number is None:
        return default
    try:
        return float(number.group(0))
    except:
        return default


# Execution part of the stretch plugin
class Stretcher():
    """
    Execution part of the stretch algorithm
    """
    def __init__(self, line_width, stretch):
        self.line_width = line_width
        self.stretch = stretch
        self.output_x = 0.
        self.output_y = 0.
        self.output_z = 0.
        self.output_e = 0.
        self.output_f = 0.

    def execute(self, data):
        """
        Computes the new X and Y coordinates of all g-code steps
        """
        Logger.log("d", "Post stretch with line width=" + str(self.line_width)
                   + "mm and stretch=" + str(self.stretch)+ "mm")
        retdata = []
        layer_steps = []
        current_x = 0.
        current_y = 0.
        current_z = 0.
        current_e = 0.
        current_f = 0.
        layer_z = 0.
        for layer in data:
            lines = layer.rstrip("\n").split("\n")
            for line in lines:
                comment = ""
                if line.find(";") >= 0:
                    comment = line[line.find(";"):]
                if _getValue(line, "G") == 0:
                    current_x = _getValue(line, "X", current_x)
                    current_y = _getValue(line, "Y", current_y)
                    current_z = _getValue(line, "Z", current_z)
                    current_e = _getValue(line, "E", current_e)
                    current_f = _getValue(line, "F", current_f)
                    onestep = GCodeStep(0, current_x, current_y, current_z,
                                        current_e, current_f, comment)
                elif _getValue(line, "G") == 1:
                    current_x = _getValue(line, "X", current_x)
                    current_y = _getValue(line, "Y", current_y)
                    current_z = _getValue(line, "Z", current_z)
                    current_e = _getValue(line, "E", current_e)
                    current_f = _getValue(line, "F", current_f)
                    onestep = GCodeStep(1, current_x, current_y, current_z,
                                        current_e, current_f, comment)
                elif _getValue(line, "G") == 92:
                    current_x = _getValue(line, "X", current_x)
                    current_y = _getValue(line, "Y", current_y)
                    current_z = _getValue(line, "Z", current_z)
                    current_e = _getValue(line, "E", current_e)
                    current_f = _getValue(line, "F", current_f)
                    onestep = GCodeStep(-1, current_x, current_y, current_z,
                                        current_e, current_f, comment)
                else:
                    onestep = GCodeStep(-1, current_x, current_y, current_z,
                                        current_e, current_f, line)
                if current_z != layer_z:
                    Logger.log("d", "Layer Z " + "{:.3f}".format(layer_z)
                               + " " + str(len(layer_steps)) + " steps")
                    if len(layer_steps):
                        retdata.append(self.processLayer(layer_steps))
                    layer_steps = []
                    layer_z = current_z
                layer_steps.append(onestep)
        if len(layer_steps):
            retdata.append(self.processLayer(layer_steps))
        retdata.append(";Stretch distance " + str(self.stretch) + "\n")
        return retdata

    def processLayer(self, layer_steps):
        """
        Computes the new coordinates of g-code steps
        for one layer (all the steps at the same Z coordinate)
        """
        layergcode = ""
        self.vd1 = np.empty((0, 2)) # Start points of segments
                                    # of already deposited material for this layer
        self.vd2 = np.empty((0, 2)) # End points of segments
                                    # of already deposited material for this layer
        current_e = layer_steps[0].step_e
        orig_seq = np.empty((0, 2))
        iflush = 0
        for i, step in enumerate(layer_steps):
            if i == 0:
                current_e = step.step_e
            if current_e == step.step_e:
                # No extrusion since the previous step, so it is a travel move
                # Let process steps accumulated into orig_steps,
                # which are a sequence of continuous extrusion
                modif_seq = np.copy(orig_seq)
                if len(orig_seq) >= 2:
                    self.workOnSequence(orig_seq, modif_seq)
                layergcode = self.generate(layer_steps, iflush, i, modif_seq, layergcode)
                iflush = i
                orig_seq = np.empty((0, 2))
            if step.step == 0 or step.step == 1:
                orig_seq = np.concatenate([orig_seq, np.array([[step.step_x, step.step_y]])])
            current_e = step.step_e
        if len(orig_seq):
            modif_seq = np.copy(orig_seq)
        if len(orig_seq) >= 2:
            self.workOnSequence(orig_seq, modif_seq)
        layergcode = self.generate(layer_steps, iflush, len(layer_steps), modif_seq, layergcode)
        return layergcode

    def stepToGcode(self, onestep):
        """
        Converts a step into G-Code
        For each of the X, Y, Z, E and F parameter,
        the parameter is written only if its value changed since the
        previous g-code step.
        """
        sout = ""
        if onestep.step_f != self.output_f:
            self.output_f = onestep.step_f
            sout += " F{:.0f}".format(self.output_f).rstrip(".")
        if (onestep.step_x != self.output_x or onestep.step_y != self.output_y
                or onestep.step_z != self.output_z):
            assert onestep.step_x >= -1000 and onestep.step_x < 1000 # If this assertion fails,
                                                           # something went really wrong !
            self.output_x = onestep.step_x
            sout += " X{:.3f}".format(self.output_x).rstrip("0").rstrip(".")
            assert onestep.step_y >= -1000 and onestep.step_y < 1000 # If this assertion fails,
                                                           # something went really wrong !
            self.output_y = onestep.step_y
            sout += " Y{:.3f}".format(self.output_y).rstrip("0").rstrip(".")
        if onestep.step_z != self.output_z:
            self.output_z = onestep.step_z
            sout += " Z{:.3f}".format(self.output_z).rstrip("0").rstrip(".")
        if onestep.step_e != self.output_e:
            self.output_e = onestep.step_e
            sout += " E{:.5f}".format(self.output_e).rstrip("0").rstrip(".")
        return sout

    def generate(self, layer_steps, i, iend, orig_seq, layergcode):
        """
        Appends g-code lines to the plugin's returned string
        """
        ipos = 0
        while i < iend:
            if layer_steps[i].step == 0:
                sout = "G0" + self.stepToGcode(layer_steps[i])
                layergcode = layergcode + sout + "\n"
                ipos = ipos + 1
            elif layer_steps[i].step == 1:
                layer_steps[i].step_x = orig_seq[ipos][0]
                layer_steps[i].step_y = orig_seq[ipos][1]
                sout = "G1" + self.stepToGcode(layer_steps[i])
                layergcode = layergcode + sout + "\n"
                ipos = ipos + 1
            else:
                layergcode = layergcode + layer_steps[i].comment + "\n"
            i = i + 1
        return layergcode


    def workOnSequence(self, orig_seq, modif_seq):
        """
        Computes new coordinates for a sequence
        A sequence is a list of consecutive g-code steps
        of continuous material extrusion
        """
        if (len(orig_seq) > 2 and
                ((orig_seq[len(orig_seq) - 1] - orig_seq[0]) ** 2).sum(0) < 0.3 * 0.3):
            self.wideCircle(orig_seq, modif_seq)
        else:
            self.wideTurn(orig_seq, modif_seq)
        self.pushWall(orig_seq, modif_seq)
        if len(orig_seq):
            self.vd1 = np.concatenate([self.vd1, np.array(orig_seq[:-1])])
            self.vd2 = np.concatenate([self.vd2, np.array(orig_seq[1:])])

    def wideCircle(self, orig_seq, modif_seq):
        """
        Similar to wideTurn
        The first and last point of the sequence are the same,
        so it is possible to extend the end of the sequence
        with its beginning when seeking for triangles

        It is necessary to find the direction of the curve, knowing three points (a triangle)
        If the triangle is not wide enough, there is a huge risk of finding
        an incorrect orientation, due to insufficient accuracy.
        So, when the consecutive points are too close, the method
        use following and preceding points to form a wider triangle around
        the current point
        dmin_tri is the minimum distance between two consecutive points
        of an acceptable triangle
        """
        dmin_tri = self.line_width / 2.0
        iextra = np.floor_divide(len(orig_seq), 3) # Nb of extra points
        ibeg = 0 # Index of first point of the triangle
        i = 0 # Index of the middle point
        iend = 0 # Index of the last point
        while i < len(orig_seq):
            # pos_after is the array of positions of the original sequence
            # after the current point
            pos_after = np.resize(np.roll(orig_seq, -i-1, 0), (iextra, 2))
            good_triangle = True
            # Vector of distances between the current point and each following point
            dist_from_point = ((orig_seq[i] - pos_after) ** 2).sum(1)
            if np.amax(dist_from_point) < dmin_tri * dmin_tri:
                good_triangle = False
            else:
                iend = np.argmax(dist_from_point >= dmin_tri * dmin_tri)
            if good_triangle:
                # pos_before is the array of positions of the original sequence
                # before the current point
                pos_before = np.resize(np.roll(orig_seq, -i, 0)[::-1], (iextra, 2))
                # This time, vector of distances between the current point and each preceding point
                dist_from_point = ((orig_seq[i] - pos_before) ** 2).sum(1)
                if np.amax(dist_from_point) < dmin_tri * dmin_tri:
                    good_triangle = False
                else:
                    ibeg = np.argmax(dist_from_point >= dmin_tri * dmin_tri)
            if good_triangle:
                # See https://github.com/electrocbd/post_stretch for explanations
                # relpos is the relative position of the projection of the second point
                # of the triangle on the segment from the first to the third point
                # 0 means the position of the first point, 1 means the position of the third,
                # intermediate values are positions between
                length_base = ((pos_after[iend] - pos_before[ibeg]) ** 2).sum(0)
                relpos = ((orig_seq[i] - pos_before[ibeg])
                          * (pos_after[iend] - pos_before[ibeg])).sum(0)
                if np.fabs(relpos) < 1000.0 * np.fabs(length_base):
                    relpos /= length_base
                else:
                    relpos = 0.5 # To avoid division by zero or precision loss
                projection = (pos_before[ibeg] + relpos * (pos_after[iend] - pos_before[ibeg]))
                dist_from_proj = np.sqrt(((projection - orig_seq[i]) ** 2).sum(0))
                if dist_from_proj > 0.001: # Move central point only if points are not aligned
                    modif_seq[i] = (orig_seq[i] - (self.stretch / dist_from_proj)
                                    * (projection - orig_seq[i]))
            i = i + 1
        return

    def wideTurn(self, orig_seq, modif_seq):
        '''
        We have to select three points in order to form a triangle
        These three points should be far enough from each other to have
        a reliable estimation of the orientation of the current turn
        '''
        dmin_tri = self.line_width / 2.0
        ibeg = 0
        i = 1
        iend = 2
        while i+1 < len(orig_seq):
            good_triangle = True
            dist_from_point = ((orig_seq[i] - orig_seq[i+1:]) ** 2).sum(1)
            if np.amax(dist_from_point) < dmin_tri * dmin_tri:
                good_triangle = False
            else:
                iend = i + 1 + np.argmax(dist_from_point >= dmin_tri * dmin_tri)
            if good_triangle:
                dist_from_point = ((orig_seq[i] - orig_seq[i-1::-1]) ** 2).sum(1)
                if np.amax(dist_from_point) < dmin_tri * dmin_tri:
                    good_triangle = False
                else:
                    ibeg = i - 1 - np.argmax(dist_from_point >= dmin_tri * dmin_tri)
            if good_triangle:
                length_base = ((orig_seq[iend] - orig_seq[ibeg]) ** 2).sum(0)
                relpos = ((orig_seq[i] - orig_seq[ibeg]) * (orig_seq[iend] - orig_seq[ibeg])).sum(0)
                if np.fabs(relpos) < 1000.0 * np.fabs(length_base):
                    relpos /= length_base
                else:
                    relpos = 0.5
                projection = orig_seq[ibeg] + relpos * (orig_seq[iend] - orig_seq[ibeg])
                dist_from_proj = np.sqrt(((projection - orig_seq[i]) ** 2).sum(0))
                if dist_from_proj > 0.001:
                    modif_seq[i] = (orig_seq[i] - (self.stretch / dist_from_proj)
                                    * (projection - orig_seq[i]))
            i = i + 1
        return

    def pushWall(self, orig_seq, modif_seq):
        """
        The algorithm tests for each segment if material was
        already deposited at one or the other side of this segment.
        If material was deposited at one side but not both,
        the segment is moved into the direction of the deposited material,
        to "push the wall"

        Already deposited material is stored as segments.
        vd1 is the array of the starting points of the segments
        vd2 is the array of the ending points of the segments
        For example, segment nr 8 starts at position self.vd1[8]
        and ends at position self.vd2[8]
        """
        dist_palp = self.line_width / 2.0 # Palpation distance to seek for a wall
        mrot = np.array([[0, -1], [1, 0]]) # Rotation matrix for a quarter turn
        for i in range(len(orig_seq)):
            ibeg = i # Index of the first point of the segment
            iend = i + 1 # Index of the last point of the segment
            if iend == len(orig_seq):
                iend = i - 1
            xperp = np.dot(mrot, orig_seq[iend] - orig_seq[ibeg])
            xperp = xperp / np.sqrt((xperp ** 2).sum(-1))
            testleft = orig_seq[ibeg] + xperp * dist_palp
            materialleft = False # Is there already extruded material at the left of the segment
            testright = orig_seq[ibeg] - xperp * dist_palp
            materialright = False # Is there already extruded material at the right of the segment
            if self.vd1.shape[0]:
                relpos = np.clip(((testleft - self.vd1) * (self.vd2 - self.vd1)).sum(1)
                                 / ((self.vd2 - self.vd1) * (self.vd2 - self.vd1)).sum(1), 0., 1.)
                nearpoints = self.vd1 + relpos[:, np.newaxis] * (self.vd2 - self.vd1)
                # nearpoints is the array of the nearest points of each segment
                # from the point testleft
                dist = ((testleft - nearpoints) * (testleft - nearpoints)).sum(1)
                # dist is the array of the squares of the distances between testleft
                # and each segment
                if np.amin(dist) <= dist_palp * dist_palp:
                    materialleft = True
                # Now the same computation with the point testright at the other side of the
                # current segment
                relpos = np.clip(((testright - self.vd1) * (self.vd2 - self.vd1)).sum(1)
                                 / ((self.vd2 - self.vd1) * (self.vd2 - self.vd1)).sum(1), 0., 1.)
                nearpoints = self.vd1 + relpos[:, np.newaxis] * (self.vd2 - self.vd1)
                dist = ((testright - nearpoints) * (testright - nearpoints)).sum(1)
                if np.amin(dist) <= dist_palp * dist_palp:
                    materialright = True
            if materialleft and not materialright:
                modif_seq[ibeg] = modif_seq[ibeg] + xperp * self.stretch
            elif not materialleft and materialright:
                modif_seq[ibeg] = modif_seq[ibeg] - xperp * self.stretch
            if materialleft and materialright:
                modif_seq[ibeg] = orig_seq[ibeg] # Surrounded by walls, don't move

# Setup part of the stretch plugin
class Stretch(Script):
    """
    Setup part of the stretch algorithm
    The only parameter is the stretch distance
    """
    def __init__(self):
        super().__init__()

    def getSettingDataString(self):
        return """{
            "name":"Post stretch script",
            "key": "Stretch",
            "metadata": {},
            "version": 2,
            "settings":
            {
                "stretch":
                {
                    "label": "Stretch distance",
                    "description": "Distance by which the points are moved by the correction effect. The higher this value, the higher the effect",
                    "unit": "mm",
                    "type": "float",
                    "default_value": 0.08,
                    "minimum_value": 0,
                    "minimum_value_warning": 0,
                    "maximum_value_warning": 0.2
                }
            }
        }"""

    def execute(self, data):
        """
        Entry point of the plugin.
        data is the list of original g-code instructions,
        the returned string is the list of modified g-code instructions
        """
        stretcher = Stretcher(
            Application.getInstance().getGlobalContainerStack().getProperty("line_width", "value")
            , self.getSettingValueByKey("stretch"))
        return stretcher.execute(data)



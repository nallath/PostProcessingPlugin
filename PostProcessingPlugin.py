from PyQt5.QtCore import  QObject
from UM.Extension import Extension

class PostProcessingPlugin(QObject,  Extension):
    def __init__(self, parent = None):
        super().__init__(parent)
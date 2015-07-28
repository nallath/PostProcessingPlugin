# Copyright (c) 2015 Jaime van Kessel, Ultimaker B.V.
# The PostProcessingPlugin is released under the terms of the AGPLv3 or higher.
from PyQt5.QtCore import  QObject, QUrl, pyqtProperty, pyqtSignal, pyqtSlot
from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import QQmlComponent, QQmlContext

from UM.PluginRegistry import PluginRegistry
from UM.Application import Application
from UM.Preferences import Preferences
from UM.Extension import Extension

from pydoc import locate

import os.path
import pkgutil
import sys

from PostProcessingPlugin.scripts.Test import Test

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("PostProcessingPlugin")

class PostProcessingPlugin(QObject,  Extension):
    def __init__(self, parent = None):
        super().__init__(parent)
        self.addMenuItem(i18n_catalog.i18n("Modify G-Code"), self.showPopup)
        self._view = None
        self._loaded_scripts = {}
        
    def loadAllScripts(self, path):
        scripts = pkgutil.iter_modules(path = [path])
        for loader, script_name, ispkg in scripts: 
            if script_name not in sys.modules:
                # Import module
                loaded_script = __import__("PostProcessingPlugin.scripts."+ script_name, fromlist = [script_name])
                loaded_class = getattr(loaded_script, script_name)
                self._loaded_scripts[script_name] =  loaded_class
    
    ##  Creates the view used by show popup. The view is saved because of the fairly aggressive garbage collection.
    def _createView(self):
        ## Load all scripts in the scripts folder
        self.loadAllScripts(os.path.join(PluginRegistry.getInstance().getPluginPath("PostProcessingPlugin"), "scripts"))
        
        path = QUrl.fromLocalFile(os.path.join(PluginRegistry.getInstance().getPluginPath("PostProcessingPlugin"), "PostProcessingPlugin.qml"))
        self._component = QQmlComponent(Application.getInstance()._engine, path)

        self._context = QQmlContext(Application.getInstance()._engine.rootContext())
        self._context.setContextProperty("manager", self)
        self._view = self._component.create(self._context)
    
    ##  Show the (GUI) popup of the post processing plugin.
    def showPopup(self):
        if self._view is None:
            self._createView()
        self._view.show()
project(PostProcessingPlugin)

cmake_minimum_required(VERSION 2.8.12)

find_package(PythonInterp 3.4.0 REQUIRED)

install(FILES
    __init__.py
    PostProcessingPlugin.py
    PostProcessingPlugin.qml
    Script.py
    ScriptProfile.py
    SingleCategorySettingPanel.qml
    Tooltip.qml
    LICENSE
    README.md
    DESTINATION lib/cura/plugins/PostProcessing 
)

install(DIRECTORY scripts DESTINATION lib/cura/plugins/PostProcessingPlugin)


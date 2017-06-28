project(PostProcessingPlugin)

cmake_minimum_required(VERSION 2.8.12)

find_package(PythonInterp 3.4.0 REQUIRED)

install(FILES
    plugin.json
    __init__.py
    PostProcessingPlugin.py
    PostProcessingPlugin.qml
    postprocessing.svg
    Script.py
    LICENSE
    README.md
    DESTINATION lib/cura/plugins/PostProcessingPlugin
)

install(DIRECTORY scripts DESTINATION lib/cura/plugins/PostProcessingPlugin PATTERN "ExampleScript.py" EXCLUDE)


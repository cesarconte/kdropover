add_library(kdropover_core STATIC
    dropovercontroller.cpp
    dropovercontroller.h
)

target_include_directories(kdropover_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(kdropover_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
)

add_executable(kdropover
    main.cpp
    resources.qrc
)

target_link_libraries(kdropover PRIVATE
    kdropover_core
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    KF6::CoreAddons
    KF6::I18n
    LayerShellQt::Interface
)

install(TARGETS kdropover DESTINATION ${KDE_INSTALL_BINDIR})
install(FILES org.cesar.kdropover.desktop DESTINATION ${KDE_INSTALL_APPDIR})

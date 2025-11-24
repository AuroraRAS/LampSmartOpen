cmake_minimum_required(VERSION 3.16)

project(lampctrl LANGUAGES C)

add_executable(lampctrl main.c)

include(GNUInstallDirs)
install(TARGETS lampctrl
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

target_link_libraries(lampctrl PRIVATE opencodeV3)

add_subdirectory(opencodeV3)

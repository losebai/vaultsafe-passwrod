cmake_minimum_required(VERSION 3.14)
project(vaultsafe LANGUAGES CXX)

# Define the application target
add_executable(vaultsafe
  "my_application.cc"
  "main.cc"
)

# Apply standard settings
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions
target_compile_definitions(${BINARY_NAME} PRIVATE
  "FLUTTER_VERSION=\"${FLUTTER_VERSION}\""
  "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}"
  "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}"
  "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}"
  "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}"
)

# Disable Linux macros
target_compile_definitions(${BINARY_NAME} PRIVATE _FILE_OFFSET_BITS=64)

# Find GTK3 libraries
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

# Include directories
target_include_directories(${BINARY_NAME} PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${GTK3_INCLUDE_DIRS}
)

# Link libraries
target_link_libraries(${BINARY_NAME} PRIVATE
  flutter
  flutter_linux_app
  ${GTK3_LIBRARIES}
)

# Flutter dependencies
add_subdirectory(${FLUTTER_MANAGED_DIR})

# === Installation ===
# Install binary
install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION bin)

# Install data files
set(FLUTTER_DATA_DIR "${CMAKE_INSTALL_PREFIX}/share/vaultsafe")
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")

install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${FLUTTER_DATA_DIR}"
)

install(FILES "${FLUTTER_ICU_DATA_FILE}"
  DESTINATION "${FLUTTER_DATA_DIR}"
)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${FLUTTER_DATA_DIR}/lib"
  )
endif()

# Install desktop entry
install(FILES "vaultsafe.desktop"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications"
)

# Install icons
install(FILES "icons/vaultsafe.png"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128/apps"
)

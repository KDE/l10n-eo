project(kde-i18n-eo)

# Search KDE installation
find_package(KDE4 REQUIRED)
find_package(Msgfmt REQUIRED)
include (KDE4Defaults)
include(MacroOptionalAddSubdirectory)

macro_optional_add_subdirectory( messages )


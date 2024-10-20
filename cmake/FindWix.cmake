# Redistribution and use is allowed under the OSI-approved 3-clause BSD license.
# Copyright (c) 2018 Apriorit Inc. All rights reserved.

find_program(WIX wix REQUIRED)

function(wix_add_project _target)
    cmake_parse_arguments(WIX "ALL" "OUTPUT_NAME;ARCH" "EXTENSIONS;DEPENDS;LIBS" ${ARGN})

    if("${WIX_OUTPUT_NAME}" STREQUAL "")
        set(WIX_OUTPUT_NAME "${_target}.msi")
    endif()

    if ("${WIX_ARCH}" STREQUAL "")
        set(WIX_ARCH ${CMAKE_CXX_COMPILER_ARCHITECTURE_ID})
    endif()

    #    if(NOT IS_ABSOLUTE ${WIX_OUTPUT_NAME})
      cmake_path(ABSOLUTE_PATH WIX_OUTPUT_NAME BASE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
      #endif()

    foreach(currentFILE ${WIX_UNPARSED_ARGUMENTS})
        GET_FILENAME_COMPONENT(SOURCE_FILE_NAME ${currentFILE} NAME_WE)
        list(APPEND WIX_SOURCES_LIST ${CMAKE_CURRENT_LIST_DIR}/${currentFILE})
    endforeach()

    foreach(current_WIX_EXTENSION ${WIX_EXTENSIONS})
        list(APPEND EXTENSION_LIST "-ext")
        list(APPEND EXTENSION_LIST ${current_WIX_EXTENSION})
    endforeach()

    # Call WiX compiler
    add_custom_command(
        OUTPUT ${WIX_OUTPUT_NAME}
        COMMAND ${WIX} build --nologo -arch ${WIX_ARCH} ${WIX_FLAGS} -o "${WIX_OUTPUT_NAME}" ${WIX_SOURCES_LIST} -i "${CMAKE_CURRENT_BINARY_DIR}" -i "${CMAKE_CURRENT_BINARY_DIR}/wxi/${_target}/$<CONFIG>" ${EXTENSION_LIST}
        DEPENDS ${WIX_SOURCES_LIST} ${WIX_DEPENDS}
        )

    if(${WIX_ALL})
        add_custom_target(${_target} ALL
            DEPENDS ${WIX_OUTPUT_NAME}
            SOURCES ${WIX_UNPARSED_ARGUMENTS}
            )
    else()
        add_custom_target(${_target}
            DEPENDS ${WIX_OUTPUT_NAME}
            SOURCES ${WIX_UNPARSED_ARGUMENTS}
            )
    endif()

    get_cmake_property(WIX_variableNames VARIABLES)
    list(REMOVE_DUPLICATES WIX_variableNames)
    list(REMOVE_ITEM WIX_variableNames "CMAKE_BUILD_TYPE")
    string(CONCAT VARS_FILE "<Include>\n")
    # handle CMAKE_BUILD_TYPE in a special way to support multiconfiguration generators
    string(CONCAT VARS_FILE ${VARS_FILE} "\t<?define CMAKE_BUILD_TYPE='$<CONFIG>' ?>\n")
    foreach(WIX_variableName ${WIX_variableNames})
        string(REPLACE "'" "&quot;" WIX_variableValue "${${WIX_variableName}}")
        string(CONCAT VARS_FILE ${VARS_FILE} "\t<?define ${WIX_variableName}='${WIX_variableValue}' ?>\n")
    endforeach()
    string(CONCAT VARS_FILE ${VARS_FILE} "</Include>")
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/wxi/${_target}/$<CONFIG>/vars.wxi" CONTENT "${VARS_FILE}")

    string(CONCAT DEPENDS_FILE "<Include>\n")
    foreach(current_depends ${WIX_DEPENDS})
        if (TARGET ${current_depends})
          string(CONCAT DEPENDS_FILE ${DEPENDS_FILE} "\t<?define TARGET_FILE:${current_depends}='$<TARGET_FILE:${current_depends}>' ?>\n")
        else()
          string(REPLACE "." "_" depends_var_name "$<PATH:GET_FILENAME,${current_depends}>")
          string(CONCAT DEPENDS_FILE ${DEPENDS_FILE} "\t<?define FILE:${depends_var_name}='${current_depends}' ?>\n")
        endif()
    endforeach()
    string(CONCAT DEPENDS_FILE ${DEPENDS_FILE} "</Include>")
    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/wxi/${_target}/$<CONFIG>/depends.wxi" CONTENT "${DEPENDS_FILE}")
endfunction()

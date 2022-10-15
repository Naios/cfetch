# CFetch

A simple CMake script for automatic and cached dependency downloads and setup that gives maximum control over the dependencies: pull whichever revision you like and patch it with custom code, that's no problem for CFetch. CFetch is meant for cutting-edge development where you do not rely on outdated revisions provided by your package manager (e.g. system package manager or vcpkg).

CFetch's main goal is to provide a non-intrusive lightweight alternative for dependency management, by polyfilling standard `Find<Dependency>.cmake` files. Those files are then picked up by any arbitrary CMake `find_package` call. Therefore it is possible to mix and match arbitrary projects while providing streamlined dependency versions.

Originally CFetch was developed for [idle](https://github.com/Naios/idle), to provide a lightweight and blazingly fast alternative for dependency management in a hot-reloadable environment. Back at the time of development CMake's `FetchContent` was not as powerful as today.

CFetch is now re-released under a much more permissive license than in its original project.

---

CFetch supports the following build models:

- **Header-Only** Libraries: Header-only libraries can be made available in one line.
- **In-Tree** Source Builds: In-Tree source builds make it trivial to add end-to-end code instrumentation like sanitizers to your whole code base by building external dependencies inside your current project directly. (Equivalent to multiple nested CMake `project` calls).
- **Out-Of-Tree** Source Builds: Build a CMake project externally and make it available in your current project (by an automated `find_package` call).

---

CFetch is comparable to CMake's [`FetchContent`](https://cmake.org/cmake/help/latest/module/FetchContent.html), however it provides some various improvements:

- **Cross-Project Caching** (downloads, archive extraction, and build directories are fully cached)
- **Patching** allows the modification of a code base through multiple patches (cached).
- **Package Sources** are github (by default) or URLs to archives.
  The script downloads based on tags or commit hashes.
- **Renaming** allows to rename headers or to moving files in an external repository. Usually used to move top-level include files into an `include` directory to prevent namespace pollution for projects not following this convention anyway.
- **Re-Exporting** makes it possible to automatically re-export dependencies in the final installed project. Can be used to include and provides public dependencies from a distributed library easily.
- **Verification** is supported by SHA512 checksums out of the box.
- **License Files** from dependencies are specified on-demand and are automatically re-installed as part of the project installation. This makes sure that the licenses of all dependencies are distributed in the packaged installation.

### Installation

CFetch is self-contained and is located at `cmake/CFetch.cmake`.

1. Download `cmake/CFetch.cmake` and place it in your project's directory,
   or in any other subdirectory of your choice.
2. Add `list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")`,
   modify the directory to point to the directory of `CFetch.cmake` if required.

#### Provide dependencies lazily through `find_package` (recommended)

1. Add a directory called `modules` to your project directory.

2. Add `list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/modules")` somewhere in your `CMakeLists.txt` pointing to your `modules` directory.

3. Create a file `Find<Name of Dependency>.cmake` in your `modules` directory, for instance, `Findfmt.cmake` to make it possible to find the [fmtlib](https://github.com/fmtlib/fmt) through `find_package(fmt REQUIRED)`.

4. Add the following content to `Findfmt.cmake`:

   ```cmake
   include(CFetch)
   
   cfetch_header_dependency(
     "fmtlib/fmt@51d3685efe0eb8a44656f9fd5dac6a04f4e58259"
     DEFINITIONS FMT_HEADER_ONLY
     LICENSE_FILE "LICENSE.rst")
   ```
   
5.  [fmtlib](https://github.com/fmtlib/fmt) can now be included in your application:

   ```cmake
   find_package(fmt REQUIRED)
   
   add_executable(main "${CMAKE_CURRENT_LIST_DIR}/main.cpp")
   
   target_link_libraries(main PUBLIC fmt::fmt)
   ```

*For a few examples take a look at the **modules** directory.*

#### Provide dependencies directly (not recommended)

As an alternative to using a file that can be found by `find_package`, it is also possible to make a dependency available immediately by using `cfetch_header_dependency` or `cfetch_dependency` directly in your `CMakeLists.txt` file.

#### Providing dependencies for external Projects

it is also possible to let CFetch provide dependencies for projects where you do not control the build process directly. This can be accomplished by invoking CMake with `cmake -DCMAKE_MODULE_PATH="<Path to the directory of CFetch.cmake>"`. Additionally you want to add the path of the directory that contains the polyfills for the `Find<Dependency>.cmake` files to `CMAKE_MODULE_PATH` as well.

For instance, take a look at the following directory structure:

```
*- Project
*- CFetchDir
   *- CFetch.cmake
*- MyModules
   *- FindDependency1.cmake
   *- FindDependency1.cmake
```

You would call: `cmake -S Project -B Project/build -DCMAKE_MODULE_PATH="CFetchDir;MyModules"`.

### Reference

#### cfetch_header_dependency

Provides header-only dependencies without any compilation involved:

**cfetch_header_dependency**(
     "**author/projectname@revision_or_hash**"
​    [**INSTALL**] # Re-Install the dependency as part of the project's install
​    [**EXPORT**] # Provide an importable target in the project's install.
​    [**NO_LICENSE_FILE**] # The project does not provide a license file
​    [**PIN_VERSION**] # 
​    [**AS** *target_name*]
​    [**SHA512** *checksum*] 
​    [**LICENSE_FILE** *path*] # Specify the license file provided by the dependency
​    [**URL** *url*]
​    [**BASE_DIR** *directory*]
​    [**INCLUDE_DIRECTORIES** *additional_include_directories...*]
​    [**DEFINITIONS** *additional_compile_definitions...*]
​    [**FEATURES** *additional_target_features...*]
​    [**LINK_LIBRARIES** *additional_link_libraries...*]
​    [**FILTER** *archive_extraction_file_filter...*]
​    [**RENAME** *rename_file_assignments...*]
​    [**PATCH** *patch_files_to_apply...*]
)

#### cfetch_dependency

Provides dependencies that are built in-tree or out-of-tree:

**cfetch_dependency**(
     "**author/projectname@revision_or_hash**"
    [**NO_LICENSE_FILE**] # The project does not provide a license file
    [**EXTERNAL**] # Build the dependency out-of-tree (is built in-tree otherwise).
    [**NO_FIND_PACKAGE**]
    [**DRY_RUN**] # Test this command without and modifications on the filesystem
    [**PIN_VERSION**]
    [**CD** *arg*]
    [**AS** *arg*]
    [**LICENSE_FILE** *path*] # Specify the license file provided by the dependency
    [**SUBDIRECTORY** *arg*]
    [**URL** *arg*]
    [**SHA512** *arg*]
    [**BASE_DIR** *arg*]
    [**OPTIONS** *args...*]
    [**FILTER** *args...*]
    [**PATCH** *args...*]
    [**RENAME** *args...*]
    [**INSTALL_RUNTIME** *args...*]
    [**CONFIGURATIONS** *args...*]
    [**TARGETS** *args...*]
    [**HINTS** *args...*]
)


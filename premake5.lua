workspace "Black-Tek-Server"
   configurations { "Debug", "Release"}
   platforms { "64", "ARM64", "ARM" }
   location ""
   editorintegration "On"

   newoption {
      trigger     = "use-system-libs",
      description = "Use system libraries instead of vcpkg",
      category    = "BlackTek Options" -- Separate options from premake options
   }

   newoption {
      trigger     = "use-lua",
      description = "Specific Lua library to use. For example lua5.4. This is most useful if the packaged lua implementation does not provide a symbolic liblua.so",
      value       = "libname",
      category    = "BlackTek Options", -- Separate options from premake options
      default     = "lua",
      --[[allowed     = {
         {"lua", "Default"},
         {"lua5.4", "Use specifically Lua 5.4"},
         {"luajit", "Use LuaJIT"},
      }]]
   }

   project        "Black-Tek-Server"
      kind        "ConsoleApp"
      language    "C++"
      cppdialect  "C++20"
      targetdir   "%{wks.location}"
      objdir      "build/%{cfg.buildcfg}/obj"
      location    ""
      files { "src/**.cpp", "src/**.h" }
      flags {"LinkTimeOptimization", "MultiProcessorCompile"}
      enableunitybuild "On"
      intrinsics   "On"

      -- Functions execute inside filters, so we need to check the host os
      --local git_cmd = os.host() == "windows" and "shell git" or "git" -- No idea if this would work
      if os.host() == "linux" then
         -- Check for git and grab the short commit hash
         local short_hash, exit_code = os.outputof("git rev-parse --short HEAD")
         if exit_code == 0 then
            local commit_msg = os.outputof("git log -1 --pretty=%B")
            defines {
               "GIT_RETRIEVED_STATE=true",
               string.format("GIT_SHORT_SHA1=%q", os.outputof("git rev-parse --short HEAD")),
               string.format("GIT_DESCRIBE=%q", os.outputof("git describe --tags --dirty") or git[1]), -- git describe --tags --match=v* HEAD
               string.format("GIT_HEAD_SHA1=%q", os.outputof("git rev-parse HEAD")),
               string.format("GIT_IS_DIRTY=%s", os.outputof("git status --porcelain --untracked-files=no") == "" and "false" or "true"),
               string.format("GIT_COMMIT_DATE_ISO8601=%q", os.outputof("git show -s --format=%cI HEAD")),
               string.format("GIT_COMMIT_MESSAGE=%q", commit_msg:explode("\n")[1]) -- Get the first line (title)
            }
         end
      end

      filter "configurations:Debug"
         defines { "DEBUG" }
         symbols "On"
         optimize "Debug"
      filter {}

      filter "configurations:Release"
         defines { "NDEBUG" }
         symbols "On"
         optimize "Speed"
      filter {}

      filter "platforms:64"
         architecture "x86_64"

      filter "platforms:ARM64"
         architecture "ARM64"

      filter "platforms:ARM"
         architecture "ARM"

      filter { "system:linux", "options:use-system-libs", "platforms:ARM"}
         libdirs { "/usr/lib", "/usr/lib/arm*" }
         includedirs { "/usr/include", "/usr/include/arm*", "/usr/include/lua*" }

      filter { "system:linux", "options:use-system-libs", "platforms:ARM64"}
         libdirs { "/usr/lib", "/usr/lib/arm*" }
         includedirs { "/usr/include", "/usr/include/arm*", "/usr/include/lua*" }

      filter { "system:linux", "options:use-system-libs", "platforms:64"}
         libdirs { "/usr/lib" }
         includedirs { "/usr/include", "/usr/include/lua*" }

      filter "system:not windows"
         buildoptions { "-Wall", "-Wextra", "-pedantic", "-pipe", "-fvisibility=hidden", "-Wno-unused-local-typedefs" }
         linkoptions{"-flto=auto"}
      filter {}

      filter "system:windows"
         openmp "On"
         characterset "MBCS"
         debugformat "c7"
         linkoptions {"/IGNORE:4099"}
         vsprops { VcpkgEnableManifest = "true" }
      filter {}

      filter "architecture:amd64"
	     vectorextensions "AVX"
      filter{}

      filter { "system:linux", "architecture:ARM64" }
         -- Paths to vcpkg installed dependencies
         libdirs { "vcpkg_installed/arm64-linux/lib" }
         includedirs { "vcpkg_installed/arm64-linux/include" }
         links { "pugixml", _OPTIONS["use-lua"], "fmt", "ssl", "mariadb", "cryptopp", "crypto", "boost_iostreams", "zstd", "z", "curl" }
      filter{}

      filter { "system:linux", "architecture:amd64" }
         -- Paths to vcpkg installed dependencies
         libdirs { "vcpkg_installed/x64-linux/lib" }
         includedirs { "vcpkg_installed/x64-linux/include" }
         links { "pugixml", _OPTIONS["use-lua"], "fmt", "ssl", "mariadb", "cryptopp", "crypto", "boost_iostreams", "zstd", "z", "curl" }
      filter{}

      filter { "system:linux", "architecture:ARM" }
         -- Paths to vcpkg installed dependencies
         libdirs { "vcpkg_installed/arm-linux/lib" }
         includedirs { "vcpkg_installed/arm-linux/include" }
         links { "pugixml", _OPTIONS["use-lua"], "fmt", "ssl", "mariadb", "cryptopp", "crypto", "boost_iostreams", "zstd", "z", "curl" }
      filter{}

      filter "toolset:gcc"
         buildoptions { "-fno-strict-aliasing" }
         buildoptions {"-std=c++20"}
      filter {}

      filter "toolset:clang"
         buildoptions { "-Wimplicit-fallthrough", "-Wmove" }
      filter {}

      filter { "system:macosx", "action:gmake" }
         buildoptions { "-fvisibility=hidden" }
      filter {}

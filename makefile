MAKEFLAGS += --no-print-directory

CC	!= which clang-devel || which clang
CXX	!= which clang++-devel || which clang++
FORMAT	!= which clang-format-devel || which clang-format
SYSDBG	!= which lldb-devel || which lldb || which gdb

CONFIG	:= -DCMAKE_TOOLCHAIN_FILE=${VCPKG}/scripts/buildsystems/vcpkg.cmake
CONFIG	+= -DVCPKG_TARGET_TRIPLET=${VCPKG_DEFAULT_TRIPLET}
CONFIG	+= -DCMAKE_INSTALL_PREFIX=$(PWD)
CONFIG	+= -DEXTRA_WARNINGS=ON
CONFIG	+= -DBUILD_TESTS=ON

PROJECT	!= grep "^project" src/CMakeLists.txt | cut -c9- | cut -d " " -f1 | tr "[:upper:]" "[:lower:]"
SOURCES	!= find src/include src/lib src/test -type f -name '*.hpp' -or -name '*.cpp'

all: debug

run: build/llvm/debug/CMakeCache.txt
	@cd build/llvm/debug && cmake --build . && ./tests

dbg: build/llvm/debug/CMakeCache.txt
	@cd build/llvm/debug && cmake --build . && $(SYSDBG) ./tests

test: build/llvm/debug/CMakeCache.txt
	@cd build/llvm/debug && cmake --build . --target tests && ctest

install: release
	@cmake --build build/llvm/release --target install

debug: build/llvm/debug/CMakeCache.txt $(SOURCES)
	@cmake --build build/llvm/debug

release: build/llvm/release/CMakeCache.txt $(SOURCES)
	@cmake --build build/llvm/release

build/llvm/debug/CMakeCache.txt: src/CMakeLists.txt build/llvm/debug
	@cd build/llvm/debug && CC=$(CC) CXX=$(CXX) cmake -GNinja -DCMAKE_BUILD_TYPE=Debug $(CONFIG) $(PWD)/src

build/llvm/release/CMakeCache.txt: src/CMakeLists.txt build/llvm/release
	@cd build/llvm/release && CC=$(CC) CXX=$(CXX) cmake -GNinja -DCMAKE_BUILD_TYPE=Release $(CONFIG) $(PWD)/src

build/llvm/debug:
	@mkdir -p build/llvm/debug

build/llvm/release:
	@mkdir -p build/llvm/release

format:
	@$(FORMAT) -i $(SOURCES)

clean:
	@rm -rf build/llvm bin lib

.PHONY: all run dbg test install debug release format clean

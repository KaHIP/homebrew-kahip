class Heicut < Formula
  desc "Exact minimum cuts in hypergraphs at scale using FPT kernelization"
  homepage "https://github.com/KaHIP/HeiCut"
  url "https://github.com/KaHIP/HeiCut.git", tag: "v1.1"
  license "MIT"
  head "https://github.com/KaHIP/HeiCut.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "boost"
  depends_on "hwloc"
  depends_on "tbb"
  depends_on "google-sparsehash"

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major
    cc = "#{gcc.opt_bin}/gcc-#{gcc_version}"
    cxx = "#{gcc.opt_bin}/g++-#{gcc_version}"

    # Build Mt-KaHyPar dependency from source at pinned commit
    mtkahypar_src = buildpath/"_mtkahypar_src"
    mtkahypar_bld = buildpath/"_mtkahypar_bld"
    system "git", "clone", "https://github.com/kahypar/mt-kahypar.git", mtkahypar_src
    cd mtkahypar_src do
      system "git", "checkout", "0ef674a"
      system "git", "submodule", "update", "--init", "--recursive"
    end

    # Fix growt compilation error with GCC 15 (-Wtemplate-body)
    growt_file = mtkahypar_src/"external_tools/growt/data-structures/migration_table_iterator.hpp"
    inreplace growt_file, "sref.ref.refresh()", "sref._mref.refresh()"
    inreplace growt_file, "sref.ref.update(", "sref._mref.update("

    # Strip -march flags that GCC doesn't understand on macOS (e.g. apple-m3)
    ENV.remove "HOMEBREW_OPTFLAGS", /-march=\S*/
    ENV["CFLAGS"] = ENV.fetch("CFLAGS", "").gsub(/-march=\S*/, "").strip
    ENV["CXXFLAGS"] = ENV.fetch("CXXFLAGS", "").gsub(/-march=\S*/, "").strip

    # On macOS with GCC, use a portable -march instead of -march=native (which resolves to apple-m3)
    extra_cxx = "-w -include cstdint -Wno-template-body"
    extra_cxx += " -march=armv8-a" if OS.mac?

    mkdir mtkahypar_bld do
      system "cmake", mtkahypar_src,
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
             "-DCMAKE_CXX_FLAGS=#{extra_cxx}",
             "-DCMAKE_C_FLAGS=#{OS.mac? ? "-w -march=armv8-a" : "-w"}",
             "-DKAHYPAR_DOWNLOAD_TBB=OFF",
             "-DKAHYPAR_DOWNLOAD_BOOST=OFF",
             "-DKAHYPAR_ENFORCE_MINIMUM_TBB_VERSION=OFF",
             "-DKAHYPAR_PYTHON=OFF",
             "-DMT_KAHYPAR_DISABLE_BOOST=OFF",
             "-DKAHYPAR_ENABLE_ARCH_COMPILE_OPTIMIZATIONS=OFF"
      system "make", "mtkahypar", "-j#{ENV.make_jobs}"
    end

    # Find the built Mt-KaHyPar shared library
    mtkahypar_lib = Dir["#{mtkahypar_bld}/**/libmtkahypar.{so,dylib}"].first
    odie "libmtkahypar not found after build" unless mtkahypar_lib

    # Install the library into a private subdirectory to avoid conflicts with other formulas
    ext = File.extname(mtkahypar_lib)
    private_lib = lib/"heicut"
    private_lib.mkpath
    cp mtkahypar_lib, private_lib/"libmtkahypar#{ext}"

    # Update CMakeLists.txt to link against the installed library
    inreplace "CMakeLists.txt",
      "${CMAKE_CURRENT_SOURCE_DIR}/extern/mt-kahypar-library/libmtkahypar.so",
      "#{private_lib}/libmtkahypar#{ext}"

    # Build HeiCut without Gurobi, with RPATH pointing to private lib directory
    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=#{cc}",
                    "-DCMAKE_CXX_COMPILER=#{cxx}",
                    "-DCMAKE_CXX_FLAGS=#{extra_cxx}",
                    "-DUSE_GUROBI=OFF",
                    "-DCMAKE_INSTALL_RPATH=#{private_lib}",
                    "-DCMAKE_BUILD_RPATH=#{private_lib}",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    # Install all binaries (ILP binaries are not built without Gurobi)
    %w[heicut_kernelizer heicut_kernelizer_parallel heicut_trimmer
       heicut_submodular heicut_submodular_parallel
       heicut_dumbbell_generator heicut_kcore_generator].each do |binary|
      bin.install "build/#{binary}" if File.exist?("build/#{binary}")
    end
  end

  test do
    (testpath/"test.hgr").write <<~EOS
      4 6
      1 2
      3 4
      1 3 5
      2 4 6
    EOS
    output = shell_output("#{bin}/heicut_kernelizer #{testpath}/test.hgr --ordering_type=tight 2>&1")
    assert_match(/final_mincut_value/, output)
  end
end

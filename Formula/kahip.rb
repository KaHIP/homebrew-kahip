class Kahip < Formula
  desc "Karlsruhe High Quality Partitioning - graph partitioning framework"
  homepage "https://github.com/KaHIP/KaHIP"
  url "https://github.com/KaHIP/KaHIP.git",
      tag:      "v3.22",
      revision: "16591ec0f74302f47db6adccc202bf70444c393c"
  license "MIT"
  head "https://github.com/KaHIP/KaHIP.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "open-mpi"

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    # Filter out Homebrew's FetchContent trap.
    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    # Install binaries from deploy/
    bin.install Dir["deploy/*"].select { |f| File.executable?(f) && !File.directory?(f) }

    # Install libraries
    lib.install Dir["deploy/lib*"]

    # Install headers
    (include/"kahip").install "interface/kaHIP_interface.h"
    (include/"kahip").install "parallel/parallel_src/interface/parhip_interface.h"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    system bin/"graphchecker", testpath/"test.graph"
    output = shell_output("#{bin}/kaffpa #{testpath}/test.graph --k 2 --preconfiguration=fast 2>&1")
    assert_match "cut", output
  end
end

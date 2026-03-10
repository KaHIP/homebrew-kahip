class FptMaxCut < Formula
  desc "FPT-based data reduction and kernelization for the maximum cut problem"
  homepage "https://github.com/KaHIP/fpt-max-cut"
  url "https://github.com/KaHIP/fpt-max-cut.git", tag: "v1.0"
  license "MIT"
  head "https://github.com/KaHIP/fpt-max-cut.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "open-mpi"

  def install
    system "git", "submodule", "update", "--init", "solvers/MQLib"

    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    # Build MQLib first
    system "make", "-C", "solvers/MQLib",
                   "CFLAGS=-Iinclude -std=c++0x -O2 -w -include cstdint -include limits",
                   "-j#{ENV.make_jobs}"

    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DCMAKE_CXX_FLAGS=-w -include cstdint -Wno-template-body",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    "-DUSE_KAGEN=OFF",
                    *cmake_args
    system "cmake", "--build", "build", "--target", "benchmark", "-j#{ENV.make_jobs}"

    bin.install "build/benchmark" => "fpt_max_cut"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      6 10
      1 2
      2 3
      3 4
      4 1
      1 3
      2 5
      3 5
      4 5
      2 6
      3 6
    EOS
    output = shell_output("#{bin}/fpt_max_cut -action kernelization -f #{testpath}/test.graph -iterations 1 -total-allowed-solver-time 5 2>&1")
    assert_match(/RUNNING BENCHMARK/, output)
  end
end

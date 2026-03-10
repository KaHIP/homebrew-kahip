class Viecut < Formula
  desc "VieCut - Shared-Memory Parallel Minimum Cut Algorithms"
  homepage "https://github.com/KaHIP/VieCut"
  url "https://github.com/KaHIP/VieCut/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "72d5a2e7ee3b12859365d515545775bd59b2d8b13b1ff25d456f4bd41402479c"
  license "MIT"
  head "https://github.com/KaHIP/VieCut.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "open-mpi"

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DCMAKE_C_FLAGS=-w",
                    "-DCMAKE_CXX_FLAGS=-w",
                    "-DUSE_TCMALLOC=OFF",
                    "-DRUN_TESTS=OFF",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/mincut" => "viecut_mincut"
    bin.install "build/mincut_parallel" => "viecut_mincut_parallel"
    bin.install "build/multiterminal_cut" => "viecut_multiterminal_cut"
    bin.install "build/kcore" => "viecut_kcore"
    bin.install "build/kcore_parallel" => "viecut_kcore_parallel"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 4
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/viecut_mincut #{testpath}/test.graph vc 2>&1")
    assert_match(/minimum cut/, output.downcase)
  end
end

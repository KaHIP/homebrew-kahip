class Viecut < Formula
  desc "VieCut - Shared-Memory Parallel Minimum Cut Algorithms"
  homepage "https://github.com/KaHIP/VieCut"
  url "https://github.com/KaHIP/VieCut/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2d853894bdf48f8f662a931b7fa7645d7aeecbe4692b81c01c14df79355f05b5"
  license "MIT"
  head "https://github.com/KaHIP/VieCut.git", branch: "master"

  resource "tlx" do
    url "https://github.com/tlx/tlx/archive/refs/tags/v0.6.1.tar.gz"
    sha256 "24dd1acf36dd43b8e0414420e3f9adc2e6bb0e75047e872a06167961aedad769"
  end

  resource "growt" do
    url "https://github.com/TooBiased/growt/archive/5c65f3e2ce7dd8eebe5943be2cd8f55608fb5f4a.tar.gz"
    sha256 "ecf66b7c9c6c731f5b3338efd394fbeebad5357377c9466df05d682de09bbdc8"
  end

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "open-mpi"

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    resource("tlx").stage do
      (buildpath/"extlib/tlx").mkpath
      cp_r Dir["./*"], buildpath/"extlib/tlx"
    end
    resource("growt").stage do
      (buildpath/"extlib/growt").mkpath
      cp_r Dir["./*"], buildpath/"extlib/growt"
    end

    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DCMAKE_C_FLAGS=-w",
                    "-DCMAKE_CXX_FLAGS=-w",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
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

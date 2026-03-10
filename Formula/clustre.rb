class Clustre < Formula
  desc "CluStRE - Streaming Graph Clustering with Multi-Stage Refinement"
  homepage "https://github.com/KaHIP/CluStRE"
  url "https://github.com/KaHIP/CluStRE/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "9f6fa8d6a72d34540dbe68730a2e270e545eaf15c2cc7388400f1f9f2f648209"
  license "MIT"
  head "https://github.com/KaHIP/CluStRE.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "open-mpi"

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DCMAKE_CXX_FLAGS=-w -D_GLIBCXX_HAVE_QUICK_EXIT=0 -D_GLIBCXX_HAVE_AT_QUICK_EXIT=0",
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/clustre"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/clustre #{testpath}/test.graph --one_pass_algorithm=modularity --mode=light 2>&1")
    assert_match(/modularity|cluster/i, output)
  end
end

class Scc < Formula
  desc "SCC - Scalable Correlation Clustering for Signed Graphs"
  homepage "https://github.com/KaHIP/ScalableCorrelationClustering"
  url "https://github.com/KaHIP/ScalableCorrelationClustering/archive/refs/tags/v1.1.tar.gz"
  sha256 "25f1a7afaf16a457b84854ab1a0347d366a1d8699e772623c2f0ac25002f2794"
  license "MIT"
  head "https://github.com/KaHIP/ScalableCorrelationClustering.git", branch: "main"

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
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/scc"
    bin.install "build/scc_evolutionary"
    bin.install "build/scc_evaluator"
    bin.install "build/scc_graphchecker"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5 1
      2 1 3 1
      1 1 3 -1 4 1
      1 1 2 -1 4 -1
      2 1 3 -1
    EOS
    output = shell_output("#{bin}/scc #{testpath}/test.graph --seed=0 2>&1")
    assert_match(/cut/, output)
  end
end

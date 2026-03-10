class Vieclus < Formula
  desc "Vienna Graph Clustering - memetic algorithm for high-quality graph clustering"
  homepage "https://github.com/KaHIP/VieClus"
  url "https://github.com/KaHIP/VieClus/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "312d0fb0353022cfb97cdcd5ead04adc1514bb07430f848299c95554f9cee5cd"
  license "MIT"
  head "https://github.com/KaHIP/VieClus.git", branch: "master"

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
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/evolutionary_clustering" => "vieclus"
    bin.install "build/graphchecker" => "vieclus_graphchecker" if File.exist?("build/graphchecker")
    bin.install "build/evaluator" => "vieclus_evaluator" if File.exist?("build/evaluator")
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    system bin/"vieclus_graphchecker", testpath/"test.graph"
    output = shell_output("#{bin}/vieclus #{testpath}/test.graph --time_limit=1 2>&1")
    assert_match "modularity", output.downcase
  end
end

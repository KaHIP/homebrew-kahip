class Streamcpi < Formula
  desc "StreamCPI - Memory-Efficient Streaming Graph Partitioning via Compression"
  homepage "https://github.com/KaHIP/CompressedStreamingGraphPartitioning"
  url "https://github.com/KaHIP/CompressedStreamingGraphPartitioning/releases/download/v1.0/streamcpi-v1.0-full.tar.gz"
  sha256 "ca1ee89202e7d07377ba58f3b86efc6b94824e9c9b0d3934b5d6d469f45ccae3"
  license "MIT"
  head "https://github.com/KaHIP/CompressedStreamingGraphPartitioning.git", branch: "main"

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
                    "-DCMAKE_C_FLAGS=-w",
                    "-DCMAKE_CXX_FLAGS=-w",
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "--target", "stream_cpi", "-j#{ENV.make_jobs}"

    bin.install "build/stream_cpi"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/stream_cpi #{testpath}/test.graph --k=2 2>&1")
    assert_match(/cut|partition|block/, output)
  end
end

class Heistream < Formula
  desc "HeiStream - Buffered Streaming Graph Partitioning"
  homepage "https://github.com/KaHIP/HeiStream"
  url "https://github.com/KaHIP/HeiStream/releases/download/v1.0/heistream-v1.0-full.tar.gz"
  sha256 "30ecc14e152ed353fcf8a2375bf2a3496d49e21ab56c19bd1125827639561301"
  license "MIT"
  head "https://github.com/KaHIP/HeiStream.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gcc" => :build

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
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/heistream"
    bin.install "build/heistream_edge"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/heistream #{testpath}/test.graph --k=2 2>&1")
    assert_match(/cut|partition|block/, output)
  end
end

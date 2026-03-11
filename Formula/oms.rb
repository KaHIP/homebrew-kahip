class Oms < Formula
  desc "OMS - Streaming Process Mapping and Hierarchical Graph Partitioning"
  homepage "https://github.com/KaHIP/OnlineMultiSection"
  url "https://github.com/KaHIP/OnlineMultiSection/archive/refs/tags/v1.0.tar.gz"
  sha256 "c251b9eb1b21a0ad30ea03c1c54b3c41dc91ba361f8bf5e3d80658ae31497dcd"
  license "MIT"
  head "https://github.com/KaHIP/OnlineMultiSection.git", branch: "master"

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

    bin.install "build/streammultisection"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/streammultisection #{testpath}/test.graph --k=2 2>&1")
    assert_match(/cut|partition|block/, output)
  end
end

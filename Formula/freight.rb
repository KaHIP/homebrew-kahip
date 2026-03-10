class Freight < Formula
  desc "FREIGHT - Fast Streaming Hypergraph Partitioning"
  homepage "https://github.com/KaHIP/FREIGHT"
  url "https://github.com/KaHIP/FREIGHT/archive/refs/tags/v1.0.tar.gz"
  sha256 "a6b458a68c2ac5adc4b378504ce5ab922eefa9d419f6d71183f3a8382fdd8b9f"
  license "MIT"
  head "https://github.com/KaHIP/FREIGHT.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gcc" => :build

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    if OS.mac?
      (buildpath/"gcc_macos_compat.h").write <<~HEADER
        #ifndef GCC_MACOS_COMPAT_H
        #define GCC_MACOS_COMPAT_H
        #if defined(__APPLE__) && defined(__cplusplus)
        extern "C" {
        extern void quick_exit(int) __attribute__((__noreturn__));
        extern int at_quick_exit(void (*)(void)) __attribute__((__nonnull__(1)));
        }
        #endif
        #endif
      HEADER
      cxx_flags = "-w -include #{buildpath}/gcc_macos_compat.h"
    else
      cxx_flags = "-w"
    end

    cmake_args = std_cmake_args.reject { |a| a.start_with?("-DCMAKE_PROJECT_TOP_LEVEL_INCLUDES=") }

    system "cmake", "-B", "build",
                    "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=#{gcc.opt_bin}/gcc-#{gcc_version}",
                    "-DCMAKE_CXX_COMPILER=#{gcc.opt_bin}/g++-#{gcc_version}",
                    "-DCMAKE_C_FLAGS=-w",
                    "-DCMAKE_CXX_FLAGS=#{cxx_flags}",
                    "-DNONATIVEOPTIMIZATIONS=ON",
                    *cmake_args
    system "cmake", "--build", "build", "-j#{ENV.make_jobs}"

    bin.install "build/freight_cut"
    bin.install "build/freight_con"
    bin.install "build/freight_graphs"
    bin.install "build/hmetis_to_freight"
    bin.install "build/hmetis_to_freight_stream"
  end

  test do
    # Test graph partitioning
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/freight_graphs #{testpath}/test.graph --k=2 2>&1")
    assert_match(/cut/, output)

    # Test hypergraph partitioning
    (testpath/"test.hgr").write <<~EOS
      4 3
      1 2
      1 3
      2
      2 3
    EOS
    output = shell_output("#{bin}/freight_cut #{testpath}/test.hgr --k=2 2>&1")
    assert_match(/cut/, output)
  end
end

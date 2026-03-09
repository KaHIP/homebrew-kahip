class Kahip < Formula
  desc "Karlsruhe High Quality Partitioning - graph partitioning framework"
  homepage "https://github.com/KaHIP/KaHIP"
  url "https://github.com/KaHIP/KaHIP/archive/refs/tags/v3.22.tar.gz"
  sha256 "3cbadfbf8d503351d921531413d3b66ad347a6d6e213120db87462093bb66b7c"
  license "MIT"
  head "https://github.com/KaHIP/KaHIP.git", branch: "master"

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

    # Sequential binaries
    %w[
      kaffpa graphchecker evaluator edge_evaluator
      node_separator label_propagation partition_to_vertex_separator
      edge_partitioning global_multisection node_ordering
    ].each do |name|
      bin.install "build/#{name}" if File.exist?("build/#{name}")
    end

    # MPI binaries
    bin.install "build/kaffpaE" if File.exist?("build/kaffpaE")
    %w[
      parhip distributed_edge_partitioning
      graph2binary graph2binary_external toolbox
    ].each do |name|
      path = "build/parallel/parallel_src/#{name}"
      bin.install path if File.exist?(path)
    end

    # Libraries
    lib.install "build/libkahip.a" if File.exist?("build/libkahip.a")
    lib.install "build/libkahip.so" if File.exist?("build/libkahip.so")
    lib.install "build/libkahip_static.a" if File.exist?("build/libkahip_static.a")
    parhip_lib = "build/parallel/parallel_src/libparhip_interface.a"
    lib.install parhip_lib => "libparhip.a" if File.exist?(parhip_lib)

    # Headers
    (include/"kahip").install "interface/kaHIP_interface.h"
    (include/"kahip").install "parallel/parallel_src/interface/parhip_interface.h"
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    system bin/"graphchecker", testpath/"test.graph"
    output = shell_output("#{bin}/kaffpa #{testpath}/test.graph --k 2 --preconfiguration=fast 2>&1")
    assert_match "cut", output
  end
end

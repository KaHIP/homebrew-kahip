class Sharedmap < Formula
  desc "SharedMap - Shared-Memory Algorithm for Process Mapping"
  homepage "https://github.com/KaHIP/SharedMap"
  url "https://github.com/KaHIP/SharedMap/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "53ea9081b87d5efa5496399ff155a4d3e0cecec624038ec32b48671e7a495625"
  license "MIT"
  head "https://github.com/KaHIP/SharedMap.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "patchelf" => :build
  depends_on "hwloc"
  depends_on :linux

  def install
    gcc = Formula["gcc"]
    gcc_version = gcc.version.major

    ENV["CC"] = "#{gcc.opt_bin}/gcc-#{gcc_version}"
    ENV["CXX"] = "#{gcc.opt_bin}/g++-#{gcc_version}"

    system "./build.sh"

    # Determine Mt-KaHyPar lib directory (lib vs lib64)
    mtk_libdir = if Dir.exist?("extern/local/mt-kahypar/lib64")
      "extern/local/mt-kahypar/lib64"
    else
      "extern/local/mt-kahypar/lib"
    end

    # Install bundled shared libraries (Mt-KaHyPar, TBB, Boost)
    lib.install Dir["#{mtk_libdir}/libmtkahypar*"]
    lib.install Dir["#{mtk_libdir}/libtbb*"]
    lib.install Dir["#{mtk_libdir}/libboost_*"]
    lib.install Dir["extern/local/kahip/lib/libkahip*"]
    lib.install Dir["build/libsharedmap.*"]

    # Fix RPATH so the binary finds bundled libs at runtime
    system "patchelf", "--set-rpath", lib.to_s, "build/SharedMap"

    bin.install "build/SharedMap"
    include.install Dir["include/*"]
  end

  test do
    (testpath/"test.graph").write <<~EOS
      4 5
      2 3
      1 3 4
      1 2 4
      2 3
    EOS
    output = shell_output("#{bin}/SharedMap -g #{testpath}/test.graph -h 2:2 -d 1:10 -e 0.03 -c fast -t 1 2>&1", 0)
    assert_match(/map|partition/i, output)
  end
end

class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/astrid-runtime/astrid"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.9.4/astrid-0.9.4-aarch64-apple-darwin.tar.gz"
      sha256 "72f336cb43c40598d43550422883ebdbc23de3604c180128ea365d6c11e95bf5"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.9.4/astrid-0.9.4-x86_64-apple-darwin.tar.gz"
      sha256 "2110edd2d5b59d456e2f1ead9fe35e68040d52049d417179ff2a7f6654552b06"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.9.4/astrid-0.9.4-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "976014a7ade7b03d7286143440128ba8bae9f73976fba27b6ea77e0b55ae8bfc"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.9.4/astrid-0.9.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "2a56f6a0e194a25f4eb72cefc556a4317cfb5f30204a80f2c18a4b7cc2a78f04"
    end
  end

  def install
    bin.install "astrid"
    bin.install "astrid-daemon"
    bin.install "astrid-build"
    bin.install "astrid-emit"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/astrid --version")
  end
end

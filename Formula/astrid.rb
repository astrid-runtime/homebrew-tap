class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/astrid-runtime/astrid"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.4/astrid-0.10.4-aarch64-apple-darwin.tar.gz"
      sha256 "f03fda82dd7c0396b613a91e02624e28c84d422a2cc5cf918503b0e2b4bae849"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.4/astrid-0.10.4-x86_64-apple-darwin.tar.gz"
      sha256 "adc665387114dc5aa9363eadfa525a18aa6c7d6c4348532ee5c8908018cde3a5"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.4/astrid-0.10.4-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "01533eb2dad429a0f30012b198a1efd96ee2d892d69b049ed450f14a8c2d79d5"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.4/astrid-0.10.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a7c955ff5901d98059e8e6fba6f6b6e2033224e39c06db93e48a2ebe2a4f4725"
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

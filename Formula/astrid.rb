class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/astrid-runtime/astrid"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.1/astrid-0.10.1-aarch64-apple-darwin.tar.gz"
      sha256 "3ac6a8a610b3b829964a665c2dd0063d3a66c7eb49290f7907e7ff4c2ed239b8"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.1/astrid-0.10.1-x86_64-apple-darwin.tar.gz"
      sha256 "9f526be64e8b3b3ccb1ccd84770289d7eecf53acb3ffd99f85f4d4c95ad38aff"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.1/astrid-0.10.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "74f06cbec1ff7b4e38dff34bff206f2a8a32b01f74fa9066cad315c923b84542"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.1/astrid-0.10.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "3d22a279a3cbbafd20a95af86526e6e5986e30c93391e113d0c03eddda6e001d"
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

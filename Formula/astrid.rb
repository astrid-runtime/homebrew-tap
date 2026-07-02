class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.9.1"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "52e5e9293d8ba507e959276e9072a6b5425f653f4f36ceee827c5d97bd18438e"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "4de8ec3e1b70bc7cf1b64de5da1a31bb461575541279f3e8fd9b543a8e065c4e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "1f1019aa8f1f34d95ff7b6f1c209fa656fcb92ff50d64cad02fa18cbbd4721e8"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "8d74f1bb5686d49ad9df967d7ef6b80e884b38d3b21501e8f60a91accbf6e03c"
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

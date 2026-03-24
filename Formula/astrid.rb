class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.5.0"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "89168c4e515729b1c9c93611b9bd176b2de021920b5c04f8dc96dad3b95fd8c4"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "89aa49569e2ab685b6dcdb6ee1c27147a28042a01f911fb7e03f00e9b84b69ec"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "fdb467d09852c00baad157968e3380b93e182545570f46a6c140a4c2500034d4"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "8160ba93b1c07952df5f1a4e525307d68016028f4591096b48c59f4fa7eb25b7"
    end
  end

  def install
    bin.install "astrid"
    bin.install "astrid-daemon"
    bin.install "astrid-build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/astrid --version")
  end
end

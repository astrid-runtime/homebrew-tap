class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.9.3"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "015a98eea06797714617c6ae2d0ddda3bf74d856cb7cdc3be8fa7dcbbc8ff7bb"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "fe1bc97e12ef2ac30ff407bb323eeb1929d0bb04eb3d03c8633bb6f8ac56711a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "2a6cf8eb2fdedc1a6cb8af71cc42df4d346bfb7f5495b6255ee66e5298904c5f"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "fbd22c37e6c4ee100bb51edbe3e45d733f7900ea60123facb10e0cc6ae77a4f1"
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

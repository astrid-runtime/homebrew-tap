class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.9.2"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "1b651e7d2df6f64a327527edbf5b358ef268d8d329cb7a744ea2a8c984ceb27c"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "d6102ca1ac6e7260ccd721804bece658c6e85dba0739bea7673beb1bbe7fe843"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "5afac0fedc1235f3539caa1183100d46e7fdedbcdefee7c2c0ce9365d34acd8f"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a3ee8b24139c1269622d4892e415adef5d572f222977ed5ee0c3aad7b42d58a3"
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

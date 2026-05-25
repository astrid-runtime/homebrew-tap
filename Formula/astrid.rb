class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.7.0"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "1c7ee06f4b92d40c1141a15d8ee531f37303660104a1e9249d605ccd9d0d2ec4"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "35a78f717d938e5578afe0178ebc3565ab5f22e68e3e3d74b7396e6ff5bf6680"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "19537c2916071029c0705d973ac9ddd345b15648f950d517d9a84959e17b50b9"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "ab839e9735d6835ddb6d7ac4bdb89989d2f4044c60f6762cc3af618b5a3cad78"
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

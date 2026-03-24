class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.5.1"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "97f694be3b39721befe90e1087e696b4997db1a0076a14731a688a865b527f06"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "9f5dff707cf1136f8b1fa3360c496988e8455816b385ae6ffd4da5339a7d0abc"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "75cc98c990f44c37e1c53e1c0debd244ad1b0e8b1316ada23112e11b18dc2ab8"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "c9fe6c733aca58c3cd559e2bf566710a379f5742bc0c91e57e526b00005f40b0"
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

class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/unicity-astrid/astrid"
  version "0.7.0"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "1f7c5ca598506a3d7e05042be8d4556f0a040feae5f538f7919077eb58aa9d4c"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "34861f7fcab3116e885622886b8e4299fa9938d6069498358ebf2e4bad5c2b53"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "09320f74db3e2571bc2bb1525e93beee30baf9e15f3d157fca08214ad5f6fe57"
    else
      url "https://github.com/unicity-astrid/astrid/releases/download/v#{version}/astrid-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "9fafb656058ab15e6a5fcf40da7be44e43f39787f30916fb7f72e1643ea69ea8"
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

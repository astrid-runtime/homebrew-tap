class Astrid < Formula
  desc "Microkernel for AI agents where agents write their own harness"
  homepage "https://github.com/astrid-runtime/astrid"
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.0/astrid-0.10.0-aarch64-apple-darwin.tar.gz"
      sha256 "82a040d744d1f64a5b3247473df519a6554229f2680f5bbc372eef25f2b47984"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.0/astrid-0.10.0-x86_64-apple-darwin.tar.gz"
      sha256 "23a06c4e5618a812bb520fe2e2e61cf61bad9db880831b3ba9860be6275acebb"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.0/astrid-0.10.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "bfe7b5b82c00014f3c4e9757591e19788be997e07cfc8a29aea834c38b9b716d"
    else
      url "https://github.com/astrid-runtime/astrid/releases/download/v0.10.0/astrid-0.10.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a9f442928480725a92b8937c47228cbf853ba1c40836790f888deaad347eff63"
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

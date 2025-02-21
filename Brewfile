## DEVEX

# venerable build tool
# Follow caveats during installation to complete setup
brew 'make' if OS.mac? # otherwise, assume we have GNU Make on Linux
# Python version manager
# Follow caveats during installation to complete setup
brew "pyenv"
# Manage virtualenvs with Pyenv just in case
brew "pyenv-virtualenv"
# Dockerfile linting, but only if we have Dockerfiles
brew "hadolint" unless %x[git ls-files '*Dockerfile*'].empty?
# Pre-commit checks, if we have a config
brew "pre-commit" if File.exist?(".pre-commit-config.yaml")

## TRANSITIVE DEPENDENCIES

# Some Python packages don't have Apple Silicon binary wheels available yet,
# so Poetry/Pip will have to build them from source.
if OS.mac? && Hardware::CPU.arm?
  # OS-level dependency for pyodbc
  brew "unixodbc" if system("grep -q pyodbc poetry.lock")
  # hdf5 for h5py
  brew "hdf5"  if system("grep -q h5py poetry.lock")
  # compiler with great ARM64 support, may actually be unnecessary
  # Follow caveats during installation to complete setup
  # brew "llvm"
  # package configuration tool to get library and cflags paths
  # always try to get paths from this tool instead of manually building them
  brew "pkg-config"
end

## PYTHON BUILD DEPENDENCIES
py_version = open('.python-version').read.strip.split('.').take(2).join('.')
brew "python@#{py_version}", args: ['only-dependencies']
# PyEnv suggests installing these for building Python using
# Homebrew-provided dependencies on Linux.
# This exists here primarily for running in containers, such as
# for devex CI and for demos.
# This can probably go away in favor of installing Homebrew's
# Python dependencies above, but kept here since there are
# some differences between that and what PyEnv suggests.
if OS.linux?
  brew "bzip2"
  brew "libffi"
  brew "libxml2"
  brew "libxmlsec1"
  brew "openssl@3"
  brew "readline"
  brew "sqlite"
  brew "xz"
  brew "zlib"
end

# vim: set filetype=ruby syntax=brewfile

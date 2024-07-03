#################################################
#### Automatic Pythonic Developer Experience ####
#################################################
##
## If you don't really know what to do, run `make help`.
## If you don't have make installed,
## On macOS, run `xcode-select --install` to get a BSD make, then install Homebrew and run `make deps`.
## On Linux, install make through your package manager.
##     N.b. this isn't really setup for Linux, but probably works.
##

## Source location
MODULE_BASE_DIR = example
TESTS_BASE_DIR = tests

## Pythonic variables
# These are set to determine some version information and normal paths to tooling.
# Python installation artifacts
PYTHON_VERSION_FILE=.python-version
ifeq ("$(shell which pyenv)","")
# pyenv isn't installed, guess the path
PYENV_VERSION_DIR ?= $(HOME)/.pyenv/versions/$(shell head -n 1 $(PYTHON_VERSION_FILE))
PYTHON_EXEC ?= python3
else
# pyenv is installed
PYENV_VERSION_DIR ?= $(shell pyenv root)/versions/$(shell head -n 1 $(PYTHON_VERSION_FILE))
# use just the first
PYTHON_EXEC ?= $(shell pyenv prefix | cut -d: -f1)/bin/python3
endif
POETRY_PATH = $(shell command -v poetry)
ifeq ("$(POETRY_PATH)","")
# poetry is not installed
POETRY_TASK = install-poetry
else
# poetry is installed
POETRY_TASK =
endif

# If we're on macos arm64, we might to need to build some packages,
# so set flags appropriately.
FLAGS ?=
ifeq ($(shell uname -m), arm64)
ifeq ($(shell uname -s), Darwin)
# LIBS = odbc libiodbc
F_LDFLAGS = # LDFLAGS="$(shell pkg-config --libs $(LIBS))"
F_CPPFLAGS = # CPPFLAGS="$(shell pkg-config --cflags $(LIBS))"
FLAGS ?= $(F_LDFLAGS) $(F_CPPFLAGS)
endif
endif

## Optional usage of Peru
# This enables *optional* running of Peru, which is a
# universal dependency retriever we can use to get test data.
# Essentially, if peru.yaml exists, set a variable with some
# extra tasks to run. To start, it'll just run deps-peru, which
# runs `peru sync`. Be sure to add `peru` to the dev deps in pyproject.toml
# with `poetry add --dev peru` if it's not already there when adding a new
# peru.yaml.
PERU_CONFIG ?= peru.yaml
DEPS_TASKS_IF_PERU_CONFIG =
ifneq ("$(wildcard $(PERU_CONFIG))","")
    DEPS_TASKS_IF_PERU_CONFIG = deps-peru
endif

## List of programs
# It's a good idea to avoid hardcoding tool executables in a Makefile.
# Setting them with ?= enables override, e.g. `make deps PYENV=path/to/dev/pyenv`
PYENV ?= pyenv
CURRENT_PYTHON ?= python3
PRECOMMIT ?= pre-commit
POETRY ?= $(FLAGS) poetry
PERU ?= $(POETRY) run peru
RUFF ?= $(POETRY) run ruff
BLACK ?= $(POETRY) run black
MYPY ?= $(POETRY) run mypy
PYTEST ?= $(POETRY) run pytest

###
### TASKS
###

##@ Utility

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: debug-make
debug-make: ## Shows ~all runtime-set variables
	@echo $(foreach v, $(.VARIABLES), $(info $(v) = $($(v))))


##@ Development

.PHONY: test
test: test-unittests ## Run required tests
	@echo "$(COLOR_GREEN)$(MAKECMDGOALS) succeeded$(COLOR_RESET)"

.PHONY: test-all
test-all: test-unittests test-integration  ## Run all tests
	@echo "$(COLOR_GREEN)$(MAKECMDGOALS) succeeded$(COLOR_RESET)"

# If you mark tests, you can switch to using the marks by swapping the
# commented lines in the next two tasks.

.PHONY: test-unittests
test-unittests: ## Run unit tests
	$(PYTEST) $(TESTS_BASE_DIR)/unit
# $(PYTEST) tests -m unittest

.PHONY: test-integration
test-integration: ## Run integration tests
	$(PYTEST) $(TESTS_BASE_DIR)/integration
# $(PYTEST) tests -m integration

.PHONY: check
check: check-py-ruff-format check-py-ruff-lint check-py-mypy ## Run all checks

.PHONY: check-py-ruff-lint
check-py-ruff-lint: ## Run ruff linter
	$(RUFF) $(RUFF_OPTS) check $(MODULE_BASE_DIR) $(TESTS_BASE_DIR) || \
		(echo "$(COLOR_RED)Run '$(notdir $(MAKE)) check-py-ruff-fix' to fix some of these automatically if [*] appears above, then run '$(notdir $(MAKE)) $(MAKECMDGOALS)' again." && false)

.PHONY: check-py-ruff-fix
check-py-ruff-fix: ## Run ruff linter
	$(MAKE) check-py-ruff-lint RUFF_OPTS=--fix

.PHONY: check-py-black
check-py-black: ## Runs black code formatter
	$(BLACK) --check --fast .

.PHONY: check-py-ruff-format
check-py-ruff-format: ## Runs ruff code formatter
	$(RUFF) $(RUFF_OPTS) format --check .

BUILD_DIR ?= build
REPORTS_DIR = $(BUILD_DIR)/reports
MYPY_OPTS ?= --show-column-numbers --pretty --html-report $(REPORTS_DIR)/mypy
.PHONY: check-py-mypy
check-py-mypy: ## Run MyPy typechecker
	$(MYPY) $(MYPY_OPTS) $(MODULE_BASE_DIR) $(TESTS_BASE_DIR)

.PHONY: check-precommit
check-precommit: ## Runs pre-commit on all files
	$(PRECOMMIT) run --all-files

.PHONY: format-py
format-py: ## Runs formatter, makes changes where necessary
	$(RUFF) format .

##@ Building and Publishing

.PHONY: build
build: poetry-build ## Build an artifact

.PHONY: publish
publish: poetry-publish ## Publish an artifact


##@ Manual Setup

.PHONY: install-homebrew
install-homebrew: ## Install Homebrew
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | NONINTERACTIVE=1 bash -

# file(s) written by pre-commit setup
GIT_HOOKS = .git/hooks/pre-commit
.PHONY: install-precommit
install-precommit: $(GIT_HOOKS) ## Sets up pre-commit hooks
	@echo "$(COLOR_GREEN)Pre-commit configured, will run on future commits!$(COLOR_RESET)"

$(GIT_HOOKS): .pre-commit-config.yaml
	$(PRECOMMIT) install

.PHONY: does-path-have-reqs
does-path-have-reqs: ## Check if shell $PATH has expected elements
	@echo "$(COLOR_BLUE)Checking PATH elements for evidence of package managers…$(COLOR_RESET)"
	@( (echo $${PATH} | grep -q poetry ) && echo "found poetry") || (echo "missing poetry" && false)
	@( (echo $${PATH} | grep -q homebrew ) && echo "found homebrew") || (echo "missing homebrew" && false)
	@( (echo $${PATH} | grep -q pyenv ) && echo "found pyenv") || (echo "missing pyenv" && false)
	@echo "$(COLOR_GREEN)All expected PATH elements found$(COLOR_RESET)"

##@ Dependencies

.PHONY: python-current
python-current: ## Display the version and binary location of python3
	@echo CURRENT_PYTHON = $(shell which $(CURRENT_PYTHON))
	@$(CURRENT_PYTHON) --version
	@echo PYTHON_EXEC = $(PYTHON_EXEC)

.PHONY: install-poetry
install-poetry: ## Installs Poetry to the current Python environment
	@echo "$(COLOR_ORANGE)Installing Poetry from python-poetry.org with $(CURRENT_PYTHON)$(COLOR_RESET)"
	curl -sSL https://install.python-poetry.org | $(CURRENT_PYTHON) -

.PHONY: deps
deps: deps-brew deps-py $(DEPS_TASKS_IF_PERU_CONFIG) install-precommit ## Installs all dependencies
	@echo "$(COLOR_GREEN)All deps installed!$(COLOR_RESET)"
.PHONY: deps-py
deps-py: install-python $(POETRY_TASK) poetry-use-pyenv poetry-install ## Install Python-based dependencies
	@echo "$(COLOR_GREEN)All Python deps installed!$(COLOR_RESET)"
.PHONY: deps-py-update
deps-py-update: poetry-update ## Update Poetry deps, e.g. after adding a new one manually
	@echo "$(COLOR_GREEN)All Python deps updated!$(COLOR_RESET)"

COLOR_ORANGE = \033[33m
COLOR_BLUE = \033[34m
COLOR_RED = \033[31m
COLOR_GREEN = \033[32m
COLOR_RESET = \033[0m
.PHONY: deps-brew
deps-brew: ## Installs development dependencies from Homebrew
	brew bundle install $(BREW_BUNDLE_OPTS) --no-lock --verbose --file=Brewfile
	@test -n "$(PYENV_SHELL)" || ( \
		echo "$(COLOR_ORANGE)PYENV_SHELL is empty so pyenv may not be setup.$(COLOR_RESET)" && \
		echo "$(COLOR_ORANGE)Ensure that pyenv is setup in your shell config, e.g. in ~/.bashrc.$(COLOR_RESET)" && \
		echo "$(COLOR_ORANGE)It should have something like this:$(COLOR_RESET)" && \
		echo "$(COLOR_BLUE)\teval \"\$$(pyenv init --path)\"$(COLOR_RESET)" && \
		echo "$(COLOR_BLUE)\teval \"\$$(pyenv init -)\"$(COLOR_RESET)" && \
		echo "$(COLOR_BLUE)\teval \"\$$(pyenv virtualenv-init -)\"$(COLOR_RESET)" && \
		echo "$(COLOR_ORANGE)You may want to wrap them inside of a check for pyenv.$(COLOR_RESET)" \
    )
	@echo "$(COLOR_ORANGE)There may be formula caveats requiring action to activate.$(COLOR_RESET)" && \
		echo "$(COLOR_ORANGE)Please read the 'brew info <pkg>' for each package carefully.$(COLOR_RESET)"
	@command -v $(PYENV) > /dev/null || \
		echo "$(COLOR_RED)Run your make command again after adding the above so that $(PYENV) is available.$(COLOR_RESET)"

.PHONY: deps-peru
deps-peru: $(PERU_CONFIG) ## Installs dependencies from Peru
	$(PERU) sync
	@echo "$(COLOR_GREEN)All Peru modules sync'd!$(COLOR_RESET)"

.PHONY: deps-ci
deps-ci: poetry-install $(DEPS_TASKS_IF_PERU_CONFIG)  ## Install CI check and test dependencies (assumes Python & Poetry already present in env)
	@echo "$(COLOR_GREEN)All CI dependencies installed!$(COLOR_RESET)"

.PHONY: install-python
install-python: $(PYTHON_EXEC) ## Installs appropriate Python version
	@echo "$(COLOR_GREEN)Python installed to $(PYTHON_EXEC)$(COLOR_RESET)"

# Pyenv already automatically uses Homebrew's libraries if available on macOS
ifeq ($(shell uname -s), Darwin)
PYENV_FLAGS =
endif
# Force use of Homebrew's libraries in Linux
# Pyenv discourages this, preferring use of distro-provided libraries.
# We want to link against Homebrew for dev workstation use, but rely on
# distro Python in CI, which is why deps-ci doesn't install Python!
ifeq ($(shell uname -s), Linux)
PYENV_FLAGS = CFLAGS="$(shell pkg-config --cflags libffi ncurses readline)" \
		LDFLAGS="$(shell pkg-config --libs libffi ncurses readline)" \
		CC="$(firstword $(wildcard $(shell brew --prefix gcc)/bin/gcc-*))"
endif

$(PYTHON_EXEC): $(PYTHON_VERSION_FILE)
	@echo "$(COLOR_BLUE)Installing Pythons from $(PYTHON_VERSION_FILE) using $(PYENV):$(COLOR_ORANGE)"
	@grep ^[^\n#] $(PYTHON_VERSION_FILE) | sed -e 's/^/\t/'
	@echo "$(COLOR_RESET)"

	grep ^[^\n#] $(PYTHON_VERSION_FILE) | while read -r py ; do \
		$(PYENV_FLAGS) $(PYENV) install --verbose --skip-existing "$${py}" ; \
	done

##@ Poetry

.PHONY: poetry-install
poetry-install: ## Run poetry install with any environment-required flags
	$(POETRY) install

.PHONY: poetry-update
poetry-update: ## Run poetry update with any environment-required flags, pass PKGS=pkg to update only pkg
	time $(POETRY) update -v $(PKGS)

.PHONY: poetry-relock
poetry-relock: pyproject.toml ## Run poetry lock w/o updating deps, use after changing pyproject.toml trivially
	$(POETRY) lock --no-update

.PHONY: poetry-build
poetry-build: poetry-set-version ## Run poetry build with any environment-required flags
	$(POETRY) build

# For release builds, pass this into poetry-set-version-from-git, e.g. ARTIFACT_VERSION=${CI_BUILD_TAG}
ifndef ARTIFACT_VERSION
ARTIFACT_VERSION = $(shell git describe --tags | sed -e 's/-/+/')
endif

.PHONY: poetry-set-version
poetry-set-version: ## Sets project version from git tag; invoke with ARTIFACT_VERSION=something to override
	$(POETRY) version $(ARTIFACT_VERSION)

.PHONY: poetry-publish
poetry-publish: ## Run poetry's publisher
# necessitates setting envvars: poetry_http_basic_publish_source_{username,password}
	$(POETRY) publish -vv --repository publish-source

.PHONY: poetry-export
poetry-export: dist/requirements.txt ## Export a requirements.txt for use with pip
	@echo "$(COLOR_GREEN)Dependencies exported.$(COLOR_RESET)"

dist/requirements.txt: poetry.lock pyproject.toml
	@mkdir -p dist
	$(POETRY) export --verbose --without-hashes --format requirements.txt --output "$@"

.PHONY: poetry-debug
poetry-debug: ## Shows Poetry debug include any envvars passed to Poetry
	@echo POETRY=$(POETRY)
	$(POETRY) debug

.PHONY: poetry-use-pyenv
poetry-use-pyenv: $(PYTHON_VERSION_FILE) ## Configure Poetry to use the expected base Python for its virtualenv
	@echo "$(COLOR_BLUE)Configuring Poetry to use $(PYTHON_EXEC) for its virtualenv$(COLOR_RESET)"
	$(POETRY) env use $(PYTHON_EXEC)

.PHONY: poetry-implode-venv
poetry-implode-venv: ## Destroys the Poetry-managed virtualenv
	sleep 2 && rm -rf $$($(POETRY) env info --path)

.PHONY: poetry-venv-path
poetry-venv-path: ## Shows the path to the currently active Poetry-managed virtualenv
	@$(POETRY) env list --full-path | grep Activated | cut -f 1 -d ' '

.PHONY: fix-poetry-conflicts
fix-poetry-conflicts: ## Attempts to fix Poetry merge/rebase conflicts by choosing theirs and locking again
	git checkout --theirs poetry.lock
	$(MAKE) poetry-relock

.PHONY: fix-poetry-conflicts-2
fix-poetry-conflicts-2: ## Another way to try to fix Poetry merge/rebase conflicts
	git restore --staged --worktree poetry.lock
	$(MAKE) poetry-relock

##@ Miscellaneous

.PHONY: all
all:
.PHONY: clean
clean: ## Clean artifacts from build and dist directories
	rm -rf $(BUILD_DIR) dist/requirements.txt

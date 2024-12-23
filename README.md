# Example repo for Make Python Devex

This repository contains a simple Python® project setup
using the Make Python DevEx system described and built by Colin Dean.
Read more about why this exists at the Target Tech blog post
[Make Python DevEx](https://tech.target.com/blog/make-python-devex).

> [!TIP]
> **Quickstart:** With [Homebrew](https://brew.sh) installed and `brew` available (`which brew`):
> ```bash
> # if you use the gh CLI tool
> gh repo clone target/make-python-devex
> # or just git
> git clone https://github.com/target/make-python-devex.git
> # then set it up, run deps twice in separate invocations
> make deps
> make deps check test build

Run `make help` to see the tasks available.

In theory, run `make deps` until it succeeds, following any instructions output
in the meantime.
Then, run `make check test build` to build the distributable.
Run `poetry run example-make-python-devex` to see the app in action.

This system was built for and tested primarily on Apple® macOS® 11 and later.
It may work on Linux with adjustments; PRs welcome.

## Legal Notices

See [LICENSE](LICENSE.md) for licensing information.

"Python" and the Python logos are trademarks or registered trademarks of the Python Software Foundation,
used by Target [with permission](https://www.python.org/psf/trademarks/#how-to-use-the-trademarks) from the Foundation.

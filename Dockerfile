# Base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    make git curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Poetry for dependency management
RUN pip install --no-cache-dir poetry

# Clone the Make Python DevEx repository
RUN git clone https://github.com/target/make-python-devex.git .

# Install project dependencies using Makefile
RUN make deps && make deps

# Run checks, tests, and build the project
RUN make check test build

# Expose the default port (if the application runs on a specific port, update this)
EXPOSE 8000

# Command to run the application
CMD ["poetry", "run", "example-make-python-devex"]

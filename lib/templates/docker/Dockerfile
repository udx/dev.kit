# make build
FROM usabilitydynamics/udx-worker:0.35.0

LABEL maintainer="UDX"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Reuse UDX Worker PATH pattern from line 13
# ENV PATH="${HOME}/.porter:${HOME}/.local/bin:${PATH}"

# Set root user for system-wide installation
USER root

# Ensure directory and permissions are set for 'udx' user
# RUN mkdir -p "${HOME}/.porter" "${HOME}/.local/bin" && \
#     chown -R "${USER}:${USER}" "${HOME}"

# Switch to non-root user for security
# USER ${USER}

# Install dependencies
# RUN apt-get update && \
#     apt-get install -y git 

# Install bins to local bin
# RUN curl -LO "https://github.com/oras-project/oras/releases/download/v1.3.0/oras_1.3.0_linux_amd64.tar.gz" && \
#     tar -zxf oras_1.3.0_linux_amd64.tar.gz -C "${HOME}/.local/bin" oras && \
#     rm oras_1.3.0_linux_amd64.tar.gz

# COPY scripts from the project root context
# COPY --chown="${USER}:${USER}" bin/ "${HOME}/.local/bin/"
# RUN chmod +x "${HOME}/.local/bin/"*

# Set working directory
# WORKDIR ${HOME}

# Default command
# CMD ["tail", "-f", "/dev/null"]
# CMD ["/bin/bash", "-c", "bin/init.sh"]
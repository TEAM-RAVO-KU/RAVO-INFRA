# dnf-utils
dnf install -y dnf-utils

# Add the official Docker repository to your package sources.
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Install Docker and all required dependency packages such as containerd.io
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker --now

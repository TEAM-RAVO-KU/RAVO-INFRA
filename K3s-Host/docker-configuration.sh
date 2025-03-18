# dnf-utils
dnf install -y dnf-utils

# Add the official Docker repository to your package sources.
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

# Install Docker and all required dependency packages such as containerd.io
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# set symbolic link and permission
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

systemctl enable docker --now

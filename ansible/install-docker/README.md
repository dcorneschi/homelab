# Docker Installation Ansible Playbook

This Ansible playbook automates the installation of Docker CE on Ubuntu/Debian systems. It provides a complete setup including Docker Engine, CLI tools, and additional plugins.

[![Ansible](https://img.shields.io/badge/Ansible-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

## Overview

The playbook performs the following tasks:
- Updates the apt package cache
- Installs required dependencies for Docker installation
- Adds Docker's official GPG key and repository
- Installs Docker CE with additional components
- Configures Docker service to start automatically
- Adds specified users to the docker group
- Verifies the installation

## Prerequisites

- **Ansible**: Version 2.9 or higher
- **Target Systems**: Ubuntu 16.04+ or Debian 9+
- **SSH Access**: Configured SSH key-based authentication to target hosts
- **Sudo Privileges**: The ansible user must have sudo access on target hosts

## Directory Structure

```
install-docker/
├── README.md
├── install-docker.yml    # Main playbook
└── inventory.ini        # Inventory file with target hosts
```

## Components Installed

The playbook installs the following Docker components:
- **docker-ce**: Docker Community Edition engine
- **docker-ce-cli**: Docker command-line interface
- **containerd.io**: Container runtime
- **docker-buildx-plugin**: Extended build capabilities
- **docker-compose-plugin**: Docker Compose V2

## Configuration

### Inventory Configuration

Edit the `inventory.ini` file to specify your target hosts:

```ini
[docker_servers]
srv-dev-01 ansible_host=192.168.50.5 ansible_user=dcorneschi
srv-dev-02 ansible_host=192.168.50.6 ansible_user=dcorneschi

[docker_servers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Variables

The playbook includes the following configurable variables:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `docker_users` | `{{ ansible_user }}` | List of users to add to docker group |

You can override these variables in several ways:
- In the playbook vars section
- In group_vars or host_vars files
- Via command line with `-e` flag

## Usage

### Basic Installation

Run the playbook against all hosts in the inventory:

```bash
ansible-playbook -i inventory.ini install-docker.yml
```

### Installation with Custom Variables

Install Docker and add specific users to the docker group:

```bash
ansible-playbook -i inventory.ini install-docker.yml -e "docker_users=['user1','user2','user3']"
```

### Target Specific Hosts

Run against a subset of hosts:

```bash
ansible-playbook -i inventory.ini install-docker.yml --limit srv-dev-01
```

### Dry Run

Test the playbook without making changes:

```bash
ansible-playbook -i inventory.ini install-docker.yml --check
```

### Verbose Output

Run with detailed output for debugging:

```bash
ansible-playbook -i inventory.ini install-docker.yml -v
```

## Post-Installation

After successful installation:

1. **Verify Docker is running**:
   ```bash
   sudo systemctl status docker
   ```

2. **Test Docker functionality**:
   ```bash
   docker run hello-world
   ```

3. **Check Docker version**:
   ```bash
   docker --version
   docker compose version
   ```

4. **Users in docker group may need to log out and back in** for group membership to take effect.

## Supported Operating Systems

- Tested on Ubuntu 20.04 LTS (Focal Fossa)

## Security Considerations

- The playbook adds users to the docker group, which grants root-equivalent access
- Docker daemon runs as root by default
- Consider implementing Docker's rootless mode for enhanced security
- Review Docker's security best practices documentation

## Troubleshooting

### Common Issues

1. **GPG Key Issues**:
   ```bash
   # Manual GPG key verification
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```

2. **Repository Issues**:
   ```bash
   # Verify repository configuration
   cat /etc/apt/sources.list.d/docker.list
   ```

3. **Service Start Issues**:
   ```bash
   # Check Docker service logs
   sudo journalctl -u docker.service
   ```

4. **Permission Issues**:
   ```bash
   # Verify user is in docker group
   groups $USER
   ```

### Log Locations

- Docker service logs: `journalctl -u docker`
- Ansible logs: Use `-v` flag for verbose output during playbook execution

## Customization

### Adding Custom Docker Configuration

Create a custom docker daemon configuration by extending the playbook:

```yaml
- name: Create Docker daemon configuration
  copy:
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
    dest: /etc/docker/daemon.json
    mode: '0644'
  notify: restart docker
```

### Installing Specific Docker Version

Modify the installation task to specify a version:

```yaml
- name: Install specific Docker CE version
  apt:
    name:
      - docker-ce=5:24.0.0-1~ubuntu.20.04~focal
      - docker-ce-cli=5:24.0.0-1~ubuntu.20.04~focal
    state: present
    allow_downgrade: yes
```

## License

This playbook is provided as-is for educational and operational use.

## Support

For issues related to:
- **Docker**: Refer to [Docker Documentation](https://docs.docker.com/)
- **Ansible**: Refer to [Ansible Documentation](https://docs.ansible.com/)

---

**Last Updated**: 2025-08-27

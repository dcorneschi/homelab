# Package Update Playbook

This Ansible playbook updates all packages on both Ubuntu/Debian and Red Hat/CentOS/RHEL systems.

![Ansible](https://img.shields.io/badge/Ansible-EE0000?logo=ansible&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-D70A53?logo=debian&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white)
![Red Hat](https://img.shields.io/badge/Red%20Hat-EE0000?logo=redhat&logoColor=white)
![Rocky Linux](https://img.shields.io/badge/Rocky%20Linux-10B981?logo=rockylinux&logoColor=white)
![AlmaLinux](https://img.shields.io/badge/AlmaLinux-262577?logo=almalinux&logoColor=white)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dcorneschi)

## Features

- **Multi-distribution support**: Works with Ubuntu, Debian, RHEL, CentOS, Rocky Linux, AlmaLinux
- **Version detection**: Automatically detects OS version and uses appropriate package manager (apt/yum/dnf)
- **Kernel handling**: Handles kernel updates separately on Red Hat systems
- **Reboot management**: Detects when reboot is required and optionally performs it
- **Cache management**: Cleans package cache after updates
- **Comprehensive reporting**: Shows update summary for each host

## Supported Systems

### Ubuntu/Debian Family
- Ubuntu 20.04, 22.04, 24.04
- Debian 10, 11, 12
- Uses `apt` package manager

### Red Hat Family
- RHEL 7, 8, 9
- CentOS 7, 8 Stream, 9 Stream
- Rocky Linux 8, 9
- AlmaLinux 8, 9
- Uses `yum` (version 7) or `dnf` (version 8+)

## Usage

### Basic Usage

```bash
# Update all servers in inventory
ansible-playbook -i inventory.ini update-all-packages.yml

# Update specific group only
ansible-playbook -i inventory.ini update-all-packages.yml --limit ubuntu_servers

# Update with automatic reboot if required
ansible-playbook -i inventory.ini update-all-packages.yml -e "force_reboot=true"

# Dry run (check what would be updated)
ansible-playbook -i inventory.ini update-all-packages.yml --check

# Run only Ubuntu-specific tasks
ansible-playbook -i inventory.ini update-all-packages.yml --tags ubuntu

# Run only Red Hat-specific tasks
ansible-playbook -i inventory.ini update-all-packages.yml --tags redhat

# Skip reboot even if required
ansible-playbook -i inventory.ini update-all-packages.yml --skip-tags reboot
```

### Configuration Variables

You can customize the playbook behavior using variables:

```bash
# Force reboot regardless of detection
ansible-playbook -i inventory.ini update-all-packages.yml -e "force_reboot=true"

# Set custom reboot timeout (default: 300 seconds)
ansible-playbook -i inventory.ini update-all-packages.yml -e "reboot_timeout=600"

# Disable automatic reboot detection
ansible-playbook -i inventory.ini update-all-packages.yml -e "reboot_required=false"
```

### Advanced Usage

#### Group-specific execution:
```bash
# Update only Ubuntu servers
ansible-playbook -i inventory.ini update-all-packages.yml --limit ubuntu_servers

# Update only Red Hat servers  
ansible-playbook -i inventory.ini update-all-packages.yml --limit redhat_servers

# Update specific host
ansible-playbook -i inventory.ini update-all-packages.yml --limit web1
```

#### Parallel execution:
```bash
# Run on 5 hosts in parallel (default is 5)
ansible-playbook -i inventory.ini update-all-packages.yml -f 10
```

#### Verbose output:
```bash
# Verbose output
ansible-playbook -i inventory.ini update-all-packages.yml -v

# Very verbose (debug level)
ansible-playbook -i inventory.ini update-all-packages.yml -vvv
```

#### Run without SSH keys:
```bash
ansible-playbook -i inventory.ini update-all-packages.yml -kK
```

## What the Playbook Does

### Ubuntu/Debian Systems:
1. Updates apt cache
2. Performs `dist-upgrade` to update all packages
3. Removes orphaned packages (`autoremove`)
4. Cleans package cache (`autoclean`)
5. Checks for reboot requirement (`/var/run/reboot-required`)

### Red Hat Systems:
1. Updates package manager cache (yum/dnf)
2. Updates all packages except kernel
3. Handles kernel updates separately
4. Removes orphaned packages
5. Cleans package cache
6. Determines reboot requirement based on kernel updates

### Common Tasks:
1. Displays system information
2. Provides upgrade summary
3. Optionally reboots systems if required
4. Verifies systems come back online after reboot

## Security Considerations

- The playbook runs with `become: yes` (sudo privileges)
- SSH key authentication is recommended
- Consider running in check mode first: `--check`
- Review the inventory file for correct SSH settings
- Test on non-production systems first

## Troubleshooting

### Common Issues:

1. **SSH Connection Failed**:
   ```bash
   # Test connection first
   ansible -i inventory.ini all -m ping
   ansible -i inventory.ini all -m ping -kK           # without SSH keys
   ```

2. **Permission Denied**:
   ```bash
   # Ensure user has sudo privileges
   ansible -i inventory.ini all -m shell -a "sudo whoami" --ask-become-pass
   ```

### Log Files:

- Ubuntu/Debian: `/var/log/apt/`
- Red Hat: `/var/log/yum.log` or `/var/log/dnf.log`
- Ansible logs: Use `-v` flags for verbose output

## Tags Available

- `ubuntu`: Run only Ubuntu/Debian tasks
- `redhat`: Run only Red Hat tasks  
- `cleanup`: Run only cleanup tasks
- `reboot`: Run only reboot-related tasks

Use `--tags` or `--skip-tags` to control execution.

## License

This playbook is provided as-is for educational and operational use.

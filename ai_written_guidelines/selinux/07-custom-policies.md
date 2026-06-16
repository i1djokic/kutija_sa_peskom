# Custom Policies

When there's no boolean and changing the context isn't appropriate, create a custom policy module.

## audit2allow — Generate Policy from Denials

The easiest way to create a policy: let SELinux tell you what's needed.

```bash
# 1. Generate the denial (run your application)
# 2. Check the audit log
sudo ausearch -m avc -ts recent

# 3. Generate and show the policy rule
sudo ausearch -m avc -ts recent | audit2allow

# 4. Create a policy module
# -M gives the module a name (you'll see myapp.pp and myapp.te appear)
sudo ausearch -m avc -ts recent | audit2allow -M myapp

# This produces:
#   myapp.pp  — the compiled policy module (binary, loadable)
#   myapp.te  — the source policy file (readable, can be edited)

# 5. Load the module
sudo semodule -i myapp.pp

# 6. Verify it's loaded
sudo semodule -l | grep myapp
```

## Manual Policy File (.te)

For more complex needs (or when you want to understand exactly what's allowed), write the policy by hand.

```bash
# myapp.te
module myapp 1.0;

require {
    type httpd_t;       # The domain of the process (from scontext)
    type var_t;         # The type of the target (from tcontext)
    class file { read write };  # What kind of object and what operations
}

# Allow httpd to read and write var_t files
allow httpd_t var_t:file { read write };
```

**How to find the values for `require`:** Look at the AVC denial message. The `scontext` gives you the process domain, the `tcontext` gives you the target type, and `tclass` gives you the object class. The denied permissions are in `{ }`.

```
avc: denied { write }    →  put these in class's { }
scontext=httpd_t         →  type httpd_t;
tcontext=var_t           →  type var_t;
tclass=file              →  class file
```

## Compiling a Module

Before you can compile a `.te` file, you need the policy development tools:

```bash
# Fedora/RHEL
sudo dnf install policycoreutils-devel checkpolicy selinux-policy-devel

# Debian/Ubuntu
sudo apt install selinux-policy-dev checkpolicy
```

Then compile:

```bash
# Compile .te to .pp (easiest — uses the system's policy Makefile)
make -f /usr/share/selinux/devel/Makefile myapp.pp

# Or manually (step by step):
checkmodule -M -m myapp.te -o myapp.mod
semodule_package -o myapp.pp -m myapp.mod
```

## Managing Modules

```bash
# List loaded modules
sudo semodule -l

# List with details
sudo semodule -lfull

# Install a module
sudo semodule -i myapp.pp

# Remove a module
sudo semodule -r myapp

# Update a module (reinstall)
sudo semodule -u myapp.pp

# Enable a disabled module
sudo semodule -e myapp

# Disable a module (without removing)
sudo semodule -d myapp
```

## Module Location

- Installed modules: `/etc/selinux/targeted/modules/active/modules/`
- Source policy: `/etc/selinux/targeted/modules/active/modules/myapp.te` (if saved)
- Custom modules are stored in the policy store after `semodule -i`

## Example: Allow httpd to Read Custom Directory

```
# From audit log:
# denied { read } for pid=1234 comm="httpd" name="custom_data"
# scontext=httpd_t  tcontext=default_t:file
```

```bash
# Generate module
sudo ausearch -m avc -ts recent | audit2allow -M httpd_custom_data

# This creates httpd_custom_data.pp
# Load it
sudo semodule -i httpd_custom_data.pp
```

Generated `.te` file:

```cpp
module httpd_custom_data 1.0;

require {
    type httpd_t;
    type default_t;
    class file read;
}

allow httpd_t default_t:file read;
```

## When to Use Custom Policies vs Other Methods

| Situation | Best approach |
|-----------|--------------|
| Wrong file context | `restorecon` or `semanage fcontext` |
| Missing boolean | `setsebool -P` |
| Wrong port label | `semanage port` |
| Process needs specific access not covered above | Custom policy via `audit2allow` |
| Third-party application | Custom policy |
| Complex rules (multiple types) | Hand-written `.te` |

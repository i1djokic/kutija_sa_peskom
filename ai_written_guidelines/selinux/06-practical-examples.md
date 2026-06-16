# Practical Examples

## Web Server (httpd) Can't Read Files

```
# Denial: httpd_t cannot read file with type var_t
# scontext=httpd_t  tcontext=var_t
```

**Problem:** Files were placed in `/var/www/html/` with the wrong context (e.g., moved with `mv` instead of `cp`).

**Fix — restore context:**

```bash
sudo restorecon -Rv /var/www/
```

**Fix — persistent rule for a custom directory:**

```bash
# If web files are in /web (not /var/www)
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"
sudo restorecon -Rv /web
```

## Web Server (httpd) Can't Write to Files

```
# Denial: httpd_t cannot write file with type httpd_sys_content_t
```

**Problem:** httpd needs write access (e.g., uploads, CMS cache).

**Fix — change type to writable:**

```bash
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/uploads(/.*)?"
sudo restorecon -Rv /var/www/html/uploads
```

## Web Server (httpd) Can't Connect to Database

```
# Denial: httpd_t cannot connect to tcp_socket port 3306
```

**Fix — enable the boolean:**

```bash
sudo setsebool -P httpd_can_network_connect_db on
```

## Web Server Is a Reverse Proxy

```
# Denial: httpd_t cannot connect to network
```

**Fix — enable the boolean:**

```bash
sudo setsebool -P httpd_can_network_connect on
```

## Custom Application Running on Port 9000

```
# Denial: myapp_t cannot bind to port 9000
```

**Fix — add port to policy:**

```bash
# First, identify the domain (type) your process is running as
ps auxZ | grep myapp
# Example output: system_u:system_r:myapp_t:s0   ← domain is myapp_t

# Find which port type your app's domain is allowed to use:
# (check the closest existing port type for similar apps)
sudo semanage port -l | grep http

# Add the port to the appropriate type
sudo semanage port -a -t http_port_t -p tcp 9000
```

If your app has its own domain (not httpd_t), you may need to write a custom policy instead. See [07-custom-policies.md](./07-custom-policies.md).

## SSH Can't Do Chroot

**Fix — enable the boolean:**

```bash
sudo setsebool -P ssh_chroot_rw_homedirs on
```

## Samba Can't Share Home Directories

**Fix — enable booleans and set context:**

```bash
sudo setsebool -P samba_enable_home_dirs on
sudo chcon -t samba_share_t /home/user/shared_folder
```

Or permanent:

```bash
sudo semanage fcontext -a -t samba_share_t "/home/user/shared_folder(/.*)?"
sudo restorecon -Rv /home/user/shared_folder
```

## FTP Can't Write to Upload Directory

```bash
sudo semanage fcontext -a -t public_content_rw_t "/var/ftp/upload(/.*)?"
sudo restorecon -Rv /var/ftp/upload
sudo setsebool -P ftp_home_dir on
```

## Moving vs Copying Files (Common Pitfall)

```bash
# mv preserves the original context
mv /home/user/index.html /var/www/html/   # keeps user_home_t context
# → httpd cannot read user_home_t

# cp creates new file with parent directory context
cp /home/user/index.html /var/www/html/   # gets httpd_sys_content_t
# → httpd can read httpd_sys_content_t

# Fix after mv:
sudo restorecon -v /var/www/html/index.html
```

## Nginx on Non-Default Port

```bash
# Nginx tries to bind to port 8080
# Denial: nginx_t cannot bind to port 8080

sudo semanage port -a -t http_port_t -p tcp 8080
```

## NFS Share Can't Be Read by httpd

```bash
sudo setsebool -P httpd_use_nfs on
```

## Making a Process Permissive (While System Stays Enforcing)

For troubleshooting, you can make a specific domain permissive:

```bash
# Allow httpd to run in permissive mode
sudo semanage permissive -a httpd_t

# Remove the permissive exemption
sudo semanage permissive -d httpd_t
```

This is useful when you want the rest of the system to stay protected while you debug one application.

## Complete Example: Setting Up a Custom Web App

```bash
# 1. Create the directory
sudo mkdir -p /webapp

# 2. Set persistent file context
sudo semanage fcontext -a -t httpd_sys_content_t "/webapp(/.*)?"

# 3. Apply it
sudo restorecon -Rv /webapp

# 4. Place your files
cp -r ./myapp/* /webapp/

# 5. If the app needs uploads directory
sudo mkdir /webapp/uploads
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/webapp/uploads(/.*)?"
sudo restorecon -Rv /webapp/uploads

# 6. If the app connects to a database
sudo setsebool -P httpd_can_network_connect_db on

# 7. If the app sends email
sudo setsebool -P httpd_can_sendmail on

# 8. Verify
sudo ausearch -m avc -ts recent
```

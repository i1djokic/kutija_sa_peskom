# Apache Role

Installs and configures Apache HTTP server.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `apache_service` | `httpd` / `apache2` | Service name (OS-dependent) |
| `apache_listen_port` | `80` | HTTP listen port |
| `apache_servername` | `localhost` | Server name |
| `apache_document_root` | `/var/www/html` | Document root |
| `apache_modules_enabled` | `[rewrite, ssl, headers]` | Apache modules to enable |
| `apache_vhosts` | list | Virtual host definitions |

## Dependencies

None.

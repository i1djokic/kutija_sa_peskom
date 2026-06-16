# Templating

## Jinja2 (config generation, file templating)

```bash
pip install jinja2
```

### Basic usage

```python
from jinja2 import Template

template = Template("Hello {{ name }}!")
result = template.render(name="World")
# "Hello World!"
```

### File templates

```python
from jinja2 import Environment, FileSystemLoader

env = Environment(
    loader=FileSystemLoader("templates/"),
    trim_blocks=True,
    lstrip_blocks=True,
)

template = env.get_template("config.yaml.j2")
output = template.render(
    app_name="myapp",
    port=8080,
    debug=True,
    database_url="postgres://localhost:5432/db",
)
Path("output/config.yaml").write_text(output)
```

### Template example (config.yaml.j2)

```yaml
# templates/config.yaml.j2
app:
  name: "{{ app_name }}"
  port: {{ port }}
  debug: {{ debug | lower }}

database:
  url: "{{ database_url }}"
  pool_size: {{ pool_size | default(10) }}

logging:
  level: "{{ log_level | default('INFO') }}"
  format: "%(asctime)s %(levelname)s %(message)s"

{% if features %}
features:
{% for feature in features %}
  - {{ feature }}
{% endfor %}
{% endif %}
```

### Template with includes

```yaml
# templates/docker-compose.yml.j2
version: "3.8"

services:
  web:
    image: "{{ image_name }}:{{ tag }}"
    ports:
      - "{{ port }}:{{ port }}"
    environment:
      {% include "partials/env.j2" %}
```

### Generating shell scripts

```jinja
#!/usr/bin/env bash
set -euo pipefail

# {{ description }}
# Generated: {{ generated_at }}

APP_NAME="{{ app_name }}"
APP_DIR="/opt/{{ app_name }}"

{% for cmd in setup_commands %}
{{ cmd }}
{% endfor %}

echo "Setup complete for {{ app_name }}"
```

### Nginx config template

```jinja
server {
    listen {{ port }};
    server_name {{ server_name }};

    location / {
        proxy_pass http://127.0.0.1:{{ upstream_port }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        {% if rate_limit %}
        limit_req zone=mylimit burst={{ rate_limit.burst | default(20) }} nodelay;
        {% endif %}
    }

    location /health {
        return 200 "OK";
    }
}
```

### Loading from strings

```python
from jinja2 import Environment

env = Environment()
template = env.from_string("Host: {{ host }}:{{ port }}")
result = template.render(host="0.0.0.0", port=8080)
```

### Filters

```python
env.filters["to_json"] = lambda v: json.dumps(v, indent=2)
env.filters["quote"] = shlex.quote
```

### Template inheritance

```jinja
{# templates/base.conf.j2 #}
# {{ app_name }} configuration
# Auto-generated, do not edit

{% block content %}{% endblock %}
```

```jinja
{# templates/nginx.conf.j2 #}
{% extends "base.conf.j2" %}
{% block content %}
server {
    listen {{ port }};
    ...
}
{% endblock %}
```

## string.Template (stdlib, no dependencies)

```python
from string import Template

t = Template("Hello $name, your balance is $balance")
result = t.substitute(name="Alice", balance=100)

# With safe substitution (missing vars stay as-is)
result = t.safe_substitute(name="Alice")
```

## f-strings (for simple cases)

```python
name = "Alice"
port = 8080
config = f"""
app:
  name: {name}
  port: {port}
"""
```

## Use cases in DevOps

| Use case | Tool |
|----------|------|
| Config files per environment | Jinja2 |
| Docker Compose generation | Jinja2 |
| Nginx/Apache configs | Jinja2 |
| Shell script generation | Jinja2 |
| Email/Slack message templates | Jinja2 |
| CI pipeline YAML generation | Jinja2 |
| SQL query templates | Jinja2 |
| Simple variable substitution | `string.Template` or f-strings |

## Best practices

- Keep templates in a dedicated `templates/` directory
- Use meaningful file extensions with `.j2` suffix (e.g., `nginx.conf.j2`)
- Validate generated output before writing (schema validation or dry-run)
- Use `trim_blocks` and `lstrip_blocks` to avoid extra whitespace
- Pass all variables explicitly (no magic globals)
- Use filters for formatting, not logic in templates
- Test template rendering in unit tests

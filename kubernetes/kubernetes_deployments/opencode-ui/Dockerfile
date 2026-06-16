FROM node:20-alpine AS opencode-install
RUN npm install -g opencode-ai

FROM python:3.12-alpine

RUN apk add --no-cache ca-certificates libstdc++ libgcc

COPY --from=opencode-install /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=opencode-install /usr/local/bin/opencode /usr/local/bin/opencode

WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ backend/
COPY ui/ ui/

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "1", "--timeout", "180", "backend.main:app"]

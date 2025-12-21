FROM python:3.11-slim

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

EXPOSE 8080

CMD ["sh", "-c", "echo 'Runner coordinator placeholder - implement as needed'"]

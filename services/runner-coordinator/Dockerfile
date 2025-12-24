FROM python:3.11-slim

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    docker.io \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

EXPOSE 8080

# Run the application
# Ensure the app has permissions to the socket if running as non-root
CMD ["python", "-m", "app.main"]

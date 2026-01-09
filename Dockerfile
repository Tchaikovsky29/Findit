# Use official Python runtime as base image
FROM python:3.11-slim

# Set working directory in container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY try.py .

# Expose port (Railway will assign the PORT env var)
EXPOSE 5000

# Health check (uses PORT env var if provided)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests, os; p=int(os.getenv('PORT', '5000')); requests.get(f'http://localhost:{p}/health', timeout=5)"

# Run the application with gunicorn, binding to the platform-provided PORT
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-5000} try:app"]

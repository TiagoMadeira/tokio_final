FROM python:3.12.3-slim

ARG APP_ENV
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g 10001 -m -s /bin/bash appuser

# 1. Set the working directory to the user's home folder root
WORKDIR /home/appuser

# 2. Copy requirements into the current folder (/home/appuser/)
COPY --chown=appuser:appuser requirements-${APP_ENV}.txt .

USER 10001

ENV PYTHONDONTWRITEBYTECODE=1

RUN pip install --no-cache-dir --upgrade pip==26.0 && \
    pip install --no-cache-dir -r requirements-${APP_ENV}.txt

# 3. Copy the folder itself, creating /home/appuser/app/
COPY --chown=appuser:appuser ./app ./app

# 4. Create the data subfolder inside the app folder for SQLite
RUN mkdir -p /home/appuser/app/data

# 5. Set PYTHONPATH to the parent directory
ENV PYTHONPATH=/home/appuser

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1


# 6. Run uvicorn using module notation from /home/appuser
CMD ["/usr/local/bin/python3", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
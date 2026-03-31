FROM python:latest
COPY requirements.txt requirements.txt
RUN python3 -m venv .venv
RUN . .venv/bin/activate
RUN pip install -r requirements.txt
COPY . .
CMD ["fastapi", "run", "app/main.py", "--host", "0.0.0.0" ]
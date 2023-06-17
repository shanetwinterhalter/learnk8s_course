FROM python:3.9-slim-bullseye

EXPOSE 8000
RUN mkdir -p /python
COPY index.html /python/index.html

CMD ["python3", "-m", "http.server", "-d", "/python/"]
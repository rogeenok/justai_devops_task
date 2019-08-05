# -- using 36 MB images with python --
FROM python:rc-alpine
COPY src ./home/devops-task/src

WORKDIR ./home/devops-task/src

# -- run python server (inner port 8080)
ENTRYPOINT ["python", "/home/devops-task/src/server.py"]
EXPOSE 8080
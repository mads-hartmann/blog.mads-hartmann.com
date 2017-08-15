FROM python:3.6.2-alpine3.6

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

COPY src .

ENV PYTHONPATH=/application/src:$PYTHONPATH

EXPOSE 80
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "server:app"]

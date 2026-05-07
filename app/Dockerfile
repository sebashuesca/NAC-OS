# Stage 1: Builder
FROM 297433793747.dkr.ecr.us-east-1.amazonaws.com/imov-python-base:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM 297433793747.dkr.ecr.us-east-1.amazonaws.com/imov-python-base:3.9-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 5000
CMD ["python", "app.py"]

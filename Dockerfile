FROM rocker/r-ver:4.3.2

WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.production.R requirements.R
COPY install_packages.R ./

# Install R packages from requirements.R
RUN Rscript install_packages.R

# Copy application source code
COPY networksecurity/ ./networksecurity/
COPY app.R server.R ./

# Copy trained model and artifacts (CRITICAL for predictions)
COPY final_model/ ./final_model/
COPY Artifacts/ ./Artifacts/
COPY local_runs/ ./local_runs/

# Create runtime directories
RUN mkdir -p prediction_output logs

# Verify critical files exist
RUN test -f final_model/model.rds || echo "WARNING: model.rds not found" && \
    test -f final_model/preprocessor.rds || echo "WARNING: preprocessor.rds not found"

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD Rscript -e "httr::GET('http://localhost:8000/health')" || exit 1

CMD ["Rscript", "server.R"]

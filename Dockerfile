FROM rocker/r-ver:4.3.2

WORKDIR /app

# System dependencies
RUN apt-get update -y && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libsodium-dev \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN Rscript -e "\
  install.packages(c( \
    'plumber', 'dotenv', 'mongolite', 'yaml', \
    'caret', 'randomForest', 'gbm', 'e1071', \
    'RANN', 'logger', 'C50', 'jsonlite', \
    'dplyr' \
  ), repos='https://cloud.r-project.org') \
"

COPY . /app

EXPOSE 8000

CMD ["Rscript", "app.R"]

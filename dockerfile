# Use lightweight Node image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json first to leverage caching
COPY package*.json ./

# Install Node dependencies
RUN npm install

# Copy the rest of the app
COPY . .

# Make scripts executable
RUN chmod +x tools/*/script.sh

# Install system dependencies: bash, curl, python3, pip, venv
RUN apk add --no-cache bash curl python3 py3-pip

# Create a virtual environment for yt-dlp
RUN python3 -m venv /opt/yt-dlp-venv

# Activate venv and install yt-dlp
ENV PATH="/opt/yt-dlp-venv/bin:$PATH"
RUN pip install --no-cache-dir yt-dlp

# Install static ffmpeg
RUN curl -L https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz \
    -o /tmp/ffmpeg.tar.xz \
    && mkdir -p /tmp/ffmpeg-extract \
    && tar -xJf /tmp/ffmpeg.tar.xz -C /tmp/ffmpeg-extract \
    && cp /tmp/ffmpeg-extract/ffmpeg-*/ffmpeg /usr/local/bin/ \
    && cp /tmp/ffmpeg-extract/ffmpeg-*/ffprobe /usr/local/bin/ \
    && chmod +x /usr/local/bin/ffmpeg /usr/local/bin/ffprobe \
    && rm -rf /tmp/ffmpeg*

# Expose the port your server uses
EXPOSE 1234

# Start the server
CMD ["node", "server.js"]

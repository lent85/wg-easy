# --------------> The production image
FROM node:20.11.1-alpine3.19

# Set working directory
WORKDIR /app

# Set node environment to production
ENV NODE_ENV=production

# Add package files first (better caching)
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application files
COPY . .

# Add custom packages if needed
RUN apk add --no-cache \
    tini \
    && rm -rf /var/cache/apk/*

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Create and use non-root user for security
RUN addgroup -g 1001 nodejs && \
    adduser -S -u 1001 -G nodejs nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

# Expose port (customize as needed)
EXPOSE 51820/udp
EXPOSE 51821/tcp

# Start the application
CMD ["node", "server.js"]

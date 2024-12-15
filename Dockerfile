# Build stage for node modules
FROM node:20-alpine AS build_node_modules

# Copy package files first for better caching
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

# Copy the entire app directory
COPY . .

# Production stage
FROM node:20-alpine

# Copy built application from build stage
COPY --from=build_node_modules /app /app

# Move node_modules up one level for development efficiency
# This helps with faster reloading and architecture compatibility
RUN mv /app/node_modules /node_modules

# Install required system packages
RUN apk add -U --no-cache \
    iptables \
    wireguard-tools \
    tini

# Create and use non-root user for better security
RUN addgroup -g 1001 nodejs && \
    adduser -S -u 1001 -G nodejs nodejs && \
    chown -R nodejs:nodejs /app /node_modules

# Expose WireGuard and Web UI ports
EXPOSE 51820/udp
EXPOSE 51821/tcp

# Set debug environment for logging
ENV DEBUG=Server,WireGuard
ENV NODE_ENV=production

# Switch to non-root user
USER nodejs

# Set working directory
WORKDIR /app

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["node", "server.js"]

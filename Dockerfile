# --------------> The build image
FROM node:20.11.1-alpine3.19 AS builder

# Set working directory
WORKDIR /app

# Add package files first (better caching)
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# --------------> The production image
FROM node:20.11.1-alpine3.19

# Set working directory
WORKDIR /app

# Set node environment to production
ENV NODE_ENV=production

# Install production dependencies
# This is done first to cache the layer
COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist

# Copy other necessary files (customize as needed)
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json .
COPY --from=builder /app/package-lock.json .

# Add custom packages if needed (example)
RUN apk add --no-cache \
    tini \
    # add other packages here if needed
    && rm -rf /var/cache/apk/*

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Create and use non-root user for security
RUN addgroup -g 1001 nodejs && \
    adduser -S -u 1001 -G nodejs nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

# Expose port (customize as needed)
EXPOSE 3000

# Healthcheck (customize as needed)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "dist/server.js"]

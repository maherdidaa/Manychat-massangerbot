# Multi-stage build for Next.js frontend

# ---- Dependencies Stage ----
FROM node:20-alpine AS deps
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./
COPY next.config.* ./

# Install dependencies
RUN npm ci

# ---- Build Stage ----
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
COPY tsconfig*.json ./
COPY next.config.* ./
COPY tailwind.config.* ./
COPY postcss.config.* ./
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build application
RUN npm run build

# ---- Development Stage ----
FROM node:20-alpine AS development
WORKDIR /app

RUN apk add --no-cache curl

# Copy built app for dev mode
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/tsconfig*.json ./
COPY --from=builder /app/next.config.* ./
COPY --from=builder /app/tailwind.config.* ./
COPY --from=builder /app/postcss.config.* ./
COPY --from=builder /app/public ./public

EXPOSE 3000

ENV NODE_ENV=development

CMD ["npm", "run", "dev"]

# ---- Production Stage ----
FROM node:20-alpine AS production
WORKDIR /app

RUN apk add --no-cache curl

# Copy production build
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/next.config.* ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

ENV NODE_ENV=production

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

CMD ["npm", "start"]

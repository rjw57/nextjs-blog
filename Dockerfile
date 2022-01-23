# Builder image.
FROM node:16-alpine AS builder
# Check
# https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine
# to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
ADD ./ ./
RUN NEXT_TELEMETRY_DISABLED=1 npm run build

# Production image, copy all the files, install non-dev deps and run next
FROM node:16-alpine AS runner
WORKDIR /app

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

COPY --from=builder /app/package.json /app/package-lock.json ./
ENV NODE_ENV production
RUN npm install --production
COPY --from=builder /app/public/ ./public/
COPY --from=builder /app/.next/ ./.next/

USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["npx", "next", "start", "-p", "$PORT"]

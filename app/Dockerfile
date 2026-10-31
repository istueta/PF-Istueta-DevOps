# Etapa 1: dependencias de producción.
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

# Etapa 2: imagen final mínima, sin herramientas de compilación.
FROM node:22-alpine AS runtime
ENV NODE_ENV=production PORT=3000
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=deps --chown=app:app /app/node_modules ./node_modules
COPY --chown=app:app package*.json ./
COPY --chown=app:app src ./src
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]

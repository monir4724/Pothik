FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY prisma ./src/database/prisma/

RUN npm ci

COPY . .

RUN npx prisma generate --schema=src/database/prisma/schema.prisma
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/src/database/prisma ./src/database/prisma

EXPOSE 3000

CMD ["node", "dist/src/main"]

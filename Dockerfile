FROM node:18-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

RUN yarn config set registry 'https://registry.npmmirror.com/'
RUN yarn install

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN chmod +x ./node_modules/.bin/next

RUN echo '{ \
  "extends": "./.eslintrc.json", \
  "rules": { \
    "@typescript-eslint/no-unused-vars": "off", \
    "@typescript-eslint/ban-ts-comment": "off" \
  } \
}' > .eslintrc.json.tmp && mv .eslintrc.json.tmp .eslintrc.json
RUN yarn build

FROM base AS runner
WORKDIR /app

# COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/server ./.next/server

EXPOSE 3000
ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
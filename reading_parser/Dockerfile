FROM node:20-slim

# Install pnpm using npm
RUN npm install -g pnpm

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

EXPOSE 3001
CMD ["pnpm", "start"]
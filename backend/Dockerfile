# ===== Build stage =====
FROM node:22-trixie-slim AS builder

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install --omit=dev

COPY . .


# ===== Runtime stage =====
FROM node:22-trixie-slim

WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/index.js ./

CMD ["node", "index.js"]

# ===== Build stage =====
FROM node:22-trixie-slim AS builder

WORKDIR /usr/src/app

RUN npm install -g npm@12.0.2

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install --omit=dev

COPY . .


# ===== Runtime stage =====
FROM gcr.io/distroless/nodejs22-debian13:nonroot

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/index.js ./

EXPOSE 3500

CMD ["index.js"]

# ---------- Build Stage ----------
FROM node:16-alpine AS builder

WORKDIR /app

ARG REACT_APP_BACKEND_URL
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# ---------- Production Stage ----------
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve
COPY ./build/web ./build/web

EXPOSE 8080

CMD ["serve", "-s", "build/web", "-l", "8080"]
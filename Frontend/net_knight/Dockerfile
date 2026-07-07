FROM node:18-alpine
WORKDIR /app
RUN npm install -g serve
COPY ./build/web ./build/web

# فتح بورت 8080 اللي زميلك حدده
EXPOSE 8080

# تشغيل السيرفر على بورت 8080 جوه الكونتينر
CMD ["serve", "-s", "build/web", "-l", "8080"]
# استخدام سيرفر Nginx لعرض الملفات
FROM nginx:alpine

# نسخ ملفات الفرونت بعد ما يتعملها Build
COPY ./build/web /usr/share/nginx/html

# فتح بورت 80
EXPOSE 80

# تشغيل السيرفر
CMD ["nginx", "-g", "daemon off;"]

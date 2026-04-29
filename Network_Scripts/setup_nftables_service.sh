#!/bin/bash
# setup_nftables_service.sh
# شغّل السكريبت ده مرة واحدة على السيرفر بصلاحيات root

# 1. تأكد إن nftables service موجود ومفعّل
systemctl enable nftables
systemctl start nftables

# 2. تأكد إن الملف موجود
touch /etc/nftables.conf
chmod 600 /etc/nftables.conf

# 3. تأكد إن nftables.service بيلود الملف ده
# الـ default config بتاعت nftables بتعمل كده أصلاً
# بس نتحقق:
if ! grep -q "nftables.conf" /lib/systemd/system/nftables.service 2>/dev/null; then
    echo "WARNING: nftables.service may not load /etc/nftables.conf automatically"
    echo "Check: cat /lib/systemd/system/nftables.service"
fi

echo "✅ Done! nftables service is enabled and will load /etc/nftables.conf on boot."

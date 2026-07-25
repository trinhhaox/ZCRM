import 'dotenv/config';
import { prisma } from '../src/shared/database/prisma-client.js';
import bcrypt from 'bcryptjs';

async function main() {
  console.log('🚀 Đang khởi tạo tài khoản Owner và Dữ liệu Demo ZCRM...');

  // 1. Check if Owner already exists
  let owner = await prisma.user.findFirst({
    where: { role: 'owner' },
  });

  let org;
  if (!owner) {
    console.log('→ Đang tạo Organization "Thiên Phúc CRM"...');
    org = await prisma.organization.create({
      data: {
        name: 'Thiên Phúc CRM',
      },
    });

    const passwordHash = await bcrypt.hash('Demo@1234', 12);

    console.log('→ Đang tạo tài khoản Owner (admin@thienphuc.com / Demo@1234)...');
    owner = await prisma.user.create({
      data: {
        orgId: org.id,
        fullName: 'Nguyễn Văn Chủ',
        email: 'admin@thienphuc.com',
        phone: '0900000000',
        passwordHash,
        role: 'owner',
        isActive: true,
        passwordChangedAt: new Date(),
      },
    });
    console.log('✅ Đã tạo thành công tài khoản Owner!');
  } else {
    console.log(`ℹ️ Tài khoản Owner đã tồn tại: ${owner.email || owner.phone}`);
    org = await prisma.organization.findUnique({ where: { id: owner.orgId } });
  }

  await prisma.user.updateMany({
    data: {
      passwordChangedAt: new Date(),
    },
  });

  console.log('✅ Hoàn tất khởi tạo Owner!');
}

main()
  .catch((e) => {
    console.error('❌ Lỗi:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

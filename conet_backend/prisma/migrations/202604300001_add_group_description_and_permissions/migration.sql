ALTER TABLE "public"."conversations"
ADD COLUMN "description" TEXT,
ADD COLUMN "only_admin_add_members" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "only_admin_remove_members" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "only_admin_edit_group" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "only_admin_send_messages" BOOLEAN NOT NULL DEFAULT true;

-- An entry can say which packaging template its release was made from.
--
-- `titles.software_model_id` has existed throughout and `v_items` never carried
-- it, so a client could see that an Amiga 2000 was made from the Amiga 2000
-- model and could not see that Blake Stone was made from "PC DOS, big box,
-- floppy". Half the feature was visible, and the half nobody could see was the
-- half most entries use.
--
-- The view is replaced rather than altered - it is derived, so there is nothing
-- to preserve, and CREATE OR REPLACE VIEW is the whole change.
--
-- Copied from schema.sql rather than retyped. Writing it out by hand produced
-- `lib.color` for a column actually called `lib.accent_color` - a view that
-- creates cleanly in the file and fails on the instance that runs it.

CREATE OR REPLACE VIEW v_items AS
SELECT
  i.*,
  lib.name AS library_name, lib.slug AS library_slug, lib.accent_color AS library_color,
  lib.kind AS library_kind, lib.owner_id AS library_owner_id,
  s.slug AS domain, c.path AS category_path, c.depth AS category_depth,
  p.name  AS platform_name,  p.slug AS platform_slug, p.accent_color AS platform_color,
  pv.name AS platform_vendor,
  c.name  AS category_name,  c.slug AS category_slug, c.role AS category_role,
  d.name  AS developer_name, d.slug AS developer_slug, d.website AS developer_website, d.logo_filename AS developer_logo,
  pb.name AS publisher_name, pb.slug AS publisher_slug,
  t.name  AS title_name,     t.slug AS title_slug, t.work_key AS title_work_key,
  t.synopsis AS title_synopsis,
  hm.name AS model_name,     hm.slug AS model_slug,
  -- The packaging template the release was made from.
  --
  -- On the title rather than the item, because "big box with two floppies and a
  -- manual" is a fact about the release and not about one copy of it. Carried
  -- here so an entry can say where its shape came from - the hardware side has
  -- always shown its model and the software side never did, which made the
  -- templates look like something only machines used.
  swm.id  AS software_model_id, swm.name AS software_model_name, swm.slug AS software_model_slug,
  img.filename AS cover_filename,
  loc.name AS location_name, loc.path AS location_path
FROM items i
JOIN libraries lib ON lib.id = i.library_id
JOIN platforms  p  ON p.id  = i.platform_id
LEFT JOIN companies pv ON pv.id = p.vendor_id
JOIN categories c  ON c.id  = i.category_id
JOIN sections   s  ON s.id  = c.section_id
LEFT JOIN companies       d   ON d.id   = i.developer_id
LEFT JOIN companies       pb  ON pb.id  = i.publisher_id
LEFT JOIN titles          t   ON t.id   = i.title_id
-- After `titles`, because it hangs off it: a join referring to a table declared
-- below it parses and then fails at runtime with "unknown column t.…".
LEFT JOIN software_models swm ON swm.id = t.software_model_id
LEFT JOIN hardware_models hm  ON hm.id  = i.model_id
LEFT JOIN item_images     img ON img.id = i.cover_image_id
LEFT JOIN locations       loc ON loc.id = i.location_id
WHERE i.deleted_at IS NULL;

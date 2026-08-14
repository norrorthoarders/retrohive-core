-- The repository is `retrohive-core` now, and one setting holds its address.
--
-- `structure_source` is written into the database at install time from the
-- default in settings_schema.php. Changing that default fixes new installs and
-- does nothing for existing ones, which would go on fetching from a URL that no
-- longer resolves - and the failure is a sync that quietly finds nothing rather
-- than an error anybody would connect to a rename.
--
-- Only the address this project publishes. A row somebody has pointed at their
-- own fork is theirs, and rewriting it because it happens to contain a word we
-- renamed would be taking a decision that is not ours.

UPDATE settings
   SET value = 'https://raw.githubusercontent.com/norrorthoarders/retrohive-core/main/structure'
 WHERE name = 'structure_source'
   AND value = 'https://raw.githubusercontent.com/norrorthoarders/retrohive/main/structure';

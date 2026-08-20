-- What a title has been worth, as observed, per condition band.
--
-- Its own table rather than columns on `items`, because a price is a fact about
-- the market at a moment and not a property of the object. `items` already
-- separates what a thing is from what a copy of it is; prices are a third thing,
-- and folding them into the second is how a table ends up with forty columns.
--
-- Keyed on the title rather than on an item: two copies of the same game are two
-- entries and one market. An entry reads the band that matches its own
-- `completeness`, which is the join that makes six numbers useful rather than
-- five wasted.
--
-- History is kept. A row per observation, not one updated in place: "what has
-- this been worth over time" is the question a collector actually asks, and an
-- overwritten number cannot answer it.
CREATE TABLE IF NOT EXISTS price_observations (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,

  -- Which market reported it. A slug rather than a foreign key to
  -- metadata_providers: an observation outlives the provider row that fetched
  -- it, and deleting a source should not delete the history it gathered.
  source        VARCHAR(40)  NOT NULL,

  -- What it is about. The platform is part of the identity - Maniac Mansion on
  -- Amiga and on NES are different markets - and the source's own id is kept so
  -- a later fetch can find the same page without guessing at its title again.
  platform_id   INT UNSIGNED DEFAULT NULL,
  title         VARCHAR(300) NOT NULL,
  external_id   VARCHAR(200) DEFAULT NULL,
  url           VARCHAR(500) DEFAULT NULL,

  -- Which condition the price is for.
  --
  -- The same vocabulary as items.completeness, plus the two bands that exist in
  -- a market and not on a shelf: `new` is sealed, and `graded` is a third party
  -- saying so on a slab. An entry matches on the first four and ignores the
  -- rest, which is why they are here rather than dropped - somebody pricing a
  -- sealed copy should see what sealed copies fetch.
  band          ENUM('loose','cib','boxed_no_manual','manual_only','new','graded')
                NOT NULL,

  amount        DECIMAL(10,2) NOT NULL,
  currency      CHAR(3)       NOT NULL DEFAULT 'USD',

  -- How much this number is worth believing.
  --
  -- A price with no volume beside it is a guess wearing a decimal point. Both
  -- are kept as the source states them: a count of sales seen, and whatever the
  -- source says about frequency in its own words - "1 sale per year", "rare" -
  -- because normalising that into a number would be inventing precision the
  -- source did not offer.
  sales_count   INT UNSIGNED DEFAULT NULL,
  volume_note   VARCHAR(60)  DEFAULT NULL,

  observed_on   DATE         NOT NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  -- One observation per source, title, band and day. A second fetch on the same
  -- day is the same fact, and a page refreshed twice should not read as a
  -- market that moved.
  UNIQUE KEY uq_observation (source, title, platform_id, band, observed_on),
  KEY idx_lookup (title, platform_id, band, observed_on),
  CONSTRAINT fk_price_platform FOREIGN KEY (platform_id)
    REFERENCES platforms (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

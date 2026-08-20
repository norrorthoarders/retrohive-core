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
  -- The market's own six, taken from the ids on their page - `used_price`,
  -- `complete_price`, `new_price`, `graded_price`, `box_only_price`,
  -- `manual_only_price` - rather than from this catalogue's vocabulary.
  --
  -- The two do not line up as neatly as they first appear, and the difference
  -- matters:
  --
  --   * `box_only` is the box *alone*, with no game in it. This is not
  --     `boxed_no_manual`, which is a box with the game and no manual. An
  --     earlier draft of this table had `boxed_no_manual` as a band, which would
  --     have priced a playable boxed copy at what an empty box fetches.
  --   * `boxed_no_manual` therefore has no band at all. The market does not
  --     quote it, and it sits between `loose` and `cib` rather than at either.
  --   * `new` and `graded` are market states a shelf cannot be in: an entry
  --     cannot be sealed and also be catalogued as a copy somebody owns.
  --
  -- All six are stored. Only three match a shelf state; the rest are here
  -- because somebody pricing a spare box should see what spare boxes fetch.
  band          ENUM('loose','cib','new','graded','box_only','manual_only')
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

  -- When the price was true, not when it was fetched.
  --
  -- Which matters more than it looks: their comparison endpoint returns a dated
  -- series per condition, so a first fetch can backfill months of history as
  -- many rows with different dates rather than one row saying "today". The
  -- unique key is on this rather than on the fetch, so importing the same series
  -- twice is idempotent.
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

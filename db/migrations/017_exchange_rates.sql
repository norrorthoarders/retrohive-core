-- What a US dollar is worth in other money, as somebody observed it.
--
-- The prices this catalogue records come from a market that quotes in dollars,
-- and a shelf in Sweden is not priced in dollars. Converting at display time
-- rather than on the way in is deliberate: an observation is what a source said,
-- and rewriting it into local money would lose the number that was actually
-- published and bake in whatever rate happened to apply that afternoon.
--
-- Dated, and kept, for the same reason price_observations are rows: "what was it
-- worth in 2019" is a question about the rate as well as the price.
CREATE TABLE IF NOT EXISTS exchange_rates (
  -- Always from USD. One base keeps the arithmetic to one multiplication and
  -- makes a missing pair obvious rather than something to derive through a
  -- third currency and hope about.
  base        CHAR(3)      NOT NULL DEFAULT 'USD',
  quote       CHAR(3)      NOT NULL,
  -- How many of `quote` one `base` buys. Ten places because some currencies run
  -- to thousands per dollar and rounding at four would be visible.
  rate        DECIMAL(20,10) NOT NULL,
  observed_on DATE         NOT NULL,
  -- Who said so, so a rate somebody typed can be told from one that was fetched.
  source      VARCHAR(60)  NOT NULL DEFAULT 'manual',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (base, quote, observed_on),
  KEY idx_rate_recent (quote, observed_on)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

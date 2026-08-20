# Prices as a metadata source

PriceCharting tracks what copies actually sold for, per platform, including the
home computers this catalogue is mostly about — there is an Amiga section, and
`/game/amiga/maniac-mansion` is a real page with real Amiga sales on it.

That makes it the first source anybody has asked for that answers a question none
of the others do. It is also the first that does not fit the shape the others
have, and that is worth writing down before any code is.

## What a page carries

From a page, per title:

| What | Example |
|---|---|
| Loose price | $99.00 |
| Complete price | $272.40 |
| New price | $545.00 |
| Graded price | $599.50 |
| Box only price | $109.30 |
| Manual only price | $68.32 |
| Sales volume, per band | "1 sale per year", "3 sales per year", "rare" |
| Sold listings, per band | Loose (7), CIB (17), New (0), Graded (0), Box (0), Manual (0) |

The bands are the interesting part. **They line up almost exactly with the
`completeness` enum this catalogue already records** — `cib`, `boxed_no_manual`,
`loose`, `manual_only` — which means a price can be matched to the copy on the
shelf rather than to the title in the abstract. A loose disc and a complete boxed
copy of Maniac Mansion are worth $99 and $272; a catalogue that stores one number
for "Maniac Mansion" is answering a question nobody asked.

Volume is worth as much as price to somebody deciding whether to sell: "1 sale
per year" and "rare" say more about whether a number means anything than the
number does. A price with no volume beside it is a guess wearing a decimal point.

## Why it does not fit the existing agent shape

Every current source answers **"which release is this?"** - it returns candidates
with a title, a year, a developer, and the client picks one and takes fields off
it. TMDB knows what a film is. TheGamesDB knows what a game is.

PriceCharting answers **"what is this copy worth?"**, which is a different
question with three consequences:

1. **It is not one value.** Six bands, and which one applies depends on the
   entry's own `completeness` - a fact the engine has and no metadata agent has
   ever needed to read.
2. **It goes stale.** A release year is true forever; a price is true this month.
   `items.valued_on` exists for exactly this and nothing has ever written it.
3. **It is per copy, not per title.** Two copies of the same game in different
   condition have different values, and the schema already models them as two
   entries.

So this is not "another agent" - it is an agent plus a decision about where six
numbers go when the schema has one column.

## The options, and what each costs

**a. Take the band that matches, write `current_value` and `valued_on`.**
Smallest change, uses columns that exist, and throws away five numbers. Somebody
who later completes a boxed copy gets no help until they look it up again.

**b. Store all six on the item.** Six new columns, or a JSON blob beside
`specs`. Keeps everything, and puts pricing data on a table that is otherwise
about the object rather than about the market.

**c. A `price_observations` table.** Source, title, band, amount, volume, and
when it was seen. Correct - it is a fact about the market at a moment, not a
property of the object - and it is the one that supports "what has this been
worth over time", which is the question a collector actually asks.

**c is right and b is the trap.** The schema already separates what a thing is
from what a copy of it is; prices are a third thing, and folding them into the
second is how `items` ends up with forty columns.

## What is not decided

Whether to use their API or read the pages. They sell an API with a token; the
pages are public. Reading pages that a site sells access to is a licensing
question rather than a technical one, and it is not mine to answer - the same way
MusicBrainz's contact requirement was theirs to state and ours to obey.

`needs_key` and a `credentials` entry for the token cover the API case with the
machinery that already exists. If the answer is the API, this agent needs no new
concepts at all beyond the ones above.

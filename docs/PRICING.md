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

## What the markup calls things

From the community scraper, on the `/console/{name}` list page:

| Column | Class |
|---|---|
| Title | `td.title` |
| Loose | `td.used_price` |
| Complete | `td.cib_price` |
| New | `td.new_price` |

The table itself is `#games_table`, loaded after the page is - which is the
detail that matters most, and is covered below.

The per-game page - `/game/amiga/maniac-mansion` - carries the other three
prices, the volume line under each, and the sold-listing counts per band. Nobody
has mapped those class names here, and guessing at them from a screenshot would
be inventing a parser against markup I have not seen.

## Reading the pages instead of paying for the API

Their API is sold with a token. The pages are public, and scraping them is what
the community does - `markfoster314/Pricecharting-Scraper` is a working example,
and there are several others.

**What that repository actually shows is not encouraging, and it is worth being
precise about why.**

It drives a real Google Chrome through Selenium. Not for convenience: the reason
a scraper needs a headless browser rather than an HTTP request is that plain
requests do not come back with the content. Either the table is rendered by
JavaScript, or the site refuses clients that do not look like browsers - and both
are the site saying no in the way sites say it.

This engine fetches with cURL. Every existing agent is an HTTP request and a
parse; adding one that needs a browser installed on the server is not "another
agent", it is a second kind of thing to deploy, keep patched and watch for
breakage on every page change.

It also reads a **different page** from the one that started this. It scrapes
`/console/{name}`, the list of every title on a platform, and takes three columns
from it - `used_price`, `cib_price`, `new_price`. The per-game page has six
prices, the sales volume and the listing counts, and none of that is in the list
table. So the example gets half of what makes this worth having.

## A second scraper, which says something different

`phantomeralphay/pricecharting-product-details-scraper` reads the **per-game**
page rather than the console list, and its documented output changes three of the
conclusions above.

**It mentions no browser.** Its stated requirements are retries and proxy
support - the vocabulary of an HTTP client meeting rate limits, not of a page that
cannot be read without JavaScript. If that is accurate, the first scraper's
Chrome was one author's choice rather than a hard requirement, and a cURL fetch
may be enough after all.

**There is a chart endpoint.** Its sample output carries a
`chart_url` of the form:

    https://www.pricecharting.com/compare?uids=R3560883&conditions=1

and `chart_data` as dated points per condition:

    "used": [["2024-10-01 06:00:00+00:00", 6700], ...]

Prices in **cents**, as integers. A price history in a structured response is a
much better thing to read than a rendered table, and `price_observations` was
designed for exactly this shape - one row per source, band and date.

**The completed sales are itemised.** `price_comparison` carries the individual
eBay sales behind a price, each with a date, a title, an amount and a platform -
which is the listing count in the screenshot, per band, with the sales themselves
attached rather than counted.

It also confirms the per-game page carries a `PriceCharting ID`, which is what
`price_observations.external_id` is for: a later fetch finds the same page without
guessing at its title again.

**None of this is verified.** It is a README, from a repository that is largely an
advertisement for a scraping agency - the technical claims may be accurate, aspirational,
or describing a run against a page that has since changed. The site is not
reachable from where this is written, so nothing here has been tested against it.

What it does establish is that the per-game page is worth reading and that a
plain HTTP path may exist. That is worth checking from a machine that can reach
them, and is a different answer from "it needs Chrome".

## Where that leaves it

Three honest options:

**a. Pay for the API.** A token, an HTTP request, a JSON parse - which is what
every other agent here already is. `needs_key` and the credential entry are
already in place for it, and it is the only one where the terms are not a
question.

**b. Scrape over plain HTTP.** Fetch the per-game page and `/compare`, parse what
comes back. Whether this works is one experiment from a machine that can reach
them: fetch the page with cURL and a proper User-Agent and see whether the prices
are in the response or only in the JavaScript. **That is the thing to try next**,
and it is ten minutes rather than a project.

**c. Scrape with a browser.** Chrome on the server. Only if (b) comes back empty,
and it is a second kind of thing to deploy and keep working.

Their terms sell the thing (b) and (c) take, and that is a decision for whoever
runs the instance rather than for this file.

## The experiment, run

    curl -sS -A 'RetroHive/x (+https://retrohive.noh.nu)' \
         https://www.pricecharting.com/game/amiga/maniac-mansion | grep -c 'used_price'
    1

**The prices are in the HTML.** A plain cURL fetch with a proper User-Agent comes
back with the page, which settles the question the first scraper raised: its
headless Chrome was that author's choice rather than something the site forces.
This can be an ordinary agent, the same shape as every other one here.

One occurrence rather than many is what a *per-game* page should give - the
console list has a row per title and so a hundred of them. It reads like an id or
a single cell rather than a table column, which is the next thing to confirm.

## The markup, read from the page

    <table id="price_data" class="info_box">
      <td id="used_price">        <span class="price js-price"> <span class="js-price">$0.00
      <td id="complete_price">    <span class="price js-price"> <span class="js-price">$0.86
      <td id="new_price">         <span class="price js-price"> <span class="js-price">$2.00
      <td id="graded_price">      <span class="price js-price"> <span class="js-price">$2.20
      <td id="box_only_price">    <span class="price js-price"> <span class="js-price">$34.92
      <td id="manual_only_price"> <span class="price js-price"> <span class="js-price">$21.82

Six cells with stable ids, in a table with an id. Better than class names on a
list page: an id is a promise in a way a layout class is not.

### The trap in it

**Those are not the prices.** The screenshot of the same page reads $99.00,
$272.40, $545.00, $599.50, $109.30, $68.32 - with a small grey figure beside each
one: $0.00, -$0.86, -$2.00, -$2.20, -$34.92, -$21.82.

The numbers above are the second set. Each cell holds two spans, and the text
visible to a crude grep is the inner one - the **change**, not the price. A
parser that took the first `js-price` it found would have recorded a game worth
$99 as worth nothing, and been consistent about it: six plausible numbers, all
wrong, on every title.

The lesson is not about this site. It is that a price is exactly the kind of
value that looks right at a glance, and $0.00 against a loose Amiga game is the
only one of the six that would have looked odd enough to notice.

### The volume and the counts

Both are keyed on the same tab name, which is better than a position:

    <td class="js-show-tab" data-show-tab="completed-auctions-used">
      <span ...>volume:&nbsp;</span><a href="#">1 sale per year</a>
    </td>

    <option value="completed-auctions-used">Loose (7)</option>

Their names, not ours: `used` for loose, and `box-only` with a hyphen where the
price cell has an underscore.

The counts come from the **select** rather than the tabs, because the select
carries every band in one list while the tabs hide some at narrow widths - and a
band whose tab is hidden still has a count.

Keying matters here for a second reason: the page repeats the last three price
cells and their volumes in a second block for narrow screens. Anything walking
the row in order reads three of the six twice.

### What the whole page yields

    loose        $99.00    1 sale per year    7 sales
    cib          $272.40   3 sales per year   17 sales
    new          $545.00   rare               0 sales
    graded       $599.50   rare               0 sales
    box_only     $109.30   rare               0 sales
    manual_only  $68.32    rare               0 sales

    PriceCharting ID: 67001

A zero count beside a price is the most useful thing there. It says the number
came from something other than sales of this exact thing, which is the difference
between a price nobody should trust and one nobody has tested.

### The fixture

`tests/fixtures/pricecharting-maniac-mansion.html` is a trimmed copy of the page
as served, kept verbatim. Written from memory it would reproduce whatever the
writer expected - and the expectation here was wrong twice, about which number in
a cell is the price and about what `box_only` means.

**It does not prove everything.** On the page as served the price comes first, so
a parser with neither the sign rule nor the zero rule reads it correctly by luck.
Those rules are tested separately, against orderings the fixture does not
contain. Two checks that overlap is better than one covering less than its name
claims.

## Superseded: what was needed before the markup arrived

The markup around those prices. Guessing at it from a screenshot is how a parser
gets written against markup nobody has seen, and the class names on the list page
(`td.used_price`, `td.cib_price`) may or may not be what the per-game page uses.

From the server:

    curl -sS -A 'RetroHive/x (+https://retrohive.noh.nu)' \
         https://www.pricecharting.com/game/amiga/maniac-mansion \
      | grep -o -E '<[a-z]+[^>]*(used_price|cib_price|new_price|price)[^>]*>[^<]*' \
      | head -40

and, for the volume line and the sold-listing counts:

    curl -sS -A '...' https://www.pricecharting.com/game/amiga/maniac-mansion \
      | grep -o -E '(sale per year|sales per year|rare|Sold Listings[^<]*)' | head -20

The second question is whether the comparison endpoint answers plainly:

    curl -sS -A '...' 'https://www.pricecharting.com/compare?uids=R...&conditions=1' | head -c 400

with the id read out of the page. If that returns dated points, the first fetch
backfills history rather than starting it.

## The original experiment, for reference

From a machine that can reach them:

```
curl -sS -A 'RetroHive/x (+https://your-instance)' \
     https://www.pricecharting.com/game/amiga/maniac-mansion | grep -c 'used_price'
```

A non-zero count means the prices are in the HTML and a cURL agent is enough. A
zero means they are rendered afterwards, and (b) is out.

Then the series endpoint, which is the more valuable half:

```
curl -sS -A '...' 'https://www.pricecharting.com/compare?uids=R3560883&conditions=1'
```

If that returns dated points rather than a page, the history in
`price_observations` can be backfilled on the first fetch instead of accumulating
one row a month from now on.

A 403 on either is the site declining, which is an answer too.

I have not read their terms of service and cannot from here; the site is not
reachable from this environment. What is clear from the scraper is that the site
is *behaving* like one that does not want to be read by scripts, and that is worth
weighing before building around it.

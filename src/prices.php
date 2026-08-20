<?php

declare(strict_types=1);

/**
 * What a copy is worth, as observed.
 *
 * Separate from metadata.php because it answers a different question. Every
 * source there says which release something is; this says what a copy of it
 * fetches, which is a fact about the market at a moment rather than about the
 * object - see docs/PRICING.md.
 */

/**
 * Which price band applies to a copy in this state.
 *
 * The bands a market quotes and the states a shelf records are nearly the same
 * vocabulary, which is the whole reason this is worth joining rather than
 * storing one number per title: a loose disc and a complete boxed copy of the
 * same game fetch very different money.
 *
 * `digital` and `unknown` have no band. A download has no second-hand market to
 * quote, and guessing at one for an entry that has not said what it is would put
 * a number on the page that nobody chose.
 */
function price_band_for_completeness(?string $completeness): ?string
{
    return match ($completeness) {
        'cib'             => 'cib',
        'loose'           => 'loose',
        'manual_only'     => 'manual_only',
        // `boxed_no_manual` deliberately has none.
        //
        // The market quotes `box_only` - a box with nothing in it - and this is
        // a box with the game and no manual. They are not the same thing and the
        // difference is most of the value: matching them would price a playable
        // boxed copy at what an empty box fetches.
        //
        // Its real price sits between `loose` and `cib`, and neither is it. A
        // page that says nothing is better than one that says the wrong number
        // confidently.
        'boxed_no_manual' => null,
        default           => null,
    };
}

/**
 * Every band a market can quote.
 *
 * The market's own six, in the order their page lists them. Three match a state
 * a shelf can be in - `loose`, `cib`, `manual_only` - and three do not:
 *
 *   * `new` is sealed, and `graded` is a third party saying so on a slab.
 *     An entry cannot be either and also be a copy somebody owns.
 *   * `box_only` is an empty box, which is a spare part rather than a copy.
 *
 * All six are stored anyway. Somebody pricing a spare box should see what spare
 * boxes fetch, and a band nobody matches costs a row.
 */
function price_bands(): array
{
    return ['loose', 'cib', 'new', 'graded', 'box_only', 'manual_only'];
}

/**
 * Their id on the page against our band.
 *
 * Read from the markup rather than guessed: the cells are `used_price`,
 * `complete_price`, `new_price`, `graded_price`, `box_only_price` and
 * `manual_only_price`, in a table with the id `price_data`.
 *
 * `used` is loose and `complete` is cib, which is the one pair where their word
 * and ours differ for the same thing.
 */
function pricecharting_band_ids(): array
{
    return [
        'used_price'        => 'loose',
        'complete_price'    => 'cib',
        'new_price'         => 'new',
        'graded_price'      => 'graded',
        'box_only_price'    => 'box_only',
        'manual_only_price' => 'manual_only',
    ];
}

/**
 * The six prices out of a PriceCharting product page.
 *
 * Their cells carry ids - `used_price`, `complete_price` and the rest - which is
 * a firmer thing to parse against than a layout class. The table is
 * `#price_data`.
 *
 * Each cell holds two figures: the price, and the change since last time. **The
 * change is the one a naive parser finds**, because it is in the inner span and
 * the price is in the outer - so taking the first number in the cell records a
 * game worth $99.00 as worth $0.00, six plausible wrong numbers per title.
 *
 * Two rules tell them apart without depending on which span nests inside which,
 * which is markup that may well change:
 *
 *   * A leading minus disqualifies. A change can be negative and a price never
 *     is, which handles five of the six on a typical page.
 *   * Zero disqualifies. The sixth case is a change of exactly nothing - "$0.00"
 *     with no sign - and it is also what their page writes for a band nobody has
 *     sold in. Neither is a price.
 *
 * Tested against both nesting orders and against a change that comes first
 * unsigned, which is the one the sign rule alone would miss.
 *
 * @return list<array{band: string, amount: float, currency: string}>
 */
function pricecharting_prices_from_html(string $html): array
{
    $out = [];
    foreach (pricecharting_band_ids() as $id => $band) {
        // The cell, from its id to the end of that cell. Anchored on the id
        // rather than on position, so a column moving does not silently read the
        // one beside it.
        if (!preg_match('/id="' . preg_quote($id, '/') . '"[^>]*>(.*?)<\/td>/s', $html, $m)) {
            continue;
        }
        $cell = $m[1];

        // Every money-shaped run in the cell, with its sign.
        if (!preg_match_all('/(-?)\$\s*([0-9][0-9,]*(?:\.[0-9]{2})?)/', $cell, $found, PREG_SET_ORDER)) {
            continue;
        }

        foreach ($found as $hit) {
            if ($hit[1] === '-') {
                // A change, not a price.
                continue;
            }
            $amount = (float) str_replace(',', '', $hit[2]);
            if ($amount <= 0) {
                // Their page writes $0.00 for a band nobody has sold in, and for
                // a change of nothing. Either way it is not a price.
                continue;
            }
            $out[] = ['band' => $band, 'amount' => $amount, 'currency' => 'USD'];
            break;
        }
    }
    return $out;
}

/**
 * Their tab name against our band.
 *
 * The volume line and the sold-listing counts are both keyed on
 * `completed-auctions-{name}`, and the names are their own: `used` for loose,
 * `box-only` with a hyphen where the price cell has an underscore.
 *
 * Keyed rather than counted by position. The page repeats the last three cells
 * in a second block for narrow screens, so anything walking the row in order
 * reads three of the six twice.
 */
function pricecharting_tab_bands(): array
{
    return [
        'completed-auctions-used'        => 'loose',
        'completed-auctions-cib'         => 'cib',
        'completed-auctions-new'         => 'new',
        'completed-auctions-graded'      => 'graded',
        'completed-auctions-box-only'    => 'box_only',
        'completed-auctions-manual-only' => 'manual_only',
    ];
}

/**
 * How often a copy in each condition changes hands.
 *
 * As the source words it - "1 sale per year", "3 sales per year", "rare" - not
 * as a number. Normalising "rare" into a count would be inventing precision they
 * did not offer, and the phrase is the honest thing to show beside a price.
 *
 * This is the half that makes a price mean anything. $599.50 for a graded copy
 * and "rare" beside it says something quite different from $599.50 and "3 sales
 * per year".
 *
 * @return array<string, string> band => the phrase
 */
function pricecharting_volumes_from_html(string $html): array
{
    $out = [];
    foreach (pricecharting_tab_bands() as $tab => $band) {
        if (!preg_match('/data-show-tab="' . preg_quote($tab, '/') . '"[^>]*>(.*?)<\/td>/s', $html, $m)) {
            continue;
        }
        // The phrase is in the anchor; the "volume:" label beside it is not part
        // of the answer.
        if (!preg_match('/<a[^>]*>(.*?)<\/a>/s', $m[1], $a)) {
            continue;
        }
        $text = trim(html_entity_decode(strip_tags($a[1]), ENT_QUOTES | ENT_HTML5));
        if ($text !== '') {
            $out[$band] = $text;
        }
    }
    return $out;
}

/**
 * How many completed sales the source has seen, per condition.
 *
 * From the "All Sold Listings" select rather than from the tabs, because the
 * select carries every band in one list while the tabs hide some at narrow
 * widths - and a band whose tab is hidden still has a count.
 *
 * Zero is kept rather than dropped. "No sales in this condition" is a fact worth
 * showing beside a price that was derived from something else, and it is the
 * difference between a number nobody should trust and one nobody has tested.
 *
 * @return array<string, int> band => count
 */
function pricecharting_sale_counts_from_html(string $html): array
{
    $bands = pricecharting_tab_bands();
    $out   = [];

    if (!preg_match('/<select[^>]*id="completed-auctions-condition"[^>]*>(.*?)<\/select>/s', $html, $m)) {
        return $out;
    }
    if (!preg_match_all('/<option value="([^"]*)"[^>]*>(.*?)<\/option>/s', $m[1], $opts, PREG_SET_ORDER)) {
        return $out;
    }
    foreach ($opts as $o) {
        $band = $bands[$o[1]] ?? null;
        if ($band === null) {
            // `completed-auctions-grade-three` and the rest of the grading
            // scale. Real bands with real counts, and none of them is a
            // condition this catalogue records - a graded CIB copy is still a
            // graded copy here.
            continue;
        }
        // The label carries markup - "Box<span ...> Only<span> (0)" - so the
        // count is taken after the tags come out.
        $label = strip_tags($o[2]);
        if (preg_match('/\((\d+)\)\s*$/', trim($label), $c)) {
            $out[$band] = (int) $c[1];
        }
    }
    return $out;
}

/**
 * The source's own id for this title, so a later fetch finds the same page.
 */
function pricecharting_id_from_html(string $html): ?string
{
    if (preg_match('/PriceCharting ID:<\/td>\s*<td[^>]*>\s*(\d+)/s', $html, $m)) {
        return $m[1];
    }
    return null;
}

/**
 * One product page, as observations ready to record.
 *
 * The three parsers joined: the price, the volume phrase and the sale count for
 * each band the page quotes. A band with no price is dropped even when it has a
 * count, because a count without a price is nothing to store against.
 *
 * @return array{observations: list<array<string, mixed>>, external_id: ?string}
 */
function pricecharting_observations_from_html(string $html, ?string $observedOn = null): array
{
    $volumes = pricecharting_volumes_from_html($html);
    $counts  = pricecharting_sale_counts_from_html($html);
    $date    = $observedOn ?? date('Y-m-d');

    $observations = [];
    foreach (pricecharting_prices_from_html($html) as $price) {
        $band = $price['band'];
        $observations[] = [
            'band'        => $band,
            'amount'      => $price['amount'],
            'currency'    => $price['currency'],
            // Both kept as the source gives them. A count of zero beside a price
            // is the most useful thing on the page: it says the number was
            // derived from something other than sales of this exact thing.
            'sales_count' => $counts[$band] ?? null,
            'volume_note' => $volumes[$band] ?? null,
            'observed_on' => $date,
        ];
    }

    return [
        'observations' => $observations,
        'external_id'  => pricecharting_id_from_html($html),
    ];
}

/**
 * Record what a source said, for one title.
 *
 * @param array<int, array{band: string, amount: float, currency?: string,
 *                         sales_count?: int|null, volume_note?: string|null,
 *                         observed_on?: string}> $observations
 * @return int How many rows were written.
 *
 * Idempotent by design. The unique key is source, title, platform, band and the
 * date the price was *true* - so importing a dated series twice writes it once,
 * and a page fetched twice in a day is one observation rather than two.
 */
function record_price_observations(
    string $source,
    string $title,
    ?int $platformId,
    array $observations,
    ?string $externalId = null,
    ?string $url = null
): int {
    $bands   = price_bands();
    $written = 0;

    foreach ($observations as $o) {
        $band = (string) ($o['band'] ?? '');
        if (!in_array($band, $bands, true)) {
            // A band this catalogue has no column for. Skipped rather than
            // stored as 'other': a price whose condition is unknown cannot be
            // matched to a copy, and an unmatched price on the page is worse
            // than none.
            continue;
        }
        $amount = (float) ($o['amount'] ?? 0);
        if ($amount <= 0) {
            // Their pages show a blank rather than a zero for a band nobody has
            // sold in. Zero would read as "worthless" where the truth is "no
            // sales", and those are opposite answers.
            continue;
        }

        $date = (string) ($o['observed_on'] ?? date('Y-m-d'));

        // INSERT ... ON DUPLICATE KEY UPDATE rather than a SELECT first: two
        // imports racing would both see nothing and both insert, and the unique
        // key is what actually settles it.
        q(
            'INSERT INTO price_observations
                (source, platform_id, title, external_id, url, band, amount,
                 currency, sales_count, volume_note, observed_on)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                amount      = VALUES(amount),
                currency    = VALUES(currency),
                sales_count = VALUES(sales_count),
                volume_note = VALUES(volume_note),
                external_id = COALESCE(VALUES(external_id), external_id),
                url         = COALESCE(VALUES(url), url)',
            [
                $source,
                $platformId,
                $title,
                $externalId,
                $url,
                $band,
                $amount,
                (string) ($o['currency'] ?? 'USD'),
                isset($o['sales_count']) ? (int) $o['sales_count'] : null,
                isset($o['volume_note']) ? (string) $o['volume_note'] : null,
                $date,
            ]
        );
        $written++;
    }

    return $written;
}

/**
 * The most recent price for a copy in this state.
 *
 * Returns null rather than a number when there is nothing to say: no
 * observation, or a state with no band. A page that shows "—" is telling the
 * truth; one that shows a loose price against a boxed copy is not.
 *
 * @return array{amount: float, currency: string, band: string,
 *               observed_on: string, sales_count: int|null,
 *               volume_note: string|null}|null
 */
function latest_price_for(?string $completeness, string $title, ?int $platformId): ?array
{
    $band = price_band_for_completeness($completeness);
    if ($band === null) {
        return null;
    }

    $row = one(
        'SELECT amount, currency, band, observed_on, sales_count, volume_note
           FROM price_observations
          WHERE title = ? AND band = ?
            AND (platform_id = ? OR (platform_id IS NULL AND ? IS NULL))
       ORDER BY observed_on DESC, id DESC
          LIMIT 1',
        [$title, $band, $platformId, $platformId]
    );
    if ($row === null) {
        return null;
    }

    return [
        'amount'      => (float) $row['amount'],
        'currency'    => (string) $row['currency'],
        'band'        => (string) $row['band'],
        'observed_on' => (string) $row['observed_on'],
        'sales_count' => $row['sales_count'] === null ? null : (int) $row['sales_count'],
        'volume_note' => $row['volume_note'] === null ? null : (string) $row['volume_note'],
    ];
}

/**
 * What a title has been worth over time, one band, oldest first.
 *
 * The question a collector actually asks, and the reason observations are rows
 * rather than a column that gets overwritten.
 *
 * @return list<array{amount: float, observed_on: string}>
 */
function price_history_for(string $title, ?int $platformId, string $band, int $limit = 60): array
{
    if (!in_array($band, price_bands(), true)) {
        return [];
    }
    return array_map(
        fn(array $r): array => [
            'amount'      => (float) $r['amount'],
            'observed_on' => (string) $r['observed_on'],
        ],
        all(
            'SELECT amount, observed_on
               FROM price_observations
              WHERE title = ? AND band = ?
                AND (platform_id = ? OR (platform_id IS NULL AND ? IS NULL))
           ORDER BY observed_on ASC
              LIMIT ' . (int) $limit,
            [$title, $band, $platformId, $platformId]
        )
    );
}

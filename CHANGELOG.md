# Changelog

**A setting that governed nothing.**

`libraries_deletable` has sat on the Security tab labelled "Owners may
permanently delete their own libraries", with help reading "Off means a library
can only be emptied, not removed" - and **nothing read it**. One grep over the
engine found the schema entry and no other mention. An administrator could switch
it off, be told the policy had taken, and owners went on deleting libraries.

That is worse than a missing switch: somebody decided a policy, was told it was
in force, and it was not.

It is read now, in `api_libraries_delete()`. Two things had to be right for
turning it on not to break instances:

- **The schema default said `''`, which in this file means off.** Wiring the
  check up naively would have stopped every owner on every existing instance from
  deleting anything, on the strength of a switch nobody had ever been able to
  set. The default is `'1'` - what every instance has actually been doing - so a
  dead setting coming to life changes nothing about a running one.
- **`is_admin()` reads the session, and an API request has a token.** So it was
  false for every administrator and their own switch locked them out. Caught by
  trying it: an administrator's token was refused, and it is
  `is_admin_user(acting_user())` now.

**And two help texts that had stopped being true.** "Where people go" still
promised that blank falls back to the public address - the fallback removed in
build 237, because it was the redirect loop. It now says what address it wants
and why it cannot be this one.

Pinned in `tests/acl.php`.

This package is **build 238**.

**An address pointing at itself is a redirect loop, not a way in.**

Reported from a live instance: `url` and `client_url` both set to
`https://retrohive.noh.nu`, so `/` answered with a redirect to `/` and a browser
followed it until it gave up. The engine is at the root there and its client is
served from `/web` - which is what `client_url` wants.

`client_base()` refuses the two being equal, and **no longer falls back to
`site_url` when `client_url` is unset**, which was the same trap arrived at by
doing nothing at all: unset meant "this instance", which meant the loop. Both
cases now answer "not configured", which is a true statement somebody can act on
- "too many redirects" reads as a broken server rather than as a setting nobody
has filled in.

The page says which address it wants and why the two cannot be the same. So does
the installer's guidance, `INSTALL.md`, and the example answer file, which now
shows the pair as it should look.

Pinned in `tests/schema.php`: the same address twice is refused, the client's own
address is used, and unset does not fall back to the engine.

This package is **build 237**.

**The log sent raw bytes where an address belongs.**

`logs.ip` is `varbinary(16)` - what `inet_pton()` made of the address - and the
endpoint sent it as-is. So every client got `\x7f\x00\x00\x01` instead of
127.0.0.1: a control-character salad in a JSON string, which a strict decoder
refuses outright and a browser renders as nothing much.

`inet_ntop()` on the way out. The web client reads the same field and has been
showing the same nonsense; it was simply less obvious in a table than in a
decoder that says no.

This package is **build 236**.

**A lookup said "6 prices recorded" and the entry showed none.**

`/metadata/apply` wrote observations under the **candidate's** title -
PriceCharting calls a release "Dune (Amiga)" where the shelf says "Dune" - while
both readers ask by the entry's own title: the history behind the chart, and the
list on the edit screen. So the prices were in the table the whole time, filed
under a name nothing asks for.

Recorded under the entry's title now. The provider and its remote id still travel
with the row, so a later sync still matches the same listing; only the key
somebody looks it up by changes.

Pinned in `tests/prices.php`: a row under the source's name is invisible to the
entry, one under the entry's is found. Two assertions that would have caught this
the day it was written.

This package is **build 235**.

**The PC had no environments at all.**

Amiga had four and the C64 two; the one platform where "which of these does it
run under" matters most had nothing to answer with - a 1993 DOS game and a 1998
Windows game are different software on one machine. MS-DOS, Windows 3.x, 9x, NT,
XP, Vista, 7, 10, 11 and Linux, in the order they arrived and spaced by ten so a
version nobody thought of can go between two.

**A price can be recorded by hand.** `POST /items/{id}/observations`. Observations
arrived from an agent or not at all, so a figure the owner knew for certain -
three copies sold locally, a dealer's asking price - could only go in the entry's
own "estimated value", which was undated and single-currency. Recorded against
the title and platform like every other observation, with `source: manual` so the
next sync does not overwrite it as a stale agent figure. The date defaults to
today, the band to this copy's own, the currency to the instance's.

**And the day an observation was seen is editable.** It was the one field on the
row nobody could change - and a price is a fact about a day: the chart places it
on a timeline and the conversion uses that day's rate, so a mistyped date was
permanent.

Two things caught by running it rather than reading it: `api_input()` does not
exist (`api_body()` does), and the new date block sat *below* the "did you send
anything" check that guards it, so a date-only correction was refused. Both found
by patching a live observation three ways - date only, empty, and rubbish.

This package is **build 234**.

**The currency answer never reached the setting that shows it.**

An install told `SEK` wrote it to the configuration file, and `display_currency()`
falls back to that - so conversion *did* work. What it never touched was the
Currency setting on the General tab, which has its own default of **USD**. So the
screen said dollars while the engine used kronor, and the first save on that tab
wrote the dollars back over the answer.

Two places holding one fact and the installer filling only one of them. Proved
before fixing: on a fresh database the setting read `NULL` while
`display_currency()` returned `SEK`.

`installer_apply_settings()` writes both, from both installers, and says which it
wrote rather than claiming what it skipped.

**And `instance.library_autofill` is an answer now.** Whether a library somebody
creates starts with the filing structure copied in - the Catalogue tab's setting,
on by default, examples never part of it - was reachable only by hand after an
install. The web installer gained a tick box for it beside the examples question,
where the same distinction is already drawn.

Both survive the JSON export, the INI export and being read back, which is where
a new answer usually goes missing.

This package is **build 233**.

**The price chart plotted dollars against an axis labelled kronor.**

`/items/{id}/prices` dropped the currency the observation was quoted in, so every
client took the number for whatever the instance shows. On an instance set to
kronor a market value of **$109.88** was drawn at *110 SEK* - the right shape at a
tenth of the scale, with nothing about it looking wrong, on the same screen as a
headline reading **SEK 1,039.02**. The two numbers were the same price and
disagreed by a factor of nine.

`price_observations.currency` has been there since valuations were added. The
column was in the table, the headline converted from it, and the history query
selected around it.

**Converted in the engine, point by point, at the rate for the day each was
observed** - which is what `in_display_currency()` takes a date for: a price from
2019 is worth comparing at 2019's rate rather than at today's. One fix for all
four clients, rather than the same arithmetic four times.

A point with no rate to convert by is left as it was and marked
`not_converted` rather than dropped: a gap in a line is a fact about the market,
and this would be a fact about the rate table.

Checked with a dollar-quoting source against a kronor instance: $109.88 on a
9.456 rate now reaches the client as 1039.03 SEK, and the older observation
converts at its own date.

This package is **build 232**.

**An unattended install can now finish on its own.**

`client_url` was the one thing neither installer asked for and neither could be
told - so every scripted install ended with a hand-finishing step: the account
made, the database loaded, and `/` answering 503 headed "Not configured" because
the engine had nowhere to send a browser.

It is `instance.client_url` in the answer file, a field on the web installer's
settings step beside the public address, and a line in the CLI's summary. Blank
is a real answer - somebody who has not installed the interface yet should not be
made to invent an address - and the CLI says plainly what blank costs rather than
leaving it to be discovered.

Written as a settings row rather than into the configuration file, because
`to_client()` reads it per request and an administrator can change it later
without editing anything.

**Round-tripped both ways.** The key survives `--example`, the INI export and
being read back, which is where a new answer usually goes missing: the parser
took it, and the normaliser and the INI writer would each have dropped it.

The guidance printed beside the example now covers `install.structure`,
`install.examples` and both addresses, and `INSTALL.md` documents the
`[instance]` block, which it never had.

This package is **build 231**.

**A library somebody creates starts with the filing structure again.**

"It starts out empty" was the answer when a client said nothing either way, and
it is a poor one for somebody who has just pressed *new library*: they asked for
a place to file things and got a tree to build first. The reasoning it came from
- an account made by a directory should not arrive holding sixty-three platforms
it never asked for - is about accounts created *for* people, not about somebody
asking.

`library_autofill` on the Catalogue tab decides it, and defaults on. A client
that asks for structure or examples outright is still obeyed; this only fills the
silence.

**Examples are never the silent answer**, whatever the setting says. Those are
somebody else's collection rather than scaffolding - the same line the installer
has always drawn.

**The install guide named an answer-file key that does not exist.** It documented
`templates` where both installers read `structure`, so a response file written
from the guide would have been ignored and the default used. The key, its three
values and the fact that `examples` is off by default are written out properly
now. The behaviour was already right: checked by parsing a response file that
sets both and reading back what the installer would use.

This package is **build 230**.

**A fresh install has no exchange rates, so it cannot convert anything.**

Both installers have asked for a currency for as long as they have existed, and
neither fetched a rate for it. So an instance set to SEK whose sources quote in
dollars answered "what is this worth" with the source's own currency and no
conversion - which reads as the feature not working rather than as a table
nobody has filled.

`installer_seed_exchange_rates()` runs beside the metadata step in both, and
reports what it got. Not fatal: it reaches the European Central Bank, and an
install behind a firewall that cannot must still finish. It is the one step here
whose failure costs nothing that cannot be had later with one press.

**And saving a setting no longer goes to the internet.** Choosing a currency used
to fetch the rates as a side effect of the save, so a save could sit waiting on
somebody else's server and then succeed - which reads as saving being slow. It
also fetched *only* when there was no rate at all, so the one case somebody
actually wants - "these look stale, get today's" - was the case it skipped.
`POST /admin/exchange-rates/refresh` is the button that does it.

This package is **build 229**.

**A sale price says it sold, not just a sale date.**

`api_item_input()` settled the status from `sold_on` alone, so filling in what a
copy fetched and nothing else left an entry marked owned with a sale on it -
which the very next rule then wiped, because owned means no sale block. Two
fields, one fact: either half of a sale now settles the status, unless the caller
said otherwise in the same breath.

This package is **build 228**.

**The install guide stopped at the engine.**

Six steps, ending at first run, and nothing about the web interface - so
following it gets you an API, a working phone, and a browser that says "Not
configured". It has a step of its own now: a second checkout, a second vhost,
`CORE_ENGINE_URL` and `CORE_ENGINE_UPLOADS_URL`, and the `client_url` setting on
the engine, **before** first run rather than after, because first run ends by
handing the browser onward.

**The web installer does not do this**, and the guide now says so where somebody
meets it rather than where it would be tidy. `public/install.php` has no field
for `client_url`: a clean run still lands on the 503, with the account made and
the database loaded. That is a gap and not a decision - the installer predates
the split and nobody has been through it since.

**Two symptoms rewritten because they are no longer subtle.** A missing
`Authorization` header used to mean "the web interface works and the API returns
401"; the interface is a client and carries a bearer token, so now it means
setup succeeds and every screen after it reports that the server did not answer.
Troubleshooting gained that one, "setup finishes and lands on Not configured",
and "every page fails but the phones are fine" - which is `CORE_ENGINE_URL`, and
the phones are unaffected because they talk to the engine directly.

**And the post-install steps described a catalogue from two versions ago:**
"Manage → Libraries, ten come pre-loaded", "Software types and Genres". A shelf
starts empty on purpose - an account made by a directory should not arrive
holding sixty-three platforms it never asked for - and the structure is copied in
from the library's own edit page, in whichever parts somebody wants.

This package is **build 227**.

**The deployment guide would have left somebody with no web interface.**

It described one Apache serving both the API and the web UI, from one document
root, and said so in the first paragraph. There are two applications now, and
following that guide gets you the engine and nothing to look at it with.

The failure is worse than a missing page, because it happens *after* something
that worked: first-run setup creates the administrator account successfully and
then hands the browser to the client, which with `client_url` unset is a 503
headed "Not configured". The account is fine. The engine simply has nowhere to
send them, and nothing on that page says so.

**Added:** the client's own virtual host - a second name, a second document root,
no database access and no `config.local.php`, told where the engine is through
`CORE_ENGINE_URL` the same way the test runner tells it. The `client_url` setting
on the engine, with the SQL to set it before an administrator exists. Both in the
"what breaks without each setting" table, which is the part somebody reads when
it has already broken.

**And one asymmetry worth explaining rather than leaving to be discovered.**
`CORE_ENGINE_URL` is internal and `CORE_ENGINE_UPLOADS_URL` is public. That looks
like an inconsistency and is not: the client fetches from the API itself, and the
*browser* fetches the photographs. An internal address in an `<img>` is a broken
image on every device outside the network.

**Corrected:** the verification steps checked the session cookie at
`retro.example.com/login`, which the engine no longer serves - `/login` went with
the screens. They ask the client now, and there are two new checks for the thing
the split added: that the engine sends a browser onward rather than refusing, and
that the client can reach the engine at all.

This package is **build 226**.

**The README described an application that no longer exists.**

"One PHP application today, not yet split into a separate headless service —
`public/index.php` routes to either the JSON API or the HTML pages." It does not.
The screens are `retrohive-clients-web`, a separate application on a separate
origin, and what is left here that is not `/api/v1` is four things: first-run
setup, the paths asked by something that is not a person, the CSV export no
screen links to, and `/` sending a browser to the client.

The diagram showed this repository's own web pages calling `src/` in the same
process. Nothing does that any more.

Documentation that describes an architecture two releases old is the same fault
as a test asserting an old implementation, and harder to notice: nothing fails.

**And the shape is worth stating, because the split's failures were all one
shape in reverse.** Every rule is on this side, so a client asking whether a
lookup is worth offering, whether a branch may be deleted, or what floor a place
is on gets the same answer as every other client - it asks rather than works it
out. What went wrong was rules left behind: a guard reachable by nobody, a box
rule written over, a sale block only the dashboard still read. The README says so
now, where somebody deciding where to put a rule will read it.

This package is **build 225**.

**Checks that existed, were maintained, and could be run by nobody.**

`src/maintenance.php` has carried jobs marked `'scope' => 'library'` since
maintenance was written - rootless branches, machines with no branch of their
own, entries shelved in a place another library owns - and
`api_maintenance_index()` says plainly that it serves the instance ones only,
"because the library ones belong to a library and are reached through it".

Nothing reached them. There was no endpoint, so a client could not ask, and the
screen that used to had gone. The checks ran from nowhere.

`GET /libraries/{id}/maintenance` and `POST /libraries/{id}/maintenance/{job}`.
`maintenance_run_check()` has taken a library id all along, which is how long
this has been an endpoint away from working.

**Curator, not administrator.** Every one of them changes or reports on what is
filed in one library, which is what a curator is for - the same bar
`maintenance_jobs_for()` already applies.

**Also: a lookup offered where nobody would answer.** `can_look_up` on the entry
says whether `providers_for()` finds a source for the branch it is filed under. A
branch nobody is asked about must not offer to ask - a rule the entry form used
to carry as an attribute per category option, lost when the form was rewritten,
and one the engine is the right place for: every client asking gets the same
answer.

**And C64 was matched to Commodore 64 in build 223**, which is in this package
too.

This package is **build 224**.

**C64 is Commodore 64.**

`metadata_suggest_platform_map()` strips the maker word and then requires the two
names to be equal - so TheGamesDB's "Commodore 64" became "64" while the platform
here is called "C64", and the commonest home computer of the era matched nothing.
Somebody mapped it by hand, every time. The same shape catches C128, A500, ST,
CPC and the BBC Micro.

**Named pairs, not a fuzzy score.** "Close enough" on platform names is how a
Mega Drive game ends up filed under the Mega-CD. These are spellings somebody has
decided are the same machine, and anything not on the list still has to match
outright.

This package is **build 223**.

**A location list that could not say what floor a place is on.**

`location_floor()` walks the ancestry to answer "which floor does this apply on"
and has done since floors were added - the item screens print it. The list
endpoint left it out, sending only what each place says for *itself*.

So a client editing a place had an empty box and no way to say what the blank
meant. The web client's Locations screen carried a tooltip explaining that blank
inherits, which is an explanation standing in for an answer.

`floor_effective` and `floor_inherited` go with each row now. Two fields rather
than one, because "nobody above has decided either" and "it is 0 here" are
different answers and a single number cannot tell them apart.

Resolved once per row: `location_floor()` reads the row and then walks its
ancestry, and a tree of two hundred places asked twice per row is two hundred
queries nobody needed.

This package is **build 222**.

**The delete guard needed a column nobody was selecting.**

`api_items_delete()` reads three columns - id, library_id, created_by - because
nothing there needed a fourth until build 220 called `item_delete_blocker()`,
which puts the entry's name in its refusal: "Blizzard 1230 is fitted to Amiga
2000". So the guard worked and PHP warned on every delete.

Caught by `tests/web.sh`, which fails on any warning in the router log for
exactly this reason: an undefined key is a defect here, not noise.

This package is **build 221**.

**Deleting a machine left its accelerator pointing at nothing.**

`item_delete_blocker()` is the rule that refuses to delete an entry with
something fitted to it, or something fitted inside it. It has been in
`src/models.php`, correct and covered by tests that call it directly - with **no
callers**. The screen that used to ask it went to the web client, and nothing on
this side picked the question up, so `api_items_delete()` checked that the
account may write to the library and then removed the row.

Through every client at once, since they all delete the same way.

It is asked now, before anything is removed - a guard that runs after the
pictures have gone is not a guard - and answers **409**, not 422: nothing about
the request is malformed. The catalogue is in a state where this cannot happen
yet, and the message says what to do about it.

This package is **build 220**.

**A sold entry could sit on the shelf, and the dashboard counted the money.**

Three rules left the engine when the entry form became a client and nothing
replaced them, so `api_item_input()` would take `status: owned` with a filled-in
sale block - two controls for one fact, contradicting each other.

Not merely untidy. `api_stats()` totals `SUM(sold_price) ... FROM items` with no
test on status at all, so an entry carrying a stale sale is counted as money
recouped while it is still on the shelf. The dashboard has been reading the block
as fact whatever the status said; this is the writer catching up with it.

**Status is the single answer and the block follows it.**

- A sale date settles the status to `sold`, unless the caller said otherwise in
  the same breath - somebody filling in when they sold it has told you it is
  sold, and making them change a dropdown as well is asking twice.
- Any other status clears the block, currency included. That is how an entry is
  un-sold: put it back on the shelf and the sale goes with it, rather than
  lingering where only a total will find it.
- A sale with no currency named was made in the money the entry was bought in.
  Not the instance's default: an entry bought in kronor and sold without saying
  is a sale in kronor, and guessing otherwise puts a figure at the wrong scale
  into a sum.

**At the end of the function, and that is the whole of the bug it nearly
repeated.** The first version sat where the box rule used to, and the money and
currency blocks further down wrote over it - the same fault as build 216, in the
same function, found the same way: by probing it rather than by reading it.

Found by `tests/box.php`, which now passes 34 of 34.

This package is **build 219**.

**Eleven endpoints that existed and were not written down.**

`docs/openapi.yaml` had no entry for exchange rates, the price history and the
observations behind it, a branch's metadata sources, teaching a source what a
machine is called, the currency list, or slot types - twenty-one routes across
eleven paths, all live in `public/index.php`, none documented. A client author
reading the specification would have concluded the price history did not exist.

They are in now, with the reasoning that is already in the code beside each
handler rather than a restatement of the URL:

- `/items/{id}/prices` answers "what has it been doing" rather than "what is it
  worth", which is the question somebody deciding whether to sell actually asks -
  and every band, because a boxed copy's owner still watches the loose price.
- `/observations/{id}` corrects the amount and the sales count and **not** the
  band, title or date: those are what the row *is*, and changing one writes a
  different observation over this one.
- `POST /categories/{id}/sources` takes `on`, `off` **or** `inherit`, and the
  third is the one worth documenting: without it a branch could only ever be
  given an explicit answer.
- An entry in a library this account cannot read is **404** on the price routes,
  not 403 - the same shape the images route uses, and for the same reason.
- The provider-platform mapping is a POST rather than a PUT, and the router says
  why: no client here has a PUT, so one verb for one endpoint would be a method
  added to every client for tidiness rather than for a reason.

`SlotTypeInput` is the one new schema. Everything else references components that
were already there, and every `$ref` in the file resolves.

Found by `tests/copy.php`, which walks the router and checks each path against
the specification - so this stays true.

This package is **build 218**.

**Every company copied into a library said it makes games.**

`copy_reference_data()` builds the row list by hand, and `domain` was not in it.
The column is `ENUM('game','software','both') NOT NULL DEFAULT 'game'`, so the
copy did not fail, did not warn, and did not leave a gap: it wrote the default.
Digita International, Gold Disk and NewTek arrived in every library as makers of
games, and Electronic Arts lost `both` the same way.

Nothing about that looks wrong from the outside. A value is there, it is valid,
and the only way to know it is the wrong one is to compare it with the row it was
copied from - which is exactly what `tests/copy.php` does, and has been saying
for as long as anybody has run it.

`domain` is in the list now. `logo_filename` stays out, deliberately, and the
comment above it says why: it names a file in `public/uploads`, and pointing
sixty library rows at one file means removing any of them takes the badge off all
the others.

This package is **build 217**.

**Unticking the box kept the grade.**

    has_box        0
    condition_box  very_good

Both written by the same save. `rule_box_state()` exists to stop exactly that -
grading a box that is not there is meaningless - and it was being called
correctly, with the right arguments, returning the right answer.

`api_item_input()` writes `condition_box` in **two** places. The flattened block
near the top, and a second one further down that handles grades arriving nested
under `components` and builds its key as `'condition_' . $part`. The box rule sat
between them, so the second block read the raw input again and put the grade
back. A text search for `condition_box` never showed it, because that block never
spells the word.

The rule moved below both. It has the last word whichever block wrote the grade -
and it now sees a grade sent as `components.box`, which bypassed it entirely
before, since only the second block understands that shape.

**The same rule was unreachable in its other half.** `rule_box_state()` takes
null for "the caller has no box control at all - the software form posts a grade
and no checkbox" and infers a box from the grade. The API only ever called it
with a bool, so a client sending `condition_box` alone left `has_box` at 0 while
grading a box the catalogue then said was not there. It runs when either half
arrives now.

**And the purchase currency is upper-cased, like the sale's already was.** Only
`sold_currency` was, so an entry could be bought in `sek` and sold in `SEK` - two
spellings of one currency in two columns of one row, and every comparison between
them a string comparison.

Found by a test suite, not by reading: `tests/box.php` was repointed at
`api_item_input()` this round, and said so on the first run. Reading the function
afterwards still did not explain it - the box block looks right where it stood.

This package is **build 216**.

**Every metadata lookup was a database error.**

    Unknown column 'mapped.platform_id' in 'ORDER BY'

`mapped` is the platforms table, whose key is `id`; the mapping's own column
lives on `mpp`. The two names read alike, only one of them exists there - and the
page reported it as "cannot reach its database", which was true of that statement
and of nothing else.

`php -l` cannot see this, and neither can loading every unit together: a
statement is only wrong once a database is asked to run it. A check now reads the
`platforms` table out of `schema.sql` and tests every `mapped.`, `scoped.` and
`asked.` column against it - the three aliases this engine gives that table.

Verified by putting the wrong column back and watching it named.

Full suite: still 1 of 25, unchanged.

This package is **build 215**.

**A condition report that reported nothing.**

    Overall     Not graded
    Box         Good
    Manual      Not graded
    Media       Not graded

Three of those four rows are a form somebody has not filled in, printed as though
they were findings.

The web client already drew only the parts that had a label - the intent was
there and had been for a long time. **Every part had one:** `condition_label()`
answers "Not graded" for a column nobody filled in, which is right where a grade
is being asked for and wrong on the way out, so the guard passed on all of them.

Nothing is sent for a part with no grade, in both senses of ungraded - null on a
row nobody touched, `unknown` where somebody chose it. The value still goes, so a
client that wants to show the absence can.

**The phones needed no change.** Both already skip a row with no value, and both
have said so in a comment for months - they were being handed a value that was
not one.

Full suite: still 1 of 25, unchanged.

This package is **build 214**.

**"Not graded" is not a grade.**

`condition_label()` answers "Not graded" for a null, which is right where a grade
is being asked for and wrong on the way out: a client testing "is there a label"
found one on every part, so an entry nobody had graded drew four rows saying
nothing about the object.

Nothing is sent where there is nothing. Both ways it is stored - null on a row
nobody touched, `unknown` on one where somebody chose it - and the same for
completeness, where "Unrecorded" is not a state of the object either.

The value is still sent, so a client that wants to show the absence can.

Full suite: still 1 of 25, unchanged.

This package is **build 214**.

**A recorded valuation can be corrected.**

A market's quote is evidence rather than gospel - a different edition, a
mispriced listing, or simply wrong for a shelf in another country. Nothing could
change one: the observations table had no update or delete path, and the history
query returned no ids to name a row by.

The amount, how often one sells, and how many sales that came from. **Not the
band, the title or the date** - those are what the row *is*, and changing one
would be writing a different observation over this one rather than correcting it.

**Zero is refused.** The source records "nobody has sold one" by not quoting a
price; a zero typed here would read as "worth nothing", which is a different
claim.

## What happens on the next sync

Correcting a row sets its source to `manual`, which changes the unique key - so a
later sync inserts the market's figure **beside** it rather than over it, and
nothing is lost either way.

But `ORDER BY id DESC` alone would then show the machine's answer again and make
the correction look like it had not saved. A correction now wins for its own day.
Without one, the newest quote still does.

## Permission, for a row that has no owner

An observation belongs to a title and a machine, not to an entry - two shelves
holding the same game share what the market said about it. So it is asked of an
entry this account may write that matches, and there may be none even though the
row exists.

Full suite: still 1 of 25, unchanged.

This package is **build 213**.

**A valuation lookup shows what the prices come to here.**

The table was headed "as published" and left at that, on the reasoning that these
are what the source quoted before anything is recorded. True, and not the point:
somebody looking at a valuation wants to know what it means for them, and being
told to record it first and look again is a poor answer to a fair question.

Both figures now. The published one leads, because it is the one that can be
checked against the source.

**`GET /currencies`** so a client can offer the list rather than keeping its own.

## A parser that needed the whole application

`display_currency()` calls `setting()` and `config()`, and `prices.php` is loaded
by the metadata agents as well as by the application - so converting a candidate's
prices fataled inside a price parser in every test that loads an agent without
the helpers. Ten suites went red at once.

Both are guarded, and so is the rate lookup: dollars is the honest answer when
there is nothing to say otherwise, because it is what the sources quote.

Full suite: still 1 of 25, unchanged.

This package is **build 212**.

**Platforms arrived with no sections.**

Every Sections box on the manage screen was unticked - Blu-ray not video, CD not
audio - on data that has always said otherwise. The column holds them, the
shipped structure ships them, the sync writes them and the library copy carries
them.

`platform_to_api()` sent nine fields and `domains` was not one of them.

So the screen drew four empty boxes for every platform, which reads as "the data
does not say" rather than "the answer was dropped on the way here" - and saving
one of those rows would have written the empty set back over a correct one.

**Credit roles share the parsing now.** They had their own `explode`, which did
not trim - so a column written "hardware, software" by hand yielded a domain
called " software" that matched nothing. One helper for both.

A blank column is an empty list rather than `['']`: a platform in no section is a
real state, and a list holding one empty string is not the way to say it.

Full suite: still 1 of 25, unchanged.

This package is **build 211**.

**The engine could not start.**

    Cannot redeclare currency_options()

Build 207 added a currency list to `settings_schema.php`. `models.php` had one
already - written for the per-entry currency field and never wired to anything -
and PHP fatals on the redeclaration **before any route is reached**. Every
request answered 503. The deploy check said "NOT operational" and was right.

Merged into the one that existed, which now also says which currencies this
instance has a rate for.

## Why nothing caught it

`php -l` parses one file at a time. Each of these was valid; the collision only
exists once both are in one process, which is a state no check here ever entered.

Every unit is now loaded together, in the order `public/index.php` loads them and
read from that file - so a unit added there is covered without anybody
remembering to add it in two places.

Tested by putting the redeclaration back: `php -l` calls the file fine and the
new check fails.

Three builds of deploy-script fixes were chasing a message that was telling the
truth all along.

Full suite: still 1 of 25, unchanged.

This package is **build 210**.

**The install now says whether its own configuration can be read.**

    Configuration written to .../src/config.local.php
    Configuration owned by wwwrun:www
    ...
    Configuration readable: mode 0640, owned by wwwrun

Every line of a successful install can be true and the site still answer 503. The
installer writes the file as whoever ran it; the web server reads it as somebody
else; nothing between those two facts was checked.

There is a step that fixes this - it chowns the file to the web server - and it
**only runs when the posix extension is loaded**. Without posix it was skipped in
silence, which is the same broken outcome with no clue attached. Said out loud
now, with what will happen if nobody acts on it.

The state is read back at the end rather than assumed, and the owner and mode are
printed. `is_readable()` would answer for the account running the installer, and
the question is about a different one - so the answer is the facts, for somebody
who knows which account serves the site.

Full suite: still 1 of 25, unchanged.

This package is **build 209**.

**"Unconfigured" covered three different problems.**

The status said it for a configuration that is not there, one that is there and
cannot be read, and an install that has never been run. A deploy check reading
that could only say "not operational".

The middle one is the common case and the least obvious: an installer running as
one user writes a file a web server running as another cannot read. The install
reports success, every line of it true, and the engine then says the same word it
would say if nothing had been installed at all.

    "config": "unreadable",
    "why": "The configuration exists and cannot be read - check its owner and mode."

## The deploy script ships here now

It runs from the server rather than from a checkout - it deletes and replaces the
checkout it would be running inside - so it is a copy somebody made once. A fix
made in the repository never arrived, and the last two builds' corrections to it
went nowhere.

It lives in `deploy/` so the copy has something to compare itself against, and
says so when the two differ. Compared rather than overwritten: replacing a
running script mid-run is how a shell reads half of one file and half of another.

Full suite: still 1 of 25, unchanged.

This package is **build 208**.

**Choosing a currency fetches the rates to convert by.**

Setting SEK and still seeing dollars looks like the setting did not take. It did:
there was no rate, because nothing had fetched any and the only way to was a
command nobody had been told to run. Half a decision.

Choosing a currency now fetches them - only when it changed, only when there is
no rate for it yet, and a source having a bad afternoon is not an error: the
setting saves, the conversion falls back to dollars, and the page says so.

**And the page says so.** A price staying in dollars now carries the reason -
"No exchange rate for SEK yet." - because that is a different problem from a
setting that did not save, and looking identical to one is how somebody spends an
hour on the wrong thing.

## A list, not a text box

Thirty-one currencies, the ones the rate source publishes - offering one they do
not quote is offering a setting that cannot work. Each says whether this instance
has a rate for it yet.

The dollar is the first entry and reads "as the sources quote": choosing it means
"do not convert", which is a real answer rather than the absence of one.

Full suite: still 1 of 25, unchanged.

This package is **build 207**.

**A mapping pass that always found nothing.**

The install output has a line for it and that line has never appeared:

    PriceCharting: 8 platforms mapped
    First library created
    Shared example library created with 20 entries of its own

The installer mapped platforms again after the libraries existed, on the
reasoning that sources are switched on first and a library's own copies of the
shared platforms are made afterwards. That reasoning was right and the pass was
still redundant: **`metadata_platforms` is one of the parts every new library's
structure seeding already runs**, and by then the sources are there.

It printed only when it wrote something, so an install looked identical whether
it did anything or not - which is how a pass doing nothing survived three builds
of being read.

Removed, with a note where it was. A pass that does nothing is one somebody later
has to work out the purpose of.

Verified rather than reasoned: both libraries an install creates go through
`seed_library_hardware()`, which takes every part by default and is where the
mapping block lives.

Full suite: still 1 of 25, unchanged.

This package is **build 206**.

**What was paid, in the money the rest of the page is in.**

An entry records what somebody paid and the currency they paid in - which is
their own money, not the dollars a market quotes. So converting it means going
through the dollar: kronor to dollars, dollars to pounds.

**Both legs are required.** Half a chain is not half an answer, and inventing the
missing leg would put a confident wrong number on a page. An amount with no route
stays as it was recorded.

At the rate for the day it was bought, so "I paid this, it is worth that" is two
figures in one money and neither has been moved by a rate that changed since.

Full suite: still 1 of 25, unchanged.

This package is **build 205**.

**Prices in the money somebody actually spends.**

The markets these prices come from quote in dollars. A shelf in Sweden is not
priced in dollars, and the instance already had a `currency` in its config that
nothing read.

`display_currency` is a setting now - three letters, changed from the settings
screen rather than by editing a file on the server.

## Converted at display time, never on the way in

An observation keeps what the source said. Rewriting it into local money would
lose the number that was actually published and bake in whatever rate applied
that afternoon.

**At the rate for the day it was observed**, not today's. A shelf's history is a
history of prices *and* of what money was worth: converting a 2019 price at
today's rate would draw a line that moved when neither did.

**A missing rate is not invented.** An amount with no rate to convert by is shown
in dollars and says so - a kronor sign over an unconverted number is the one
outcome worse than not converting.

## Where the rates come from

The European Central Bank's daily reference set: XML, free, no key, no account.
It quotes against the euro, so every rate is derived - the dollar inverted, then
the rest through it. Without a dollar rate in the answer nothing is written,
because deriving one through a third currency would be guessing.

`./bin/rates.php`, run from maintenance. A night without the ECB is **not a
failed run**: rates go stale gracefully, the conversion falls back to the nearest
one there is, and the message says the last ones still apply.

Full suite: still 1 of 25, unchanged.

This package is **build 204**.

**"This source everywhere except on the C64" was expressible and unwritable.**

`provider_scopes.platform_id` has been in the schema since it was written, with
an index on it and a ranking rule in `providers_for()` that puts a machine rule
above its branch. Every writer sent `0`.

So the column, its index, the ranking, and the library guard added to the join in
build 202 were all covering rows nothing could create. A comment in the schema
described the feature; nothing implemented it.

    an entry on the C64, filed under Games:
      on at Software (branch)          -> asked
      off at Software, C64 only        -> not asked
      on at Games (branch, deeper)     -> asked
      off at Games, C64 only           -> not asked

A machine rule beats its branch at the same depth, and depth still wins overall -
which is what the scoring already did, confirmed by running it rather than by
reading it.

**A machine from another library is refused**, because the lookup would not match
it: scoping a branch to a platform row somebody cannot see leaves a rule that
silently never fires.

Full suite: still 1 of 25, unchanged.

This package is **build 203**.

**One fix, two places, and only one of them done.**

Build 192 taught `provider_scopes` to match a platform by slug, because every
library has its own copy of the shared rows and matching on the row id missed
them. Build 197 found that matching by slug alone reaches **every** library with
a machine of that name, and gave the mapping lookup a guard.

The scope lookup did not get one. So a scope somebody set on their own Amiga
could decide which sources are asked about somebody else's - the same leak, in
the half that was found first and fixed last.

    an entry on library 7's Amiga sees: any platform, the shared Amiga, library 7's Amiga
    an entry on library 9's Amiga sees: any platform, the shared Amiga, library 9's Amiga

This library's rows or the shared template, never another library's. A scope that
names no machine at all - "any platform" - is unaffected, because it never
crosses a boundary to begin with.

The other slug joins in the engine were checked rather than assumed: the mapping
lookup carries its guard in the `WHERE`, and the category one binds
`mc.library_id` directly.

Full suite: still 1 of 25, unchanged.

This package is **build 202**.

**Who may read a branch's sources, and who may change them.**

Yesterday's endpoints got both wrong.

**Reading** selected the category's `library_id` and never looked at it, so
anybody signed in could read another library's filing configuration. Checked now,
and answered as "not found" rather than "forbidden" - a tree in a library this
account cannot read is not something to confirm the existence of.

**Writing** required an instance administrator, which is wrong in both
directions: it let an admin rearrange a library they have no part in, and stopped
a library's own curator from arranging their own tree. Which sources a branch is
asked about is a decision about that branch, and belongs with the rest of the
structure permissions.

    a library curator, own tree          may edit: yes
    a library curator, another tree      may edit: no
    a curator, the shared tree           may edit: no
    an admin, the shared tree            may edit: yes

The shared tree is `is_admin()` rather than `can_manage_library()`, which falls
back to whatever library the person happens to be working in - that would let a
curator of one shelf edit the template every library is built from.

The answer says whether this account may change any of it, so a client can show
the configuration without offering buttons that lead to a 403.

Full suite: still 1 of 25, unchanged.

This package is **build 201**.

**Which sources a branch is asked about, editable at last.**

`provider_scopes` has modelled this since the schema was written: bound to a
node, inherited downwards, and a row deeper in the tree can switch a source off
for its own subtree. It was seeded on install and read on every lookup, and
**nothing could change it** - no endpoint, no screen. The old non-API version had
this; the rewrite carried the table and left the editing behind.

`GET` and `POST /categories/{id}/sources`.

**Three states, not a checkbox.** On here, off here, or inherited - and inherited
is the common one. A screen with only on and off makes somebody set explicitly
what they already have, and the setting then stops following the branch it came
from. `inherit` removes the row rather than writing one.

The answer says **where it came from**, so "on" reads as "on, because Software
says so" rather than as a setting nobody remembers making.

Read in one query rather than one per source per ancestor: thirteen sources and a
tree five deep is sixty-five statements for a screen with thirteen rows on it.

Full suite: still 1 of 25, unchanged.

This package is **build 200**.

**A mapping can now be corrected by hand.**

Every seeder in this engine says it fills gaps and never writes over a mapping
somebody corrected by hand. Nothing could make one - there was no endpoint and no
form - so the comments had been describing a capability that did not exist, and a
shipped mapping that was wrong for a shelf could only be lived with.

`POST /admin/metadata-providers/{id}/platforms/{platform}` with what that source
calls the machine. This one **writes over**, which is the whole point: the
seeders fill gaps precisely so they do not undo it.

POST rather than PUT because every other write on this resource is a POST and the
clients have none - one verb for one endpoint would be a method added to every
client for tidiness rather than for a reason.

**Clearing is not mapping to nothing.** With no row the lookup falls back to the
shared template, which is the shipped answer: removing a correction puts things
back rather than switching a machine off.

Full suite: still 1 of 25, unchanged.

This package is **build 199**.

**The mapping count was measuring the wrong thing.**

The sources list counted every mapping row on the instance. Once mappings became
a library's own, that number always looked healthy: the template rows are there
after any install, and a library that has never taken its own contributes
nothing. It said "mapped" while a shelf could not be looked up.

It counts the **shared template** now, which is the question that page can
actually answer - what a source can be asked about at all.

**Whether a given library has taken them is a fact about that library**, so each
of its platforms now carries what the sources call it. One query for the lot
rather than one per machine: the page already runs several statements and a
column that is usually two words should not add a dozen more.

Full suite: still 1 of 25, unchanged.

This package is **build 198**.

**Mappings are part of a library's structure, and only its own.**

Libraries are separated because access to them is. A mapping - what a metadata
source calls this library's machines - is part of a library's structure, so
taking the shipped ones is now something an owner **ticks**, like the category
trees or the locations, rather than something the installer writes into every
shelf on the instance.

`Metadata platform mappings` is a sync part. It brings in the platforms first,
because a mapping points at one and would otherwise quietly do nothing on a
library with no machines yet. Gaps only, so a mapping somebody corrected by hand
survives every later sync.

## The lookup no longer borrows

Build 196 ordered the fallback so another library's mapping came last. That is
the same leak with better manners: a mapping written on one shelf could still
answer a lookup on another.

Excluded now. A lookup sees this library's own rows, or the shared template - and
the template is not anybody's, it is what every library's copy was made from.
Falling back to it is falling back to the default rather than to a stranger.

A library with neither gets nothing, which is the honest answer and now says so
on the page.

## Where the rows are written

* The **template** pass writes against the shared platforms only, which is what
  it always should have done.
* The **installer** writes each library's own, for the libraries it just made.
* **Adding a source** writes the template and then each library's, the same way
  it already loops libraries for the scopes.
* A **sync** writes one library's, when its owner asks.

Full suite: still 1 of 25, unchanged.

This package is **build 197**.

**Yes, per library - and the fallback was leaking across them.**

`metadata_provider_platforms` is keyed on a platform row, and platforms are per
library: a null `library_id` is the shared copy and every library makes its own.
So a mapping is per library on purpose, and one shelf calling a machine something
unusual stays that shelf's business.

The slug fallback added in build 191 had `LIMIT 1` and **no order**, so it took
whichever row the database happened to offer. A correction somebody made on their
own library could answer a lookup in a different library, silently - which is the
opposite of what per-library mappings are for.

Ordered now: the shared row first, then this library's own, then anyone else's.

* The **shared row** is the honest default when a library has no mapping of its
  own. It is what the copy was made from.
* Another library's stays **last rather than excluded**: a mapping written by
  hand is still better evidence than nothing, and on a fresh install before the
  second seeding pass it may be the only row there is.

An exact mapping still wins outright, so a correction is never talked over by the
fallback that exists to cover its absence.

Full suite: still 1 of 25, unchanged.

This package is **build 196**.

**The miss note reaches the screen, and says what to do.**

Build 193 gave a source a way to explain a miss and put it in the log. The person
looking at "Nothing found" still had nothing - and they are the one who can act
on it.

Collected per source and sent beside the errors rather than among them: a source
that looked properly and found nothing has worked, and dressing that as a failure
would be wrong. An object always, for the same reason `errors` is - an empty PHP
array encodes as `[]` and a populated one as `{}`, and a client that decodes one
cannot decode the other.

The note now ends with the answer:

    their search offered nothing on amiga, and no page at amiga/superfrog-1993
    or amiga/superfrog. If they list it under another name, put its address in
    this entry's reference link.

That last part is build 194's escape hatch, and nobody would have guessed it was
there.

Full suite: still 1 of 25, unchanged.

This package is **build 195**.

**The C64 mapping is right, and that page is a different game.**

`c64` maps to `commodore-64`, which is what their address says. What differs is
the title: **Attack** of the Mutant Camels is Camels I, and **Revenge** of the
Mutant Camels is Camels II. Their search offers the first for the second, and it
scores zero and is refused - correctly. Two games, one family, and a wrong price
is worse than none.

Loosening the match to catch it would price Camels II at Camels I money, which is
the fault that had a lookup for Doom priced against Doom III.

## Settling it by hand

Refusing forever is not an answer either, so: **an entry's reference link is used
when it is one of the source's own addresses on the right console.** Put the
product page in it and the search is skipped entirely.

Only their addresses, and only on the console the entry is on - a link to Lemon
Amiga or MobyGames is ignored rather than fetched, because that field holds
whatever reference somebody found useful.

One decision, recorded once, for the titles no rule can reach.

Full suite: still 1 of 25, unchanged.

This package is **build 194**.

**"0 results" now says why.**

    pricecharting: "Superfrog" gave 0 results (0 images) in 8051ms

That line reads the same whether their search offered nothing on this console,
offered only a different release, or the addresses simply do not exist - and only
the last means the title is not in their catalogue under that name. Three
different situations, one line, nothing to act on.

    pricecharting: "Superfrog" gave 0 results in 8051ms - their search offered
    nothing on amiga, and no page at amiga/superfrog-1993 or amiga/superfrog

A source may now return a third element explaining a miss. Optional: every other
source returns two and is unaffected, and the note is only printed when nothing
was found - what a source walked to reach an answer is noise once it has one.

## Meanwhile, it works

    prices.recorded  PriceCharting: 6 prices for "Jagged Alliance: Deadly Games"

Search, match, parse, record. The path the last dozen builds have been chasing is
closed.

Full suite: still 1 of 25, unchanged.

This package is **build 193**.

**The same fault, in the other place a platform crosses libraries.**

A source binding can be scoped to a platform - "ask OpenRetro about Amiga games,
not about DVDs" - and it matched on the row id. Every library has its own copy of
the shared platforms, so a scope set against the shared Amiga did not apply to an
entry on a library's own Amiga. Same machine, different row, and the rule quietly
did not fire.

That is exactly what made every PriceCharting lookup say "not mapped" on a fresh
install. Found once and then looked for elsewhere rather than waited for.

Matched by slug now, which is what makes two rows the same machine. A different
machine is still a different machine: a scope on PC does not fire for an Amiga
entry.

**Categories are not affected**, and it is worth saying why rather than leaving
it to be re-checked: the ancestry walked there is the entry's own, so it never
leaves the library it belongs to. Only the platform is compared across that
boundary.

Full suite: still 1 of 25, unchanged.

This package is **build 192**.

**The platform was mapped. The entry's platform was a different row.**

Every library gets **its own copy** of the shared platforms - same name, same
slug, its own id. The installer switches sources on before any library exists, so
the first mapping pass covered the shared rows and every copy made afterwards had
none.

On a fresh install that is every entry, because the example library is created
last. The source said 8 platforms mapped, the platform was one of them, and the
lookup still said "not mapped" - because it was asking about a different row for
the same machine.

Resolved by slug when the exact row has no mapping of its own. The slug is what
makes two rows the same machine: a library's copy is made from the shared row and
carries it, which is the rule `metadata_seed_platform_map()` already uses when it
writes them. The exact row still wins where there is one, so a mapping somebody
edited by hand is never talked over.

That fixes an install that has already happened. The installer also maps again
after the libraries exist, so the rows are there to be edited rather than
resolved every time.

Full suite: still 1 of 25, unchanged.

This package is **build 191**.

**The mapping report, laid out like the lines beside it.**

    Metadata sources switched on: 13, the ones needing no key that answered
      PriceCharting: 8 platforms mapped
      skipped MusicBrainz - it did not answer its own probe: HTTP 503

It used `note()`, which wraps its line in blank lines - that is for a standalone
warning, not for a list - so six of them came out double-spaced and at the same
level as the heading they belong under.

The web installer reports them too. It listed what was skipped and not what was
mapped, which is the half that says whether a source can answer anything.

Full suite: still 1 of 25, unchanged.

This package is **build 190**.

**The installer switched sources on and left them unable to answer.**

Adding a source through the API seeds its platform mappings - what it calls each
of this instance's machines. The installer inserted the row and stopped.

So every source that files by console came out of a **fresh install with nothing
mapped**, answered "no platform" at every lookup, and nothing in the install
output suggested a step had been missed. A reinstall did not help, because the
reinstall was where it went wrong.

**Six sources, not one.** Wikidata, Wikimedia Commons, TheGamesDB, IGDB,
OpenRetro and PriceCharting all file by platform and all ship a mapping.
PriceCharting is only where it was noticed - the others degrade quietly, because
a source that also works without a platform just returns worse results.

The installer seeds them now and says how many each got, so a source with none is
visible in the output rather than three lookups later.

## "No platform" when the platform was there

A source is handed a console, never a platform id, so it cannot tell "nobody
named a machine" from "one was named and has no mapping". The message said the
first when the truth was almost always the second - which sent somebody looking
at the lookup rather than at the source's mapping, where the answer was.

The caller knows which it is, so the caller says.

Full suite: still 1 of 25, unchanged.

This package is **build 189**.

**A PC lookup was searching the Amiga section.**

The command line found Doom-1993 and the web found nothing, from the same code -
which meant the fault was in the path around the source rather than in the
source.

`metadata_search()` substitutes a source's own probe console when `$remote` comes
back null. But **null means two opposite things**: nobody named a machine, or
somebody named one and it has no mapping. The first is the install probe. The
second is a real lookup, and putting the probe's console there searched
`/game/amiga/…` for a PC entry - which found nothing, every time, and logged "0
results" like any other honest miss.

The command line never reached it: `--platform=pc` resolves to a console before
the search, so the substitution had nothing to do.

Now it applies only when no platform was asked for at all. A platform that was
named and is not mapped says so.

## And why the mapping was missing

`metadata_seed_platform_map()` runs when a source is created and when the
structure is synced. A source added **before** its mapping shipped never got one,
and nothing said so - the lookup just found nothing.

The sources list reports how many platforms each source has mapped against how
many it ships, so that state is visible rather than inferred from silence.

Full suite: still 1 of 25, unchanged.

This package is **build 188**.

**Two questions were sharing one cached answer.**

    pricecharting: "Doom" answered from cache, 0 results

The key held the title and the platform and **not the year** - so a search for
Doom with 1993 on the shelf answered from one that had no year at all. Different
question, different answer, same key.

Which also means the year rule added in build 185 was never exercised: every
attempt since has come back from a cache written before it existed.

The year is part of the question and is part of the key now. Two years differ,
and no year differs from either.

**Title with the year first, title alone second** - which is what the search
already did, hidden behind that cache. `doom-1993` is asked for before `doom`,
and the bare slug is only reached when the year form is not there.

Full suite: still 1 of 25, unchanged.

This package is **build 187**.

**The price history was being kept and never read.**

`price_history_for()` was written, called by nothing and tested by nothing - so
observations accumulated as rows for the sake of a question no page asked. That
is the whole reason they are rows rather than a column that gets overwritten, and
it had been true only in the comment.

`GET /items/{id}/prices` answers it: every band with a history, oldest first, and
which of them matches this copy so a client can lead with it rather than making
somebody find their own condition in a list of six.

Every band rather than only the matching one - somebody watching a loose price
climb while their own copy is boxed still wants to see it.

Full suite: still 1 of 25, unchanged.

This package is **build 186**.

**`/game/pc-games/doom` is the 2016 reboot.**

An exact slug match scored highest and took it, so a 1993 shelf was priced
against a 2016 release - and nothing about the answer said so. Both pages are
real, both have the right title, and a title alone cannot tell them apart.

**The year on the shelf can.** A slug ending in the entry's own release year now
outranks an exact match:

    doom-1993   110   the release this entry is
    doom        100   the title, and no word on which release
    doom-iii     57   a different game
    doom-2016    30   a year, and not ours - refused

With no year of our own the bare slug is the best signal there is, and scores
highest. With one, it is not enough on its own: the floor rises to the year
match, the search declines, and the fallback asks for `doom-1993` directly -
which is a page that exists and was never being asked for.

The year form is asked first for the same reason. Asking for the bare slug first
found the reboot, and finding it looked like success.

**A year page that does not exist falls back to the bare slug** rather than
giving up, so a title they have never had to disambiguate still works. One extra
request in that case; wrong prices on a shelf cost more.

Full suite: still 1 of 25, unchanged.

This package is **build 185**.

**The lookup tool showed everything except the answer.**

    1. Doom
       for       pc-games
       url       https://www.pricecharting.com/game/pc-games/doom

For a valuation source that is a title and an address - it says the right page
was reached and nothing about whether the six numbers came off it. The same gap
the trace closed one level out, left open one level in.

    prices
      loose            $99.00 1 sale per year · 7 seen
      cib             $272.40 3 sales per year · 17 seen
      new             $545.00 rare · 0 seen
      graded          $599.50 rare · 0 seen
      box_only        $109.30 rare · 0 seen
      manual_only      $68.32 rare · 0 seen

Each band, its price, and how much to believe it: the volume in the source's own
words and the count of sales it was drawn from. A zero is shown rather than
hidden - it is the difference between a number nobody should trust and one nobody
has tested.

## The search itself works

`--platform=pc Doom` reaches `/game/pc-games/doom` and stops there. The bare slug
was right for this title after all; the year form is still tried when it is not.

Full suite: still 1 of 25, unchanged.

This package is **build 184**.

**The prices had nowhere to go.**

The search read six of them and nothing consumed them. Applying a valuation
candidate was refused - it has no fields, and the guard wanted at least one
ticked - and no page had anywhere to put one. The whole path existed except its
two ends.

**Taken as a set, not as six ticks.** "Loose $99" is a fact about a market and
half a market is not half a fact, so this is one yes and the set is recorded.
Stored against the title as a dated observation rather than written onto the
entry: what a copy was worth last year is still there.

**An entry carries what a copy in its state is worth** - matched to its own
completeness rather than offering six numbers, because a loose disc and a boxed
copy are worth very different money and the one that matters is the one on the
shelf. Null when the market does not quote that state; a box with the game and no
manual has no band, and saying nothing is better than saying the wrong number.

Only on the full shape. It is a query per entry, and a list of two hundred would
run two hundred of them for a column nobody is reading.

Full suite: still 1 of 25, unchanged.

This package is **build 183**.

**A near match was still being taken.**

The trace showed the same fetch again: `doom-iii`, for a lookup of Doom. Scoring
had been added and it did not help, because `doom-1993` **is not on that results
page at all** - "Doom" returns two hundred products and the 1993 release is not
among the ones on the wanted console.

So `doom-iii` scored 57, was the best available, and won. The score said "a
different game" and the code took it anyway. That is the fault: a scoring change
that still accepts the top of a bad field has changed nothing.

**Ninety is the floor now** - an exact slug, or the same title with a year.
Everything below is a sequel, a variant, or a longer title containing the word,
and none of those is the thing that was asked about. A shelf with no price is
correct; a shelf priced off Doom III is not.

## The year is what finds it

With the search declining, the direct address is the second chance - and the bare
slug is not enough either, because theirs is `doom-1993`.

The entry's own release year is tried after it. A catalogue recording 1993 for
its copy of Doom knows something their search ranking does not.

It travels in `params` rather than as a fourth argument: an agent is handed a
title and a platform and nothing else, and that contract is shared by fourteen
sources. Changing every signature for the benefit of one would be the wrong
shape.

Two requests at most, and only after the search has failed to find the same
release. A 404 costs a request; a wrong answer costs a price on a shelf.

Full suite: still 1 of 25, unchanged.

This package is **build 182**.

**A lookup for Doom priced Doom III.**

The trace showed it, which is what the trace is for:

    → …/search-products?type=prices&q=Doom
      product links:
        …/game/nes/ninja-gaiden-iii-ancient-ship-of-doom
        …/game/super-nintendo/doom
        …/game/nintendo-64/doom-64
    → …/game/pc-games/doom-iii

Two hundred products across every console, and this took the first one whose
console matched. Their results are not ordered by how well they match, and there
is no reason they should be.

**A wrong price is worse than none**, because nothing about it looks wrong: six
figures, a real page, a title one word off.

Candidates are scored now:

    doom                                   100   exactly it
    doom-1993                               90   the same release, disambiguated
    doom-iii                                57   a different game
    doom-3-resurrection-of-evil             38
    ninja-gaiden-iii-ancient-ship-of-doom   10   contains the word, is not it

A four-digit tail in a plausible range is a **year** - how they disambiguate a
release that shares a name - and a numeral or a word is a **sequel**. That is a
rule about this catalogue's subject matter rather than about strings, and it is
the whole reason `doom-1993` beats `doom-iii`.

**A miss is a miss.** The first version started the best score below zero, so the
first link always beat it and a search for a title they do not have returned
whatever came back first - confidently. Caught by testing a title that does not
exist, which is the case nobody thinks to try.

Language-prefixed links are left alone: `/de/game/…` is the same product in
German, and taking one would price a shelf off a page nobody asked for.

Full suite: still 1 of 25, unchanged.

This package is **build 181**.

**The lookup tool could not make a request.**

    Error: Undefined constant "APP_VERSION"

`metadata.php` builds a User-Agent from it, and `bin/lookup.php` loaded that unit
without `src/version.php`. Every fetch the tool made died on the constant.

It died **inside** the request, which is why it read as the source being broken
rather than the tool being incomplete - and the one path that would have shown it
is the one nobody runs until there is something to debug. The tool has existed
for a while; the trace is what finally made somebody use it against a live
source.

## The check

Which units define which constants, which units read them, and whether a tool
that loads the second also loads the first. `bin/install.php` names its
seventeen units in a list rather than one require each, and that list is read
too.

**The first version reported that installer as broken in three places.** It read
the list from `as $unit` onwards - and the list is *before* that - so a tool
loading everything correctly looked like one loading three units wrongly. The
foreach header is the thing to match.

Tested by taking the require back out and watching it name the file, the unit and
the constant.

Full suite: still 1 of 25, unchanged.

This package is **build 180**.

**`--platform` was ignored unless `--all` was also given.**

    ./bin/lookup.php --trace --source=pricecharting --platform=pc Doom
      PriceCharting files by console; map this platform to one of theirs first.

The flag was read into the options and used by one code path. A single-source run
passed nothing - so a source that files by console refused a lookup from somebody
who had just named the console, and both the flag and the source looked broken.
Neither was.

Resolved on that path now, from the source's own mapping and falling back to the
shipped one, so it works before a source has been configured at all. A platform
that maps to nothing says which one and where to set it, rather than failing as
though none had been given.

**The refusal names what is missing.** "Map this platform first" without saying
which platform is a sentence somebody reads twice - and after a `--platform=pc`
that had been silently dropped, it read as the mapping being absent rather than
the flag never arriving.

Full suite: still 1 of 25, unchanged.

This package is **build 179**.

**A lookup can be watched.**

    ./bin/lookup.php --trace --source=pricecharting --platform=pc Doom

    → https://www.pricecharting.com/search-products?type=prices&q=Doom
      ← 344kB in 412ms
      canonical: https://www.pricecharting.com/search-products?q=Doom
      title: Search results | PriceCharting
      link paths: /console ×64, /game ×2, /market ×1
      product links:
        /game/pc-games/doom-1993

"0 results" is three different failures wearing one face: it may not have
fetched, it may have fetched and been refused, or it may have fetched something
perfectly good and had the parser miss it. From outside they look identical.

So this prints the URL, the size, where the page says it is, **the shape of its
links**, and the first few that look like products. A parser matching
`/game/{console}/` against a page whose links are written some other way is one
line here and invisible everywhere else.

The trace is a closure the request path calls when somebody is watching, so
nothing in it has to know what a terminal is.

## The metadata log could not be read

Entries were filed as `metadata` correctly, and the viewer asking for that
channel got nothing - because the query turned anything that was not `security`
or `server` into `server`. Asking for the metadata stream searched the server
one.

`log_channels()` already exists and already lists all three. The comment on it
describes this exact fault being fixed **on the writing side** - and it was left
on the reading side, which is the half nobody checks when a tab shows zero.

One list now, read by both.

Full suite: still 1 of 25, unchanged.

This package is **build 178**.

**A search can ask one sort of source.**

`?kind=details` asks the sources that say what a release is; `?kind=prices` asks
the ones that say what a copy is worth. Absent asks both, which is what every
caller did before.

A source's own `kind` decides which list it is in, and a source that does not
declare one is details - every source that predates the distinction says what a
release is.

**A bad value is refused, not ignored.** A typo silently becoming "ask
everything" is how somebody ends up with prices in a details list and no idea
why.

## The item says whether it can be valued

`can_value` on an entry, true when an enabled source answers that question -
computed from the sources rather than from a name kept in a client, so a second
price source added later lights the button without anything else being touched.

Answered once per request rather than per row: the question is about the
instance, and a list of two hundred entries would otherwise ask it two hundred
times.

Full suite: still 1 of 25, unchanged.

This package is **build 177**.

**A search that found nothing was cached for a week.**

    pricecharting: "Doom" answered from cache, 0 results

Which is why the last fix looked like it had not worked. A search that finds
something is a fact about their catalogue and worth keeping for a week; a search
that finds nothing is usually about *us* - a parser matching the wrong thing, a
mapping not set - and cached that long it makes every fix invisible.

**An hour for an empty answer**, a week for a real one. Still cached, because a
title that genuinely is not there should not be fetched on every keystroke.

And a way to not wait the hour: an administrator can clear what a source has
answered, which is what somebody debugging a mapping actually wants. Cleared by
source *type* rather than by row, because the cache is keyed on what a source is
and two rows of one type share it.

Full suite: still 1 of 25, unchanged.

This package is **build 176**.

**Every PriceCharting search returned zero.**

    pricecharting: "Doom" gave 0 results in 654ms
    pricecharting: "Maniac Mansion" gave 0 results in 1724ms

No error, a real fetch, a real answer read - and nothing found in it. The link
matcher asked for `href="/game/{console}/..."` and their pages write links **in
full**: the product page's own canonical link is
`https://www.pricecharting.com/game/amiga/maniac-mansion`, so a results page
doing the same matched nothing at all.

Absolute and relative both now. A query string on the end no longer breaks the
match either - the pattern required a closing quote straight after the path, so a
tracking parameter would have produced the same silent zero.

## A second guess that fails differently

When the search finds nothing usable, the direct address is tried:
`/game/{console}/{slug}`, the title lowercased and hyphenated.

Searching is the right way round - it finds `doom-1993`, which no rule derives
from "Doom" - but it depends on their results markup, which is undocumented and
has now been guessed at wrongly once. The direct address is a guess too, and a
different one: for a title they have not disambiguated it is exactly right, and
Maniac Mansion on Amiga is the proof.

Two guesses that fail differently are better than one, and a 404 on the second
costs a request rather than a wrong answer.

Full suite: still 1 of 25, unchanged.

This package is **build 175**.

**An entry's cover carries its full-size URL.**

`cover` had `thumb` and `display` and no way to reach the original, so a client
letting somebody look at a photograph properly had to enlarge the display copy -
a bigger blurry version rather than more of the picture.

`original` is null for a stock or category picture rather than a URL. Those ship
at display size and have no larger version, so an `orig` address for one is a
404: saying "there is no more of this" is better than offering a link that
breaks.

Found while making the web client's cover clickable - the fallback would have
used `display` every time and looked like it worked.

Full suite: still 1 of 25, unchanged.

This package is **build 174**.

**PriceCharting was listed and could not answer anything.**

Two faults, and each looked like the other.

**No platform map.** `structure/metadata_agents.json` is where a source's console
names live, and this one was not in it - so every lookup stopped at "map this
platform to one of theirs first", the same message the install probe gave.
Fifteen platforms and no mapping for any of them.

**A URL built from the title.** `/game/{console}/{slug}`, with the slug derived
by lowercasing and hyphenating. That is right for Maniac Mansion and wrong for
anything they have had to disambiguate: **Doom on PC is
`/game/pc-games/doom-1993`**, and no rule derives that year from the title.

It asks them now. `/search-products?type=prices&q=...` is the form on their own
page, and the results are filtered to the wanted console before one is taken -
searching "Doom" returns the Jaguar release, the 32X one and a dozen more, and
taking the first would price an Amiga shelf at Jaguar money. A search that
redirects straight to a product is recognised by its canonical link rather than
fetched twice.

## Their names, not ours

    pc         -> pc-games
    c64        -> commodore-64
    amiga      -> amiga
    mega-drive -> pal-sega-mega-drive

`pc-games` rather than `pc` is the pair that proves this was read rather than
assumed: a guess would have 404ed on every PC lookup and looked like a source
with no PC coverage.

The Sega entries are the **PAL** ones, because a shelf in Europe holds PAL copies
and the two markets price differently. Somebody with NTSC copies should change
them rather than have them quietly mean the wrong region.

CDTV and every video and audio platform are **deliberately absent**. They do not
file those, and a mapping to a console that does not exist is a 404 on every
lookup rather than an honest "not covered".

## The empty Covers column

`default_for_kinds` was an empty list, which is why the sources page showed a
dash - the same reason Wikidata shows one. Games, machines and peripherals now:
they price hardware the same way they price software, which is unusual among
these sources. Not applications, films or records, because claiming those would
put this source in front of lookups it can only fail.

Full suite: still 1 of 25, unchanged.

This package is **build 173**.

**PriceCharting was skipped on every install, on a source that works.**

    skipped PriceCharting - it did not answer its own probe:
      PriceCharting files by console; map this platform to one of theirs first.

The message was right and the situation was ours. The install probe runs before
any provider row exists, so there is nothing for `remote_platform_for()` to map a
platform id against - and this source cannot search without a console, because
its URLs are `/game/{console}/{slug}`.

A definition can name a **probe platform** now, used only when the caller has
none to give. PriceCharting names `amiga`, which with Maniac Mansion is a page
that exists and has prices on it - which is what a probe needs to prove. A real
lookup that has mapped a platform keeps its own, and no other source declares
one.

## A fatal that would have followed

`metadata.php` calls the price parsers, and **both loaders pull metadata.php in
before prices.php** - so the first lookup during an install would have died on an
undefined function, one step past the probe that was failing first.

Found by running the search rather than by reading it. metadata.php requires the
parsers itself now, and both loaders use `require_once` so naming a unit twice is
not a redeclaration.

MusicBrainz's 503 in the same run is theirs, and reported as such.

Full suite: still 1 of 25, unchanged.

This package is **build 172**.

**PriceCharting is switchable from the answer file, and needs no key.**

    "metadata": { "agents": { "pricecharting": { "enable": true } } }

The API token is gone from the definition. Their pages answer a plain cURL fetch
with a proper User-Agent - checked against the live page, not assumed - so the
paid path is not the only path, and asking for a token that nothing reads was a
requirement invented rather than found.

`metadata_search_pricecharting()` is written. Their product pages are addressable
- `/game/{console}/{slug}` - so this fetches by URL rather than scraping a search
page. The slug is the title lowercased and hyphenated, which is a guess at their
scheme rather than a documented rule: a miss is a 404 and reported as one.

One candidate or none. This source does not answer "which release is this", so
offering a list to choose from would invite a decision there is nothing to
decide. The six prices ride under `prices`, where nothing walking a candidate's
fields can mistake one for a fact about the release.

## Off unless somebody says so

`needs_key` is what usually makes a source opt-in, and this one needs no key. It
is still off by default, for a different reason: **their terms sell access to
what these pages give away**, and that decision belongs to whoever runs the
instance rather than to a default in this file.

`opt_in` is the flag. It behaves exactly like `needs_key` in both the writer and
the install step - named in the answer file or not switched on, whatever
`install.metadata_sources` says.

Tested end to end: a file naming it is accepted, reads back, and switches on that
source and no other; a file that never mentions it does not switch it on even
with the general default set.

Full suite: still 1 of 25, unchanged.

This package is **build 171**.

**The whole product page reads.**

    loose        $99.00    1 sale per year    7 sales
    cib          $272.40   3 sales per year   17 sales
    new          $545.00   rare               0 sales
    graded       $599.50   rare               0 sales
    box_only     $109.30   rare               0 sales
    manual_only  $68.32    rare               0 sales
    PriceCharting ID: 67001

Prices, the volume phrase and the completed-sale count for all six bands, plus
the id so a later fetch finds the same page without guessing at a title.

**Volume is kept in the source's own words** - "1 sale per year", "rare" - rather
than turned into a number. Normalising "rare" would invent precision they did not
offer, and the phrase is the honest thing to put beside a price.

**A zero count is kept**, and it is the most useful thing on the page: it says a
price came from something other than sales of this exact thing, which is the
difference between a number nobody should trust and one nobody has tested.

Both are keyed on the tab name - `completed-auctions-used`, `box-only` with a
hyphen where the price cell has an underscore - rather than on position. The page
repeats the last three cells in a second block for narrow screens, so anything
walking the row in order reads three of the six twice. The counts come from the
"All Sold Listings" select rather than the tabs, because the tabs hide some at
narrow widths and a hidden band still has a count.

## The fixture, and what it does not prove

`tests/fixtures/pricecharting-maniac-mansion.html` is a trimmed copy of the page
as served, kept verbatim. Written from memory it would reproduce whatever the
writer expected - and the expectation here was wrong twice already, about which
number in a cell is the price and about what `box_only` means.

**On the page as served the price comes first**, so a parser with neither the
sign rule nor the zero rule reads it correctly by luck. That was checked by
removing both rules and watching the fixture pass anyway.

Those rules are tested separately against orderings the fixture does not contain,
and removing them fails that check. Two checks that overlap is better than one
covering less than its name claims.

Full suite: still 1 of 25, unchanged.

This package is **build 170**.

**The numbers on that page are not the prices.**

The markup came back with six cells carrying stable ids - `used_price`,
`complete_price`, `new_price`, `graded_price`, `box_only_price`,
`manual_only_price`, in a table called `price_data`. Ids rather than layout
classes, which is a firmer thing to parse against than the list page offered.

The values a crude read finds are **$0.00, $0.86, $2.00, $2.20, $34.92, $21.82**.
The prices on the same page are **$99.00, $272.40, $545.00, $599.50, $109.30,
$68.32**. Each cell holds two spans - the price and the change since last time -
and the change is the one a first parser finds.

Six plausible wrong numbers per title, on every title, and invisible by
inspection: $0.86 looks exactly like a price. The only one that would have raised
an eyebrow is $0.00 against a loose Amiga game.

Two rules tell them apart without depending on which span nests inside which:
a leading minus disqualifies, because a change can be negative and a price never
is; and zero disqualifies, which catches both a change of nothing and a band
nobody has sold in. Tested against both nesting orders and against a change that
comes first unsigned - the case the sign rule alone would miss.

## A band that would have been priced wrong

The table had `boxed_no_manual` as a band. The market quotes **`box_only`**,
which is a box with *nothing in it*. A box with the game and no manual is a
different object and most of the value, so matching them would have priced a
playable boxed copy at what a spare box fetches.

`boxed_no_manual` now has no band at all. Its real price sits between `loose` and
`cib` and neither is it, and a page that says nothing is better than one that
says the wrong number confidently.

The bands are the market's six now, read from their ids rather than translated
from this catalogue's vocabulary. Three match a state a shelf can be in; `new`,
`graded` and `box_only` do not, and are stored anyway - somebody pricing a spare
box should see what spare boxes fetch.

Full suite: still 1 of 25, unchanged.

This package is **build 169**.

**The prices are in the HTML.**

    curl -sS -A 'RetroHive/x (+...)' .../game/amiga/maniac-mansion | grep -c 'used_price'
    1

That settles what the first scraper raised: its headless Chrome was that author's
choice, not something the site forces. A plain cURL fetch with a proper
User-Agent comes back with the page, so this can be an ordinary agent - the same
shape as every other source here, no browser to install on the server.

## The half that does not need the markup

`src/prices.php`, which is everything the parser will hand its results to:

**A band for every state a shelf records.** `cib`, `boxed_no_manual`, `loose` and
`manual_only` map straight across; `digital` and `unknown` deliberately map to
nothing. A download has no second-hand market, and putting a number against an
entry that has not said what it is would be inventing one. Tested against the
schema's own enum, so a seventh state cannot be added without this failing.

**Sealed and graded are stored and never matched.** They exist in a market and
not on a shelf - an entry cannot be sealed and say so - but somebody pricing a
sealed copy should still see what sealed copies fetch.

**A blank is not a zero.** Their pages show nothing for a band nobody has sold
in, and zero would read as "worthless" where the truth is "no sales". Those are
opposite answers, so a zero is skipped rather than stored.

**Writing is idempotent.** The unique key is source, title, platform, band and
the date the price was *true* - so importing a dated series twice writes it once,
and two imports racing settle on the key rather than on who read first.

The insert was checked against the table column by column: names, placeholders
and every NOT NULL without a default. There is no database here to run it
against, which is exactly why that check exists - and it caught `query()` for
`q()` before it ever ran.

## What is still needed

The markup around those prices, from the server. Guessing it from a screenshot is
how a parser gets written against markup nobody has seen - and the class names
from the *list* page may not be what the per-game page uses. Two commands are in
`docs/PRICING.md`.

Full suite: still 1 of 25, unchanged.

This package is **build 168**.

**The second scraper says the first one's browser may not be needed.**

`phantomeralphay/pricecharting-product-details-scraper` reads the per-game page
rather than the console list, and its documented output changes three
conclusions.

**It mentions no browser.** Its stated requirements are retries and proxy
support - the vocabulary of an HTTP client meeting rate limits, not of a page
that cannot be read without JavaScript. If accurate, the first scraper's Chrome
was one author's choice rather than a hard requirement.

**There is a comparison endpoint** - `/compare?uids=R3560883&conditions=1` -
returning dated points per condition, prices in cents as integers. A structured
series is a far better thing to read than a rendered table, and it means a first
fetch can **backfill months of history** rather than accumulating one row a month
from now on. `price_observations` already dates a row by when the price was true
rather than when it was fetched, so that import is idempotent without a change.

**The completed sales are itemised** - each eBay sale behind a price with its
date, title, amount and platform. That is the listing count in the screenshot,
with the sales attached rather than counted.

**None of it is verified.** It is a README from a repository that is largely an
advertisement for a scraping agency, and their site is not reachable from where
this was written. The claims may be accurate, aspirational, or describing a page
that has since changed.

## The experiment, written down so it is not reinvented

Two cURL commands, in `docs/PRICING.md`: fetch the game page and count
`used_price` in the response, then fetch the comparison endpoint. Prices in the
HTML means a plain agent is enough and this is a normal source. Nothing there
means the browser is real. A 403 is the site declining, which is an answer too.

Ten minutes from a machine that can reach them, rather than a project.

Full suite: still 1 of 25, unchanged.

This package is **build 167**.

**What the community scrapers show about PriceCharting.**

`markfoster314/Pricecharting-Scraper` was worth reading, and what it shows is not
encouraging.

**It drives a real Google Chrome through Selenium.** Not for convenience: a
scraper needs a headless browser rather than an HTTP request when plain requests
do not come back with the content. Either the table is rendered by JavaScript or
the site refuses clients that do not look like browsers - and both are the site
saying no in the way sites say it.

This engine fetches with cURL. Every agent here is a request and a parse; one
needing Chrome installed on the server is not another agent, it is a second kind
of thing to deploy, patch and watch break on every markup change.

**It also reads a different page.** It scrapes `/console/{name}` - the list of
every title on a platform - and takes three columns from it: `td.used_price`,
`td.cib_price`, `td.new_price`, out of `#games_table`. The per-game page has six
prices, the volume line and the sold-listing counts, and none of that is in the
list table. So the example gets half of what made this worth having.

Those class names are recorded in `docs/PRICING.md` because they were read rather
than guessed. The per-game page's are not: guessing a parser from a screenshot
would be inventing markup nobody has seen.

## Three options, written down rather than chosen

**Pay for the API** - a token, a request, a JSON parse, which is what every other
agent already is and what the existing `needs_key` machinery covers.
**Scrape with a browser** - works until a class name changes or the check that
made Chrome necessary tightens, and has to be squared with terms that sell the
thing being taken.
**Neither yet** - the table, the bands and the reasoning are in place for whenever
one of the two is decided.

Their site is not reachable from where this was written, so their terms have not
been read. What is clear from the scraper is that the site behaves like one that
does not want to be read by scripts, which is worth weighing before building
around it.

Full suite: still 1 of 25, unchanged.

This package is **build 166**.

**PriceCharting, declared and not yet built.**

It answers a question none of the other sources do - what a copy is worth rather
than what it is - and the answer does not fit the shape the others return. Six
prices per title, by condition: loose, complete, sealed, graded, box only, manual
only, each with how often one changes hands.

**The bands line up with `completeness`**, which entries already record. That is
the whole reason this is worth doing properly: a loose disc and a boxed copy of
Maniac Mansion fetch $99 and $272, and a catalogue storing one number for "Maniac
Mansion" is answering a question nobody asked.

`price_observations` is the table, migration 016 and in `schema.sql` for a fresh
install. Its own table rather than columns on `items`, because a price is a fact
about the market at a moment and not a property of the object - and history is
kept, because "what has this been worth over time" is what a collector actually
asks and an overwritten number cannot answer it.

Volume is stored beside every price. A price with no volume is a guess wearing a
decimal point: "1 sale per year" and "rare" say more about whether a number means
anything than the number does.

**The fetch is not written**, and the source says so - `metadata_search()` answers
"No implementation for provider type" and the installer skips it rather than
probing something that cannot answer. A source announcing itself and doing
nothing is worse than one that admits it is unfinished.

`docs/PRICING.md` has the reasoning, the three options for where six numbers go
and why the third is right, and the one question that is not mine: their API is
sold with a token and the pages are public, and reading pages a site sells access
to is a licensing decision for whoever runs the instance.

Full suite: still 1 of 25, unchanged.

This package is **build 165**.

**Wikidata timed out on an endpoint that answers a browser at once.**

Every request is preceded by a HEAD, to see where a redirect leads before
following one. That check sent **no User-Agent**.

Wikimedia's policy is explicit that a client giving none is throttled or refused,
and the request that would have identified itself properly never happened - the
preflight was still waiting. The install reported "Operation timed out after
15002 milliseconds" against a service that was working.

The check now sends the same agent the request does: the version, and the
instance's own address as a way to reach whoever is running it. That was already
built and already correct; it was being used in one of the two places that needed
it.

**The preflight also had the whole timeout.** Both it and the request were given
fifteen seconds, so a slow endpoint could spend fifteen deciding it does not
redirect and fifteen more answering. It gets a third now, and at least five - a
HEAD to a healthy endpoint is fast, and one that needs longer is telling us
something.

Browsing to the site works because that is the website. The lookup asks
`query.wikidata.org/sparql`, which is a different service with different manners.

Full suite: still 1 of 25, unchanged.

This package is **build 164**.

**Every keyed source was probed with an empty key.**

An install with all five credentials filled in reported "TheGamesDB: no API key
configured", and the same for TMDB, TheTVDB and IGDB - on a file that had them.

`$params = ($def['params'] ?? []) + $given;`

Every provider declares its credential fields in `params` with an empty
default - `'api_key' => ''` - and PHP's union operator keeps the **left** side
where a key exists in both. So the blank default won over the real key every
time, and each source was probed with nothing and reported as unconfigured.

`array_merge` takes the right side, which is the one that was given.

## A source can need something that is not a credential

MusicBrainz needs no account and cannot run without a contact address: their own
terms require a real one in every request. It lived in `params`, which an answer
file had no way to reach - so it was switched on unconditionally and failed its
own probe on every install, with a sentence nobody had been given a way to act
on.

The answer file offers it now, and a source whose requirement is blank is
**skipped with the reason** rather than switched on and left to fail.

**Named by the source, not inferred from a blank default.** TheTVDB's `pin` and
TheRetroWeb's `manufacturers` are blank too and genuinely optional - TheTVDB's
own documentation says an unwanted pin should be left out rather than sent
empty - so "blank means required" would have skipped two sources that work
perfectly. `metadata.php` declares what a source cannot do without; the installer
reads that.

Anything else a source declares is still accepted, for somebody pointing one at a
mirror.

Full suite: still 1 of 25, unchanged.

This package is **build 163**.

**Three docblocks stacked on one function, two of them wrong.**

`installer_enable_metadata_sources()` carried its original block, then one
describing a `$credentials` parameter it no longer takes, then the current one -
each added by inserting a signature above the last without removing what
described the old one. A docblock immediately above another documents the comment
rather than any code, and the stale ones claimed parameters that had gone.

The same had happened to `answers_export_json()`, which was documented as writing
its own `_help` keys - the behaviour removed in build 161 - while the block
actually attached to it described something else entirely.

Both collapsed to one block each, saying what the functions now take.

A check reports a one-line docblock directly above another, which is the shape a
stale one leaves. **Scoped to the installer**: eight more exist across the engine -
`auth.php` carries the same sentence twice - and every one predates this. Fixing
those is a tidy-up worth doing on its own rather than folded into an unrelated
change, and a check failing on eight things nobody is fixing is one that gets
ignored.

Full suite: still 1 of 25, unchanged.

This package is **build 162**.

**The response file holds settings and nothing else.**

It carried a `_help` array in every section and on every one of the thirteen
sources - fifteen blocks of prose the parser was required to ignore, in the one
artifact that is read by a machine. The reasoning was that JSON has no comments
and the guidance the INI file held was worth keeping. It was worth keeping; it was
not worth keeping *there*.

`--example` writes the file to standard output and what the settings mean to
standard error, so:

    php bin/install.php --example > install.json

gives a file a machine can read and a terminal that explains it. Two streams, each
carrying what it is for.

The guidance is better for having room: it lists every source with its homepage
and what its credential fields are called, which the per-source help blocks only
managed one line at a time.

The wizard says the same beside its download button, and `docs/INSTALL.md` - which
still described an INI file called `.rsp` - now describes what the installer
actually writes.

**A file with `_help` in it still loads.** Underscore keys are ignored on the way
in, because files written by the build that wrote them exist.

The example is half the size and all of it configuration.

Full suite: still 1 of 25, unchanged.

This package is **build 161**.

**An answer file the installer wrote, refused by the installer.**

Every source in it came back as "No metadata source called wikidata", and so on
for all thirteen - on a file `--example` had produced minutes earlier.

The check reads the provider definitions, which are loaded with the rest of the
engine. `bin/install.php` reads the answers **first**, to find out whether it can
proceed at all, and boots afterwards - so the check ran with no definitions and
`function_exists()` was false. Every source was unknown because nothing was
known.

**Not checkable is not the same as wrong.** With the definitions absent the
values are carried through untouched, and the check happens where they are used:
`installer_enable_metadata_sources()` runs after the boot and knows every source,
so a real typo is still reported - one step later, as something that could not be
switched on rather than a file that could not be read.

The wizard was unaffected. It loads the engine before it reads anything, which is
why this only ever appeared on the command line.

Full suite: still 1 of 25, unchanged.

This package is **build 160**.

**RetroVault is gone from the tree.**

Build 158 argued the opposite - that the bundle identifier, the package, the
keychain service and the installer's environment variables were addresses rather
than names, and that moving them was a migration with a compatibility window
rather than a rename. That reasoning was right about what a migration costs and
wrong about whether one was needed: this instance is redeployed from scratch, so
there is nothing on the far side of the window to be compatible with.

Everything now carries the one name:

* `se.retrohive.app` and `nu.noh.retrohive` - the bundle identifier and the
  Android package, and the `nu.noh.retrohive.ui.Icon*` launcher aliases with them.
* `se.retrohive.token`, and the Android preferences and token store.
* `RETROHIVE_DB_PASS` and `RETROHIVE_ADMIN_PASS`.
* The iOS sources, the entitlements, the app file and the SPM target.

**A deployment carrying the old environment variables will install with no
password.** That is the compatibility window the previous build was protecting,
deliberately given up: nothing reads `RETROVAULT_DB_PASS` any more, and an
install that relied on it stops rather than proceeding with a blank.

`docs/NAMING.md` is deleted. It existed to explain why the old name was still
here, and it is not.

Full suite: still 1 of 25, unchanged.

This package is **build 159**.

**The answer file is JSON, as a tree.**

    "metadata": {
      "agents": {
        "theaudiodb": {
          "_help": ["TheAudioDB - needs an account - https://www.theaudiodb.com/",
                    "api_key: API key (123 for the free test key)."],
          "enable": true,
          "api_key": "123"
        }
      }
    }

A tree rather than a flat list of dotted keys, because that is what the thing is:
sections, and under metadata, one object per source with its own settings in it.

## INI is still read

Files written by an earlier version exist, and a provisioning tool that templates
one should not break on an upgrade. The format is chosen by what the file looks
like rather than by what it is called - the wizard takes an upload and a
provisioning tool pipes to standard input, and neither has a filename worth
trusting.

Both go through **one** check for the metadata agents, so "igdb has no setting
called client_di" is the same answer whichever way the file was written. Two
copies of that check is one that gets fixed and one that does not.

## JSON has no comments

The INI file's were doing real work: somebody opening it is about to choose
between three words for `deploy`, and a credential field called `api_key` does
not say "API Read Access Token" - which is what TMDB wants and the only thing it
will accept.

They are kept as `_help` keys, which the parser ignores. An explanation that
survives as data is better than one dropped because the format has no place for
it.

## Named errors

`metadata.sources` is refused with "the sources go under agents" rather than as an
unknown section - a wrong guess at the nesting is the mistake this shape invites,
and the answer should say where the thing actually goes.

Full suite: still 1 of 25, unchanged.

This package is **build 157**.

**Every lookup source is switched on individually.**

`metadata_sources = 1` was one flag for eight sources: all the ones needing no
account, or none of them. The answer file now lists every source, free and keyed
alike:

    ; Wikipedia - https://en.wikipedia.org/
    wikipedia.enable = true

    ; IGDB - needs an account - https://api-docs.igdb.com/#getting-started
    igdb.enable = true
    ; Client ID
    igdb.client_id = ...
    ; Client secret
    igdb.api_key = ...

Written from the provider definitions, so a source added later appears with its
own name, its own fields and its own homepage.

## The old flag still means something

`metadata_sources` is the **default for a source [metadata] does not name**,
rather than a gate in front of it - an answer file with no [metadata] section
behaves exactly as before, and one that switches the general flag off and names a
single source gets that source. Gating would have dropped it.

**A keyed source falls back to off**, not to that default. "Switch on the lookup
sources" has always meant the ones needing no account, and reading it as "all of
them" would report four failures on every install that never mentioned them.

## Credentials with no flag count as yes

Somebody who has pasted an API key has said what they want as plainly as a flag
would. Making them write a second line to mean it is a trap that fails silently,
and a silent nothing is the worst answer an installer can give. An explicit
`enable = false` still wins.

**A source asked for and not given its credentials is reported** - by flag or by
half a pair. One that was never mentioned stays silent, because then it is simply
one this instance does not use.

Full suite: still 1 of 25, unchanged.

This package is **build 156**.

**Metadata sources with credentials can be configured at install time.**

The keyed sources - TheGamesDB, TMDB, TheTVDB, TheAudioDB and IGDB - were left
out of an unattended install and added by hand afterwards. The answer file has a
`[metadata]` section now: give a source its credentials and it is switched on
with the free ones.

**Written from the provider definitions**, not from a copy of them. A source
added to `metadata.php` appears in the next answer file with its own field names,
its own labels and its own homepage - which is the only way a template stays
right. IGDB's two fields come out as two lines because IGDB declares two.

**A blank is not a failure.** A source with no credentials is skipped silently:
that is "I do not have an account for this", not something that went wrong. Half
a credential pair *is* reported - a source with a client id and no secret fails on
its first lookup, which is a worse place to find out than during the install.

**Keyed sources are probed like the free ones**, with their credentials in hand,
so a wrong key is reported while somebody is still watching rather than months
later by a lookup that half works.

## The parser still refuses a typo

`[metadata]` accepts keys the schema cannot list, since the providers are declared
elsewhere - so they are checked against the definitions instead. `igdb.client_di`
is refused by name, and so is a source that does not exist.

Full suite: still 1 of 25, unchanged.

This package is **build 155**.

**Uploading a photograph returned 500. `$item` was never assigned.**

`api_item_images_upload()` passed `$item` to `api_hold_new_images()`, which is
typed `array` - and nothing in the function ever set it. PHP made it null, and
the TypeError fired at the moment the typed parameter refused it.

    api_hold_new_images(): Argument #1 ($item) must be of type array, null given

The entry is loaded now. Not taken from the guard above it, which already reads
the row and throws it away: that returns a library id and one of its three
callers uses it as one, so widening the return type to fix this would change a
signature to suit a single call site.

An entry deleted between the guard and this line is a 404 rather than a crash -
which is what the missing assignment was, once the picture had already been
stored.

## Why nothing caught it

The variable is read once and written nowhere, which PHP does not consider an
error. It fails only where a type declaration refuses the null - so the same bug
one line earlier, into an untyped parameter, would have been a silent no-op
instead.

The base64 path reached the same line and had presumably been the one exercised;
the multipart path is what a phone uses, and this was the first phone.

I looked for the same shape across the engine afterwards. Seventy-eight
candidates, every one of them a closure parameter, a sort callback or a
by-reference out - which is to say the scan cannot tell them apart and is not
worth keeping. What is kept is a check that this function loads the entry before
using it, and that both upload paths reach one hold.

Full suite: still 1 of 25, unchanged.

This package is **build 154**.

**The last three packaging templates have something made from them.**

`laserdisc-case`, `dvd-case` and `cassette-case` shipped and nothing used them. A
template that exists and is demonstrated by nothing is a screen somebody has to
guess the purpose of - so a fresh install now has nineteen examples covering
every template it ships.

- **The Long Quiet** on LaserDisc, and **Harbour Lights** on DVD, both from
  Silverreel Pictures - the same studio and director as the Blu-ray example, so
  the video side shows a studio with a body of work rather than one film each.
- **Tape Hiss Lullabies** on cassette, from a different label to the other two.
  Two releases on one label read as "this is where a label goes"; three across two
  labels read as a field that varies.

## A trap worth naming

The loop skips an example whose title is already on the shelf, which is what
makes a re-run safe. So a second copy of an existing title would be **silently
skipped** - and the template it was added for would still have nothing made from
it, with no error to say so.

My first draft did exactly that: a second "Metropolis Nights" on LaserDisc. A
check now confirms no two examples share a title.

## Two checks that failed on unrelated growth

The unused-template check carried an exception list naming those three. It is
empty now, so the exception is gone rather than kept as a comment about history.

And a check reading "the first 4000 characters of the video seeder" reported that
video had stopped using `seed_company_for_name()` - because the function grew.
A check with a magic length in it fails on things that are not about it. It reads
the whole function now.

That is three brittle assertions in three rounds. The pattern is the same each
time: a check pinned to a count or a length rather than to the property it cares
about.

Full suite: still 1 of 25, unchanged.

This package is **build 153**.

**The video and music examples did not know models existed.**

Software examples name a packaging template. Hardware examples name a machine
model. The video and audio ones named neither - so seven of the twelve shipped
packaging templates had nothing made from them, and half the example set
demonstrated the feature while the other half quietly did not.

A Blu-ray case, a VHS clamshell, a CD jewel case and a vinyl sleeve all ship, and
the four examples are on exactly those platforms. They name them now, store
`software_model_id` on the title, and carry the fields the template declares -
Running time, Region code, Speed, Size.

## Three templates still have no example, and that is recorded

`laserdisc-case`, `dvd-case` and `cassette-case` are for platforms with no
example at all. That is a different gap: an example needs a platform, a category
and a plausible title, not just a template.

The check names those three rather than asserting "nothing is unused" - an
exception written down is one somebody can disagree with later, and a list that
quietly passes is one nobody rereads.

## A check that broke on the right thing happening

The previous round asserted that exactly two places blank a missing default. Four
do now, and it failed - on precisely the change it should have welcomed. It
counts field readers and requires all of them to blank, rather than counting to a
number that was true on the day it was written.

Full suite: still 1 of 25, unchanged.

This package is **build 152**.

**The developer lookups did resolve. What they did on a miss was wrong.**

Every company the software examples name - Team17, id Software, JAM Productions,
Apogee, Sir-Tech, Llamasoft, Electronic Arts - is in `game_developers.json` and
resolves on a full install. The question was worth asking anyway, because the
*shape* of the lookup was wrong in two ways.

**The three example sets disagreed with each other.** Video and music have always
used `seed_company_for_name()`, which finds or creates. Software matched by name
and gave up, on the stated reasoning that an example should never invent a
studio - a rule only one of the three followed.

**A silent null is the wrong failure.** An example whose developer did not
resolve became a release nobody made, which is not something a catalogue should
demonstrate. On a full install this changes nothing; on a partial one - companies
not seeded - it is the difference between an entry with its maker and an entry
with a blank.

## software_developers.json was empty

Not a bug on its own - the file exists so an application house can be told apart
from a games one, and the importer defaults its rows to `domain: software` rather
than `game`. It had no rows to default.

Three now: Gold Disk, Digita International and NewTek - the Amiga's serious
software houses, which is what the file is for.

**Only the fields the importer writes.** A first draft carried `notes`, which is
read for a company from other feeds and never for a developer - a key that looks
like data, is parsed, and is discarded. A check now rejects any field the writer
would silently drop.

## Electronic Arts publishes an application

Deluxe Paint IV is the application example and EA was tagged `game`. It is
`both`, which the importer already accepts and nothing was using.

Fourteen checks confirm every named company ships, all three seeders use the same
find-or-create, and no call site still expects the old return shape.

Full suite: still 1 of 25, unchanged.

This package is **build 151**.

**A seeded example named its model and had none of the model's fields.**

The Amiga 2000 example pointed at the Amiga 2000 model, and its Specifications
were empty. De-selecting the model and picking the same one again filled them
in - which is the tell: **the web form applies a model's fields in the browser
the moment somebody picks one**, and the seeder never did the equivalent.

So the one place a new instance shows what models are for was the one place they
did nothing.

## Both halves had it

A hardware model declares Processor, Memory, Expansion, Storage; a packaging
model declares Minimum memory, Copy protection, Sound support. Neither was
carried onto the examples made from them. Both are now.

**A field with no default is still offered, empty.** The label is the model
saying *this is worth recording about this kind of thing* - a serial number
differs unit to unit and the label is the useful half. Filling in a plausible
answer would be the installer making claims about somebody's copy.

## One bug this nearly introduced

`item_hardware` was only written when a machine had a board revision, so an
Amiga 2000 - which has none - got no hardware row at all, and the specs would
have had nowhere to go. The row is written when there is either.

Twelve checks now confirm both seeders read the right table, write the right
column, and that every column they name exists in the schema. Two of those
assertions are about column names, which is where the last mistake of this kind
came from.

Full suite: still 1 of 25, unchanged.

This package is **build 150**.

**Every example entry is made from a model, and now says so.**

Both halves were already linked - a hardware example stores `model_id`, a
software example stores `software_model_id` on its title. What was missing is
that only one of them was visible.

## The software link was invisible

`titles.software_model_id` has existed throughout and `v_items` never carried it.
So an Amiga 2000 showed the model it came from, and Blake Stone did not show that
it came from "PC DOS, big box, floppy" - which made the packaging templates look
like something only machines use, when in fact most entries come from one.

The view carries it now and the API reports it as `software_model`. Migration 015
replaces the view on an existing instance.

**The migration is copied from schema.sql rather than retyped.** Writing it out
by hand produced `lib.color` for a column actually called `lib.accent_color` - a
view that reads correctly in the file and fails on the instance that runs it. A
check now compares the two definitions, ignoring comments, so they cannot drift.

## The PC side had models and nothing made from them

`pc-486`, `sound-blaster-16` and `voodoo2` were all seeded and never used. So a
fresh install showed one platform where models produce entries and another where
they sit unused - which teaches that models are an Amiga thing rather than how
the catalogue works.

All three are catalogued now, and the two cards are fitted into the 486 the same
way the Amiga pair are fitted into the 2000. Two hosts rather than one, because a
single example reads as *the* way it is done rather than as one case of it.

A check confirms every example names a model that actually ships, and that no
peripheral model ships without an example. Twenty assertions, which is the kind
of thing that only stays true if something asks.

Full suite: still 1 of 25, unchanged.

This package is **build 149**.

**"What goes in it" is gone. Specifications say the same thing.**

`model_slots` held a counted list of connectors per hardware model - five Zorro,
four ISA - beside a Specifications field saying the same in prose: *"Zorro II,
plus ISA and a CPU slot"*. One fact recorded twice, and only the prose half could
be edited from any screen. The structured half could only be changed by editing
`hardware_machines.json` and re-syncing.

## Why the structured form would have been worth keeping, and was not

A counted list against a controlled vocabulary is what *"which of my cards fit
this machine?"* needs. Prose cannot answer it. That was the argument for the
table, and it is written down in TAXONOMY.md.

**Nothing ever asked.** `parts_fitting_model()` was written for a model detail
page and deleted when an audit found no caller. The slot list outlived it by
being seeded, copied between libraries, checked by a maintenance job, and finally
displayed - but never read by a decision.

Two ways to say one thing, one of them uneditable and neither of them read, is
complexity without a return.

## What went, and what stayed

Gone: the table, the helper, the copy into a new library, the structure
importer's handling, the maintenance check, the API field, and the panel on the
web client.

**`hardware_vocab` stays.** It carries sockets, form factors and features too,
and `interface_vocab_id` uses it to say what a card plugs into - the other half
of the pairing, and the half something reads.

The vocabulary's delete guard was repointed at it. That guard counted slots, so
after this it would have been asking a dropped table whether a row was safe to
remove - a refusal that could never fire, on a query that could never run.

**The seeded machines now say the counts in prose.** The Amiga 2000's Expansion
field reads *"Zorro II x5, ISA x4 (bridgeboard only), video slot, CPU slot"* -
what the slot rows carried, in the one place that can now be edited.

Migration 014 drops the table. TAXONOMY.md keeps the reasoning, so that if
*"what fits this?"* is ever wanted, the shape it needs is on record rather than
rediscovered.

Full suite: still 1 of 25, unchanged.

This package is **build 148**.

**A location sent by id was silently ignored.**

`api_item_input()` read `location_path` and nothing else, so both phone clients -
which pick from `GET /locations` and therefore hold an id - sent `location_id`
and had it dropped. The save succeeded, reported success, and changed nothing,
which is the worst of the three possible outcomes: a failure would at least have
said so.

The id is accepted now, scoped to the entry's own library. The path still works,
for a client that has what a person reads rather than an id, and the id wins when
both arrive - it is the exact thing, and a path disagreeing with it is a caller
confused about which shelf it means.

**Null clears it, absent leaves it alone.** That distinction is why this asks
whether the key is present rather than whether it is truthy: `location_id: null`
means "nowhere" and no key at all means "do not touch".

The comment above the path branch said the API "has never handled a location at
all - not by id, not by path". Half of that was fixed and half was left, and the
half left was the half a client actually uses.

Full suite: still 1 of 25, unchanged.

This package is **build 147**.

**A dead token and no token were the same 401.**

Five failures produced one status: no header, an unrecognised token, a revoked
one, an expired one, and an account since closed. The *messages* already told
them apart - that was fixed a while ago - but a client reads codes, not prose, and
`unauthenticated` covered all five.

So a client had to guess. Guess one way and a request made before signing in logs
somebody out of a session they were about to start; guess the other and a phone
holding a revoked token retries forever against a wall, showing an error it cannot
act on.

`token_invalid` now marks the three that mean **this credential is dead**: revoked,
expired, or belonging to a closed account. A request with no token at all is still
`unauthenticated`, because that is a different thing and only one of them should
end a session.

Full suite: still 1 of 25, unchanged.

This package is **build 146**.

**`path` on a location meant two different things.**

An item's `location.path` is what it is called all the way down - "Retroway 22 ›
Basement › Book Shelf 1", built by `location_breadcrumb()`. The locations *list*
sent the column of the same name, which is the materialised id path: `/1/2/3/`,
maintained for subtree queries and never a label.

So a client reading `path` got a readable name from one endpoint and `/1/2/3/`
from the other, which is exactly what the mobile location pickers drew.

`breadcrumb` is the readable one on the list now. `path` still carries the ids,
because that is what it is for and something may be querying with it.

One field name meaning two things is the defect. A second name for the second
thing is the fix.

Full suite: still 1 of 25, unchanged.

This package is **build 145**.

**A read-only token could mint a read-write one.**

`POST /tokens` asked for authentication and nothing else. So the rule this scope
exists for - a read token changes nothing - had a hole in the middle of it: hand
somebody a read-only credential and they could ask here for a write one, and the
phone that was only supposed to browse could then empty a library.

A token that can issue tokens is every permission it can name. Minting is a
change, and goes through the same guard every other change does.

`POST` and `DELETE /profile/avatar` were the same shape and are now guarded too.
Small on its own - somebody's picture - but a rule with exceptions is not one
anybody can rely on.

## What was checked

Every write route in the API against whether it reaches a scope guard,
transitively rather than by looking at the handler alone. 128 routes; 119 were
already correct, three were not, and six are correct to leave open:

- the five ways to *get* a token - login, register, logout, verify, resend -
  which cannot require one
- revoking a token, deliberately. Cancelling a credential from a read-only device
  is a safety valve, and refusing it would mean a stolen phone in read mode
  cannot even lock itself out.

The first version of that check stopped at the handler and reported forty-four
failures. Most call `api_require_curates_library()` or `api_require_owns_library()`,
which guard properly one level down - a check that has to be right about a
security rule is worth writing twice.

## The rule, said plainly

**Scope is a ceiling, not a grant.** A read token reads, whoever holds it: an
administrator with a read-only token can change nothing, and a viewer with a
write token still cannot edit. Membership decides what a person may do; scope
decides how much of that they lent to a device.

Full suite: still 1 of 25, unchanged.

This package is **build 144**.

**`model_slots` is reported, after being seeded and read by nothing since the
beginning.**

It says what a machine physically takes: five Zorro slots, four ISA, one CPU
slot. `hardware_machines.json` has carried it for all six shipped machines from
the start, `structure.php` writes it on every sync, `model_slots()` reads it, and
no endpoint has ever sent it. Every installation has known its Amiga 2000 has
five Zorro slots and had no way to say so.

On a hardware model, and on the model an entry is made from.

**Empty rather than absent for a part.** A graphics card has no slots of its own
- it goes *in* one, which is `interface` and a different question. A client
should not have to tell "this has none" from "this was not asked".

**Only with the full article.** The flag the detail endpoints pass and the list
endpoint does not: a query per entry is nothing on one machine and forty on a
page of them, to fetch something a list has no room for.

Full suite: still 1 of 25, unchanged.

This package is **build 143**.

**An administrator can confirm an email address on somebody's behalf.**

`email_verified` has been reported by this API throughout and settable by
nothing. That matters the moment "require a confirmed email address to sign in"
is switched on: every account made before mail worked is locked out, and the way
back needs a working relay - which is exactly what an instance in that state does
not have. The requirement creates a situation it cannot itself fix.

`PATCH /admin/users/{id}` takes it now. Confirming an already-confirmed address
keeps the original timestamp rather than moving it, because when it was confirmed
is a fact and this is not a new one.

Named in the security log for what it is: **"email confirmed by an
administrator"** or **"email confirmation withdrawn"**, not `email_verified_at`.
Nobody has proved they can read the address; somebody with the authority to say
so has decided that is fine, and a log that leaves the reader to work out which
of those happened is not much of a log.

Full suite: still 1 of 25, unchanged.

This package is **build 142**.

**Removing an account did nothing about what it owned, while the web client's
confirmation described exactly what it should have done.**

`api_users_delete()` was `delete_row('users', $id)` and nothing else.
`libraries.owner_id` has no foreign key, so the row went and every library it
owned kept pointing at an id that no longer existed. A personal shelf survived
with its entries and photographs, owned by nobody, invisible to every screen that
starts from an account.

The dialog in Instance Users already promised the behaviour below. A dialog that
describes something the engine does not do is worse than a missing feature: it is
believed.

## Two fates, because they are two different things

**A personal shelf is deleted with the account**, entries, photos and all. It
exists because the account does, nobody else can be given it, and keeping it
leaves a library no screen can reach and no person can claim.

**Every other library it owned is left standing with no owner**, for an
administrator to hand on. Those are somebody's work, possibly several people's.
Deleting a club's shelf because the person who happened to create it left would
be destroying other people's entries to tidy up after one.

An offer of ownership made *to* the departing account is cleared too, or the
library keeps a pending owner nobody can accept as.

## What that needed

`library_purge()` takes `$withOwner`. It refuses a personal shelf, correctly - it
is not an administrator's to tidy away while its owner is still using the
instance - and this is the one case where the owner is going too. The
last-library guard is lifted with it: an instance whose only library is a
departing account's personal shelf should end up with none, not keep a shelf
nobody owns so that a count stays above zero.

**A personal shelf that cannot be deleted stops the whole thing**, with a 409 and
the account intact. Removing it anyway is how the orphan this fixes was made.

The response is 200 with `purged` and `orphaned` rather than a bare 204, so a
client can say how many libraries now need an owner instead of reporting success
and leaving somebody to notice.

Full suite: still 1 of 25, unchanged.

This package is **build 141**.

**The repository is `retrohive-core`.**

The directory, the GitHub and GitLab remotes, and the four addresses the engine
actually fetches from:

- `structure.php` reads the template data from
  `raw.githubusercontent.com/norrorthoarders/retrohive-core/main/structure`
- `installer.php` and `structure.php` ask
  `api.github.com/repos/norrorthoarders/retrohive-core/releases/latest` whether
  there is a newer version

Those break the moment the rename happens on GitHub, and the failure is a sync
that quietly finds nothing rather than an error anybody would connect to a
rename.

## Migration 013

`structure_source` is written into the database at install time from the default
in the settings schema. Changing that default fixes new installs and does nothing
for existing ones - so the migration rewrites the stored value.

**Only the address this project publishes.** A row somebody has pointed at their
own fork is theirs, and rewriting it because it happens to contain a word we
renamed would be taking a decision that is not ours to take.

Full suite: still 1 of 25, unchanged.

This package is **build 140**.

**`GET /items?library_id=` was silently ignored, so both phone clients showed
every library at once.**

The filter read `?library=slug` and nothing else. A client holding the id from
`GET /libraries` - which is what both mobile clients hold, because that is what
the endpoint returns - sent `library_id`, and an unrecognised parameter narrows
nothing. Selecting "My Private Library" returned the example library's entries
too, which reads as a switcher that does not work rather than a filter that was
never applied.

**Silently is the problem.** A filter that matched everything and a filter that
was never read look identical from the outside. The comment sitting above this
code warned about exactly that failure for the slug - "the filter has to exist or
that link quietly shows everything instead of one shelf" - and the same thing
then happened one parameter along.

Both are accepted now. The id wins when both arrive: it is the exact thing, and a
slug that disagrees with it is a caller confused about which shelf it wants
rather than a request to be guessed at.

No access check on the id. The ACL clause above already limits the query to
libraries the account may read, so naming one it may not simply matches nothing -
the right answer, and not a disclosure.

Checked every parameter the two clients send against what the filter reads:
`domain`, `library_id` and `q` are filtered, `page` and `per_page` are read by
the endpoint. Nothing else is being dropped on the floor.

The web client sends the slug and was never affected.

Full suite: still 1 of 25, unchanged.

This package is **build 139**.

**A sweep for what the interface removal left behind.**

## The stylesheet and the script

`app.js` carried 43 modules for the interface this application used to serve -
table filters, tree editors, drop zones, a cropper, a barcode reader. **40 of
them attached to markup that no longer exists**: they found nothing and returned,
which is harmless and was 83 KB of harmless. What is left is the notices module,
which the two remaining pages actually use. **101 KB to 3.7 KB.**

`app.css` was the same story: **299 of 384 rules** styled markup that is gone.
**56 KB to 14 KB.**

The colour variables are kept whole rather than trimmed to what is read today -
they are the palette, not decoration for one screen, and cutting them by current
usage is how the next thing added here comes out the wrong colour.

Verified by rule rather than by eye: every class the surviving templates put on
an element still has a rule, and every variable a kept rule reads is still
declared. The first pass of that check failed - it matched class names as
substrings, so `.on` was kept because the word "on" appears in prose, and two
rules came with it referencing variables that do not exist. The check reads class
attributes now.

## Files

`src/config.local.php.bak` removed, and `.gitignore` widened to cover it. The
pattern named `src/config.local.php` exactly, so a backup of the local config -
which is the local config, credentials included - would have been committed. The
one here was empty. The next one might not have been.

The uploads directory is cleared of the test images sitting in it. Already
ignored by git, so they were never committed; they were in the working tree and
would have gone out in a package.

## What was checked and kept

Every `bin/` script - they are command-line tools that never depended on the
interface. `public/router.php`, which is for PHP's built-in server in
development. `/setup`, which creates the first administrator on an instance that
has none and is the only screen that cannot sit behind a sign-in.

`docs/REDESIGN.md` describes a browsing design in terms of screens that no longer
exist here. Left alone: the argument is about the shape of the category tree,
which the web client now has to answer, so it is a design note rather than
documentation of something removed.

Full suite: still 1 of 25, unchanged.

This package is **build 138**.

**The root sends people to the interface, and every redirect that pointed at a
deleted screen has somewhere to go.**

Removing the web interface left the root serving a 404 - on a running instance
that reads as "this is broken", not "you are one hop away". `GET /` now
redirects to the client.

First run wins over it: an instance with no administrator has one thing worth
doing, and sending somebody to a client they cannot sign in to helps nobody.

## Seven redirects were pointing at nothing

`auth_setup()` and `auth_setup_form()` sent an already-configured instance to
`/login`, `require_edit()` and `require_manage()` sent a signed-out caller there
too, and `require_admin()` and the manage guard sent people to `/` - which was
itself a 404 until this build. Somebody hitting `/setup` on a working instance
was bounced to a page that no longer existed.

All of them go through `to_client()` now. The `next` parameter went with
`/login`: this application cannot hand somebody back to a page it no longer
draws.

**Both 404 buttons were dead too** - "Back to the overview" and "Browse the
collection" pointed at the two screens most recently deleted, so a 404 offered
two more of itself. One link now, to the interface, and only when the instance
knows where that is.

## When it does not know

`client_base()` reads `client_url`, falls back to `site_url`, and returns nothing
when neither is set. Nothing means a short page saying the address has not been
configured and where to set it - **not a guess at `/web`**. Redirecting to a path
that might be right is how somebody lands on a second error page wondering which
one is the real problem, and the same setting builds confirmation links, so
getting it wrong here would be wrong twice.

Full suite: still 1 of 25, unchanged.

This package is **build 137**.

**The engine's own web interface is removed. What is left is an API, a first-run
screen, and the endpoints other services call.**

## Gone

113 routes, and with them six controllers - `browse`, `dashboard`, `locations`,
`notifications`, `taxonomy`, `titles` - and the template trees for taxonomy,
titles, companies and items. Controllers and templates together: **1272 KB to
393 KB**.

Four controllers were trimmed rather than deleted, because the API calls into
them. `account.php` keeps 5 functions of 45, `items.php` 3 of 30, `import.php` 7
of 9, `registration.php` 6 of 8. Each now says at the top what it is and why it
outlived the rest.

`library_grantable_levels()` was the one function the API genuinely needed from
an own-UI file, and it has moved to `acl.php` - beside the other rules about who
may be granted what, which is where a rule about who may be granted what belongs.

## Still served

`/setup`, `/status`, `/status.json`, `/status/debug`, `/robots.txt`,
`/items/export.csv`, and the API. Every pattern was tested against paths that
should and should not match; `/items`, `/manage` and `/login` are 404s now.

The list of paths reachable without a session was updated with them: it still
named `/login` and `/register`, which is a door held open onto a room that is not
there.

## Two things the removal exposed

**The 404 page drew the full navigation** - a menu of links to screens that no
longer exist. It is bare now, like setup, and the layout's navigation branch went
with it, along with an unread-notification announcement pointing at a deleted
page. Both surviving pages were rendered to prove they still work rather than
assumed.

**27 comments describe a form that is gone.** Phrases like "the same rule the
real form applies" were true when written and now point at nothing. Each is left
in place - it still says something true about *why* a rule is what it is - and
each file now opens by saying what those phrases mean and that the screens have
been deleted. A reader who takes them literally would go looking for a page that
is not there.

## Verification

No surviving code calls any of the 115 removed functions - checked against the
previous package with comments stripped, in the source and in the templates
separately. 174 route handlers resolve, 114 API routes documented as 114, and
every suite passes.

Full suite: still 1 of 25, unchanged.

This package is **build 136**.

**The two things that were only possible from the engine's own screens.**

## Confirming an email address

`verify_email_token()` has existed throughout and was reachable only from
`GET /verify`. The API had `verify/resend` - a way to ask for another link and no
way to use one - so an instance running on the API alone could send confirmation
mail nobody could act on. With "require a confirmed email address to sign in"
switched on, that locks out every account including whoever ticked it.

`POST /auth/verify`, unauthenticated on purpose: the situation it exists for is
somebody who cannot sign in *because* their address is unconfirmed, and requiring
a token to fix the thing stopping you getting one is a closed loop. The same
answer for a wrong, used or invented token - telling them apart tells somebody
holding a guess which guesses are close.

**Where the link points is now a setting.** It was built from `site_url`, the
engine's own address, which is right while the engine serves the screens and
wrong once it does not - a confirmation link that 404s is an account nobody can
finish making. `client_url` names where people actually go and falls back to
`site_url`, so an instance that has never heard of it behaves as before.

## Handing a library over

The API had accept, decline and withdraw and no way to *make* an offer - three
quarters of a feature, and the quarter missing was the one that starts it.

`POST /libraries/{id}/ownership/offer`. Owner only, never a personal shelf, and
only to a member who has accepted: somebody who has not joined has not agreed to
be in the library at all. Nothing changes hands - the library stays the owner's
until the offer is taken, which is what makes it an offer.

`pending_owner_id` is reported on a library now, so a client can say an offer is
standing rather than leaving the only sign to be the person at the other end
being asked something.

Full suite: still 1 of 25, unchanged.

This package is **build 135**.

**A metadata source reports which kinds it answers about.**

`default_for_kinds` has been known per provider throughout - it is what decides
which branches a source is switched on for when a library is seeded - and was
never reported. So a client listing sources could not say which side of the
catalogue each one serves, and "which of these covers films" is the first
question anybody has about a list of them.

`kinds` and `domains` now come down with each configured source and with each
available type.

Full suite: still 1 of 25, unchanged.

This package is **build 134**.

**A metadata source is tested before it is added, which this said it could not
do.**

`api_metadata_providers_create()` demanded `skip_probe: true` and explained that
"this API cannot make that call". It can, and always could: the installer has run
exactly this check on every shipped source since the beginning - that is what "7
switched on, the ones that answered" means in its output. The claim was written
before that existed and outlived it, and the cost was a source added in a broken
state behind a tick box asking somebody to accept that it might not work.

A source that does not answer is refused. The failure carries `needs_key` and the
parameter names, so a client can tell "fill in the key" from "the source is down"
- which are different things to do next.

**Saving a source's settings re-tests it**, and reports the result. A source added
without a key is switched on and unable to work; the moment somebody fills the key
in is the first chance to find out whether it was the right one, and it is exactly
when they want to know. Not fatal - the settings save either way, because
refusing them would mean a perfectly correct key cannot be stored during an
outage. The answer is reported and written to `last_error`.

Full suite: still 1 of 25, unchanged.

This package is **build 133**.

**A logo is trimmed and fitted when it is stored, so any size works.**

A logo arrives as somebody's export: the mark in the middle of a large canvas,
most of the file transparent or white. The one that prompted this was 1536x1024
with the mark occupying 935x181 - **89 per cent of the file was background**.
Scaled whole to 24 pixels tall, the mark itself came out around 4 pixels. It
looked broken because it was being asked to share its height with an inch of
nothing.

So the margin is measured and removed first, and only then is the thing itself
scaled. Both halves matter: trimming without scaling leaves a file far bigger
than it needs to be, and scaling without trimming is the problem.

Transparent *and* near-white count as margin. A logo exported on white is as
common as one on transparency, and whoever uploads it thinks of both as "the
background". An image that is entirely background is left alone rather than
cropped to nothing, and one GD cannot read is refused with a message rather than
stored at the wrong size.

Doing it once here means every client gets a logo that is the right shape,
instead of each of them meeting the same problem and solving it differently. It
also means **no size needs to be demanded of anybody** - a requirement in a hint
is a requirement somebody has to satisfy by hand in an image editor.

No separate thumbnail any more: the stored file is the size it is drawn at, so a
second copy would be a second thing to keep in step for nothing.

Full suite: still 1 of 25, unchanged.

This package is **build 132**.

**An instance can carry its own marks.**

`POST /admin/logo/small` and `/large`, with `DELETE` beside each. Two pictures,
not one scaled twice: a mark that reads at 24 pixels beside a menu is rarely the
same drawing as one that carries a sign-in page, and making somebody use one
image for both guarantees it is wrong at one of the two sizes.

Reported by `GET /meta` rather than from behind the admin gate, because a client
needs the large one **before anybody has signed in** - which is the whole point
of it. Null means "draw the built-in mark", so an instance that uploads nothing
behaves exactly as it did.

## The orphan sweep would have eaten them

Every other picture is referred to by a column on a row, and these two are named
in `settings` - so `maintenance_upload_is_orphan()` read them as unreferenced,
and the repair beside it deletes what it reports. Uploading a logo and then
running the sweep would have restored the built-in mark with no explanation.

The same check was also missing `users.avatar_pending_filename`, so a profile
picture waiting for an administrator was an orphan too - the sweep would have
thrown away the very picture somebody was queued up to approve. Both are covered
now, in the maintenance job and in `bin/cleanup-uploads.php`, which keeps its own
list.

This is the third time that list has been short. It is worth reading whenever
anything new is written to the uploads directory.

Full suite: still 1 of 25, unchanged.

This package is **build 131**.

**Two kinds of library, named for what they mean - and the cap on a personal
shelf is enforced in acl.php rather than in a dropdown.**

## private and public

`shared` said how a library is used; `public` says who may reach it, which is
what the column actually decides. The pair was not really a pair either: a
library could be `shared` and still members-only, because `public_read` was a
separate switch beside it. Four combinations for two real arrangements, and one
of them - private-but-public - was a contradiction the form allowed.

    private   access has to be granted to each person by name
    public    anybody signed in can find it and join it, and gets read access

`public_read` follows `kind` now, and `public_write` is always 0: joining grants
read and nothing more. A higher level is something somebody is invited to, not
something taken by arriving.

Migration 012 maps it forward. A shared library that was open becomes public; one
that was members-only becomes private, which is what it already behaved as. The
ENUM is widened before the rows are rewritten and narrowed afterwards - renaming
the value in place would have made every existing row invalid for the instant
between two statements, and MySQL resolves that by silently writing `''`.

## The invitation ceiling

`library_grantable_levels()` answered on `kind`: only a public library could
grant above viewer. So a private library shared with three people could never
make any of them an editor - backwards, since a private library is the one whose
membership is deliberate.

What caps it is `is_personal`. Somebody's own shelf - made with their account,
impossible to delete - invites at **viewer and no higher**, so nobody but its
owner can ever change what is on it. Every other library, private or public, goes
up to administrator. Owner is on no list anywhere: a library has exactly one, and
it moves by an offer that has to be accepted.

**In `acl.php`, and the three callers now go through it.** A ceiling that lives in
a dropdown is a ceiling a second client does not have.

`library_to_api()` reports `invitable_levels`, so a client offers what is allowed
rather than a list the server then refuses.

Full suite: still 1 of 25, unchanged.

This package is **build 130**.

**`GET /profile/libraries` reports how many decisions are waiting.**

`meta.waiting` - invitations plus offers of ownership. Two different objects and
the same fact to somebody looking at a menu: something is waiting on them. A
client drawing a badge should not have to fetch both lists, add them up, and
decide for itself which of the four keys count.

**Libraries open to join are deliberately not in it.** Nobody is waiting on an
answer about those - they stand open to everybody - and counting them would put a
badge on a menu entry permanently, which teaches people to ignore it.

Full suite: still 1 of 25, unchanged.

This package is **build 129**.

**`GET /libraries/{id}/invitable` - who could be invited here, by name.**

Inviting somebody needed their numeric account id, which nobody knows and which
has to be read off a screen most people who run a library cannot open.

**A search, deliberately not a list.** Anybody who administers one library would
otherwise be handed every account on the instance - a membership directory nobody
asked them to have, and on a shared instance somebody else's business. Two
characters minimum, twenty results.

Short queries answer with an empty list rather than a 422: an empty box is the
ordinary state of a search, and an error under a field nobody has typed in is
noise.

Only what an invitation needs comes back - the id to send and a name to recognise.
No email, no role, no last-seen: none is required to choose somebody, and all
would be a fact about an account leaking to whoever runs a shelf. Inactive
accounts, the caller, and anybody already a member or invited are left out, since
offering them is offering an action that would be refused.

Same gate as the invitation itself. A search that answers for somebody who could
not act on the answer is a directory with extra steps.

Full suite: still 1 of 25, unchanged.

This package is **build 128**.

**Credit roles are counted in the structure report.**

They have been offered as a part to synchronise all along and were never counted
by `structure_row_counts()`, so the one report that says whether a sync worked had
nothing to say about them - somebody ticking "Credit roles" got no confirmation
either way.

**People are deliberately absent and stay absent.** There is no people file to
sync from: a person exists because a credit named them - a director on a film, a
composer on a record - so the list grows from the catalogue rather than from the
structure feed. A row here reporting "0 of 0" would invite somebody to go looking
for a sync that does not exist.

Full suite: still 1 of 25, unchanged.

This package is **build 127**.

**"Can this person sign in, and as what?" is an API question now.**

`ldap_inspect_user()` has existed throughout and was reachable from the engine's
own directory screen and nowhere else - so the question an administrator actually
asks when somebody cannot get in could only be asked from one place.

`POST /admin/auth-methods/inspect`, taking the same shape as the test beside it:
a saved directory by id, or whatever is on an unsaved form, or both merged. A
directory can be interrogated before it is saved rather than only after.

**`found` and `allowed` come back separately**, and that is the whole value. An
entry the search cannot see is a base DN or a filter problem; one it finds but
refuses is a group membership problem. Those are different afternoons, and a
single "cannot sign in" sends somebody down the wrong one.

Always 200. "Not found" and "found but refused" are successful lookups reporting
bad news, and a 404 there would make a client show a broken-request error for a
working request.

Logged as a security event: reading who a directory says somebody is - their
name, their address, their groups - is reading personal data out of another
system, and a log that recorded only the sign-ins would not show it happening.

Full suite: still 1 of 25, unchanged.

This package is **build 126**.

**The log can be pruned through the API, and the list says how much a prune would
take.**

`log_prune()` has existed since the beginning, reachable from the engine's own
settings screen and from the nightly `bin/notify.php` and from nowhere else - so
a client could read the log and never tidy it.

`POST /admin/logs/prune`. **The rule is not a parameter.** Retention is an
instance setting, and letting a request name its own cutoff would put "delete the
whole log" one request away from anybody who can read it. Retention set to keep
everything is refused with a 422 rather than succeeding and removing nothing: a
button that reports success and does nothing is worse than one that explains
itself.

`GET /admin/logs` now sends `prunable` and `retention_days` alongside the
entries, so a client can label the button with its effect instead of asking
somebody to press it and find out. New `log_prunable_count()` asks the same
question `log_prune()` answers by acting.

The prune is itself logged, after the delete so the entry survives it.

Full suite: still 1 of 25, unchanged.

This package is **build 125**.

**A company can be given a logo through the API.**

`store_company_logo()` has existed throughout with no endpoint in front of it, so
the only way a logo ever arrived was the engine's own screen - and any other
client could show one and never set one.

`POST /companies/{id}/logo` and `DELETE` beside it. Same gate as editing the
company itself: a logo is a property of the company, not a separate kind of thing
with a looser rule.

Full suite: still 1 of 25, unchanged.

This package is **build 124**.

**`GET /companies` accepted neither the library nor the side of the shop, so the
Companies screen was empty and every manufacturer picker with it.**

`all_companies()` with no arguments falls back to the engine's own
`working_library()` - a session notion an API client has no way to set. So this
endpoint returned whatever library the *server* happened to think was current,
and nothing at all when it thought none was. Companies became per-library when
vendors and companies were merged; this was the reader still assuming otherwise.

`?makes=hardware` was ignored outright. The hardware model form has been asking
for hardware makers all along and being answered with everything, or with
nothing.

Both are ordinary query parameters now, like every other picker endpoint, and the
`q` search is scoped the same way - otherwise typing a name reaches past the
shelf the rest of the screen is confined to.

Full suite: still 1 of 25, unchanged.

This package is **build 123**.

**An audit, and the one real finding from it: five endpoints added in build 110
were never documented.**

`/admin/users/{id}/avatar/approve` and `/reject`,
`/libraries/{id}/pending-images`, `/images/{id}/approve` and `/reject`. The
schema they use was documented at the time and the paths were not, so the
approval features existed for anybody reading the code and did not exist for
anybody reading the API. Now 107 routes and 107 documented paths.

## What was checked, and found clean

- **Every route handler exists.** 253 in the engine, 118 in the web client, none
  missing.
- **Every column written exists in the schema.** Parsed the CREATE TABLE bodies
  and every `insert_row()`/`update_row()` literal against them. Two literals the
  parser could not read were checked by hand.
- **Every template variable is passed or local.** Cross-checked what each
  controller sends against what each template reads.
- **This session's features as chains** rather than as files: pending pictures
  stay out of `item_images()`, out of the cover, and out of the image count;
  every new endpoint is routed; every new function is defined exactly once.
- **The settings schema and the client's tab list agree** in both directions, and
  no setting is declared in two sections - a move between sections would
  otherwise shadow one silently.

Two findings were false and worth recording as such: `h()` and `fail()` appear
twice each, in separate entry points that never load together, and the three
"duplicate" template functions are in separate script scopes.

Full suite: still 1 of 25, unchanged.

This package is **build 122**.

**A stale scope note corrected.**

`api_auth_methods_index()` still said that "testing a real bind and looking up a
real directory entry stay out of scope". Testing a bind was built - it is
`POST /admin/auth-methods/test`, and it takes whatever is on the form rather than
what is stored, so a directory can be proved before it is saved. Only the
named-user lookup is still engine-only.

A comment describing restraint that no longer exists is worse than no comment: it
is the file telling somebody the wrong thing about itself, and the next person to
read it will believe it.

Full suite: still 1 of 25, unchanged.

This package is **build 121**.

**Structure source moves from General to Catalogue.**

General is where a setting goes when nobody has decided where it belongs, and
this one had been sitting between the instance name and the public address. What
it names is the feed the categories, companies, platforms and models are fetched
from - the source of the catalogue's whole shape, and the one setting on the
instance that decides what the filing tree looks like.

It joins the switch for the generic pictures, and the Catalogue section's help
now covers both: where the structure comes from, and what entries look like when
nobody has said.

The help text says what it is actually for, which the old one left implicit -
pointing it at a fork runs your own tree, and the copy that shipped is used when
the address does not answer.

Nothing stored moves. A section is where a field is *shown*; settings are keyed by
their own name, and every reader of this one - `structure_source_url()`, the
sync, the settings form - reads it by name. Checked, along with the field names
being unique across sections so a move cannot shadow another.

Full suite: still 1 of 25, unchanged.

This package is **build 120**.

**Hardware model specification fields reach the API, an administrator stops
seeing everybody's private shelves, and a personal library can no longer be
deleted from the one path that allowed it.**

## Specification fields

`model_fields` has existed and been written by the engine's own screen
throughout, and `hardware_model_to_api()` never reported it. So a client could
pick an Amiga 2000 and get its name, its interface and nothing else, while the
model itself knew its processor, its memory and its chipset - which is why the
autofill on the entry form filled three fields: three were all it could see.

Reported now, and accepted on create and update. Replaced wholesale when present,
left alone when absent, blank-label rows dropped - the same rule every other
child list on this API follows. `INSERT IGNORE`, because `uq_model_field` is on
(model_id, label): two rows both called "Memory" is a typo, and the second
silently losing beats the whole save failing on it.

## An administrator is not a landlord

`GET /admin/libraries` listed every library on the instance, private ones
included, with the owner's name and a count of what was in it. `acl.php` is
deliberate that membership is the whole of access and that being an administrator
grants nothing - this screen was the one place that quietly disagreed.

It now returns every library except somebody else's private one. The
administrator's own private library stays, because it is theirs. Ordinary
browsing was already membership-only for administrators and is unchanged.

## A personal library cannot be deleted, by anybody

`api_libraries_delete()` has refused this from the owner's own side throughout,
and `library_purge()` refuses it too. `api_admin_libraries_delete()` had no such
check - so the one account with the most reach was the one that could destroy
somebody's default shelf and leave them nowhere to put things. It refuses now,
and says that disabling is what "stop this being used" actually means.

## Elsewhere

Sound card joins Graphics card under Adapters. A sound card's whole purpose is
reaching something outside the case - a speaker, an amplifier, a MIDI box - and
the earlier reading, that it adds synthesis the machine did not have, is equally
true of a graphics card. Splitting the pair on it put two cards that sit in
adjacent slots in different branches.

The profile-picture approval switch moves from General to Security, where the
other three site-wide security switches already are.

Full suite: still 1 of 25, unchanged.

This package is **build 119**.

**`effective_image` on a category told a screen "nothing" while the shelf plainly
showed something.**

It reported two of the four steps an entry actually takes: a picture uploaded
onto the branch, and one inherited from a branch above. It knew nothing about the
shipped pictures - so a branch relying on those, which is most of them, came back
with no picture at all while every entry filed under it visibly had one.

All four now, with `source` saying which answered:

    own        uploaded onto this branch
    inherited  from a branch above
    branch     the shipped picture this branch declares
    kind       the shipped picture for this kind of thing

The last is named `kind` rather than passed off as the branch's answer, because
it is the weakest: an entry that says what it comes on may well get something
closer - a Blu-ray film gets a Blu-ray case rather than the generic one a branch
of films would show here.

`stock_image` comes with it, so a picker can show which shipped picture a branch
currently declares rather than only offering the whole list.

Full suite: still 1 of 25, unchanged.

This package is **build 118**.

**Proving that mail arrives is an API now, not just a form handler.**

`send_smtp_confirmation()` and `confirm_smtp_code()` have existed throughout and
were reachable only from the engine's own settings form, so no other client could
offer the one step that matters: saving relay settings proves nothing, because a
relay will happily accept a message and drop it. The only evidence is somebody
holding a number that was sent to them.

- `GET /admin/mail` - enabled, verified, when, and whether a code is waiting
- `POST /admin/mail/send-code`
- `POST /admin/mail/confirm-code`

`code_pending` is false once the relay settings change, not merely once the code
expires. A code is stored against the fingerprint of the settings it was sent
under and cannot be redeemed after the host moves - reporting it as pending would
have somebody typing a number that cannot work.

`code_expires_in` comes with it, so a client can say what is actually left rather
than repeating a flat "good for half an hour" to somebody twenty-nine minutes in.

A refusal is 422 rather than 500: almost every failure here is a setting somebody
typed - a sender the server will not accept, a host that does not answer - and
the engine's own message names which, which is far more use than "could not
send".

Full suite: still 1 of 25, unchanged.

This package is **build 117**.

**The `signin` settings section becomes `security`, and grows the two switches
that had been filed under General for want of anywhere better.**

`search_indexing` governs whether this instance can be found from outside;
`libraries_deletable` governs whether data can be destroyed. Neither is a general
preference. Sign-in was a section of one field with a name too narrow to hold
them.

The keys are unchanged, so nothing stored moves - a section is where a field is
*shown*, and settings are keyed by their own name. The two places that name
`signin` both key on the field rather than the section and are unaffected.

Full suite: still 1 of 25, unchanged.

This package is **build 116**.

**A hard drive picture, closing the last gap in the hardware catalogue.**

All five branches under Storage now name a picture of their own - hard, floppy,
optical, Zip and tape. Nothing under Storage inherits the generic expansion card
any more.

42 pictures across 84 files, 6 MB. 33 of the 35 hardware branches name one; the
two that do not are Storage itself and Peripherals, which is right - both are
headings whose children answer for them.

Full suite: still 1 of 25, unchanged.

This package is **build 115**.

**Thirty categories came out of a fresh install with truncated paths, because the
two functions that rebuild them disagreed about how deep the tree goes.**

`rebuild_category_paths()` looped four times, under a comment saying "four
levels, which is what the tree allows". `category_rebuild_paths()` beside it
looped eight. Which one ran decided whether a deep branch came out right, and the
installer calls the one that said four.

Four was true of the tree it was written for. It stopped being true when the
shipped hardware feed grew Storage controller and I/O card: a library's tree is
two levels deeper than the template it is copied from - the platform is the root
and the section sits under it - so a template branch three deep lands at five.
The fifth level was never visited. Five slugs across six platforms is exactly the
thirty rows the consistency check reported.

Both now use `CATEGORY_MAX_DEPTH`, written once, set to twelve. Locations use it
too: nobody nests a shelf twelve deep, but the category tree did not look like it
would outgrow four either.

**Worth being blunt about the failure mode, because it is quiet.** A wrong path is
not a wrong row - the tree still draws correctly, since that follows `parent_id` -
so nothing looks broken. What breaks is everything reading `path` as a prefix: the
subtree filter behind `category=`, the non-empty check behind `non_empty=1`, and
the ancestry walk deciding which metadata sources a branch gets. A SCSI controller
with a truncated path is filed correctly and found by none of them. The only sign
was the check on Instance Status, which is what it is for.

An instance already carrying this does not need reinstalling: **Instance Status →
Filing tree consistency → Rebuild the paths** now repairs it, having been the one
report that could see the problem and the one repair too shallow to fix it.

Full suite: still 1 of 25, unchanged.

This package is **build 114**.

**An optical drive, and a Storage branch for it.**

    Storage
      Hard drive       (still inherits the generic card)
      Floppy drive
      Optical drive    new
      Zip drive
      Tape drive

**Named for the family rather than for CD-ROM specifically.** A CD-ROM drive, a
DVD-ROM drive and a writer are the same object from the front - three branches
that cannot be told apart in a photograph would be three ways to file the same
thing, and whichever one somebody picked would be a guess. The note on the
picture says as much.

Sort orders renumbered rather than wedging the new branch on the end, so the list
still reads in a sensible order.

Unlike the three drives in build 112, this one is photographic and matches the
monitor and the cards. The floppy, Zip and tape drives remain the line-art
outliers in an otherwise photographic hardware set.

**Hard drive is now the only one of the five without a picture of its own**, and
the only remaining gap in the hardware catalogue.

41 pictures across 82 files, 5.9 MB. 32 of the 35 hardware branches name one.

Full suite: still 1 of 25, unchanged.

This package is **build 113**.

**Three drive pictures, closing most of the gap left when Storage gained its
four branches in build 99.**

    Floppy drive   an external drive box with a 3.5-inch slot
    Zip drive      the dark external cartridge drive
    Tape drive     a cassette recorder of the kind a home computer loaded from

Those three branches were inheriting the generic expansion card, which is honest
about them being peripherals and wrong about all three - a drive is not a card.

**Hard drive is still the exception** and still inherits the card. It is the one
of the four with no picture, and worth saying rather than quietly leaving.

Normalised the same way as the rest: trimmed to their own alpha bounds and
re-centred at the same relative scale, so the grid does not jump between a drive
and a jewel case. 2.2 MB of PNG each down to 143, 86 and 83 KB of WebP.

A note on style, since it will be visible: these three are drawn as line art
while the rest of the hardware set is photographic. Beside the monitor and the
cards they read as a different hand. Not wrong - they are clear at thumbnail
size, which is the job - but if the set is ever made consistent, these are the
three that differ.

The catalogue is 40 pictures across 80 files, 5.8 MB, and 31 of the 34 hardware
branches now name one.

Full suite: still 1 of 25, unchanged.

This package is **build 112**.

**A stale docblock corrected.**

`software_model_to_api()` still carried the note explaining that the three child
lists were "left for later" - written when they were, and left in place when
build 89 added them. A comment describing restraint that no longer exists is
worse than no comment: it is the file telling somebody the wrong thing about
itself.

Replaced with what the function actually does, including why the lists are
behind `$withLists`.

Full suite: still 1 of 25, unchanged.

This package is **build 111**.

**Pictures can be made to wait for somebody's approval - profile pictures across
the instance, photographs per library.**

Two features with one shape, and one rule each about who is exempt. Both switches
are off, both new columns default to the permissive value, and an instance that
turns neither on behaves exactly as it did.

## Profile pictures

New `avatar_approval` setting. On, a picture uploaded by anybody but an
administrator waits in Instance Users until one says yes.

**The picture already in use stays up meanwhile.** What is pending is the change,
not the removal - somebody waiting a day should not spend that day as a set of
initials, and reverting them would be a second change nobody asked for. That is
why this is a second column, `avatar_pending_filename`, rather than a state on
the first: the first *is* what is shown, and holding a pending picture there
would mean either showing it or teaching every reader of `avatar_filename` to
check a flag. There are readers in the API, this application's own screens and
two clients. None of them has to know the feature exists.

Administrators are exempt from their own switch - a queue you approve your own
entries in is a formality rather than a check.

## Library photographs

New per-library `photo_approval`. On, a photograph uploaded by anybody who does
not curate that library waits until somebody who does says yes. Per library
because one shared shelf wanting review and one private shelf wanting none is the
ordinary arrangement.

Exempt: instance administrators, and anybody who curates the library - again, the
people who would be approving it.

Here the state is on the row, unlike an avatar: an entry has many pictures, and a
pending one is a new row rather than a replacement.

## Making "not shown" actually true

A pending picture would have leaked in three separate places, and each had to be
closed on its own:

- `item_images()` returns approved only unless asked otherwise. This is what
  every gallery, cover and API read goes through, so one default covers all of
  them rather than each place somebody remembered.
- `ensure_primary_image()` will not make a pending picture the cover, and clears
  any stale primary flag on a pending row. Both halves needed it: the count, or
  the first pending upload onto an entry with no photographs would satisfy it and
  stop anything else being chosen.
- `sync_item_image_columns()` excludes pending from `cover_image_id` **and**
  `image_count`. These are the columns `v_items` reads, so this is the one that
  mattered most - a pending picture would otherwise have appeared as the cover on
  a shelf card without anybody opening the entry.

Metadata agents are unaffected: the column defaults to approved, and an agent is
not a person whose artwork needs vouching for. Every picture already on an
instance stays visible for the same reason.

## Deciding

- `POST /admin/users/{id}/avatar/approve` and `/reject`
- `GET /libraries/{id}/pending-images`, `POST /images/{id}/approve` and `/reject`

Refusal deletes the row and its files, through the same `delete_image()` every
other removal uses. There is no rejected state: a refused picture left on disk is
one somebody can still reach by guessing a URL, and a row kept as rejected would
be a queue that only ever grows.

`api_image_decide()` reads the library from the picture rather than from the
caller, so no request can approve a picture into a library it is not in.

`item_images.uploaded_by` is now recorded on every upload, switch or no switch. A
photograph on a shared shelf with no name against it is one nobody can ask about.

Migration 011. Full suite: still 1 of 25, unchanged.

This package is **build 110**.

**`GET /categories` can be asked for one library's tree, and `non_empty` now
counts only that library's entries.**

The endpoint returned every tree the account could read and had no way to narrow
it. That is right for a picker not yet told which shelf it is filling, and wrong
for anything that has been - and `non_empty` inherited the same scope, so it
answered "does anything anywhere use this branch" when the question was always
"does anything *here*".

An empty private library therefore offered the genres of every other library the
account could read - Applications › Graphics and CAD on a shelf with nothing on
it, because a different shelf had a copy of Deluxe Paint. The branches offered
were that other library's rows too, so choosing one could not have matched a
single entry.

`library_id` narrows both, and refuses a library the account cannot read rather
than quietly returning nothing.

The platform count is scoped to the same library when one is named. It was
already confined to one by `vi.platform_id = p.id` - a platform belongs to one
library and its entries reference that one - but a count that is only correct
because of a join elsewhere is a count that breaks when the join changes.

Full suite: still 1 of 25, unchanged.

This package is **build 109**.

**A platform can finally say which sections it belongs to.**

`platforms.domains` decides which browsers offer a platform, and the write path
never accepted it. `api_platform_payload()` handled the maker, the year and the
colour, and left `domains` to the column's own default - `hardware,software`.

So every platform added by hand was a hardware-and-software platform, whatever it
actually was. A VHS label, a bootleg cassette format, a disc format the shipped
feed does not carry: all offered under Software and Hardware, none under Video or
Audio, with no way to say otherwise short of editing the database. The shipped
platforms escaped only because the structure feed writes the column directly, so
the filters looked correct until somebody added their own.

`domains` is accepted now on create and update, as an array or a comma string.
Absent leaves it alone, so a PATCH of the name does not silently reset it.
Present and empty is **refused** rather than written: the column is a SET and
would take `''` happily, and a platform belonging to no section at all cannot be
filed under, browsed, or found again.

Full suite: still 1 of 25, unchanged.

This package is **build 108**.

**`non_empty` counted through every section at once, which is how the C64 kept
turning up in the Hardware filters.**

## The category list

A platform's root node is one row shared by every section - the C64 node is the
same row whether you are looking at its games or its hardware. The non-empty
check asked "does anything anywhere use this branch", so one C64 *game* marked
the C64 node occupied, and the C64 node then survived the filter in the
*hardware* list, where the machine has nothing at all. The dropdown offered a
branch that could only ever return an empty page - the exact thing the filter
exists to prevent.

Scoped to the same section the list itself is scoped to, through `v_items.domain`.

## The platform list

The same fault in the other dropdown, and it needed more than a scope: platforms
carried an `item_count` over every section, so the Video browser offered the C64
because the C64 has games. `GET /platforms` now takes `domain` to scope that
count, and `non_empty` to drop platforms it leaves at zero.

Counting through `v_items` rather than `items` is what makes the section
reachable at all - the domain lives on the category, not on the entry. That
needed its own ACL clause for the aliased view rather than a string edit of the
one built for `items`: `library_filter_sql()` takes a qualified column name, and
rewriting generated SQL by search-and-replace is how a filter ends up pointing at
the wrong column without anybody noticing. The function refuses any column but
`library_id` for precisely that reason.

Both flags are off by default. A picker for *filing* an entry needs the empty
branches and the empty platforms most of all.

Full suite: still 1 of 25, unchanged.

This package is **build 107**.

**A per-user preference store, and the first thing kept in it.**

New `user_prefs` table (migration 010) and `GET`/`PATCH /prefs`. A row per person
per key, cascading away with the account - the shape `notification_prefs` already
uses.

Not columns on `users`: the first of these is which view each browser section
opens in, the next will be something else, and a column apiece means a migration
apiece for settings individually worth almost nothing. Not the `settings` table
either, which holds instance configuration an administrator sets; mixing
per-person preference into it would mean every read had to say whose it was.

`PATCH` **merges rather than replaces**. A client setting one preference must not
clear the ones it has never heard of, which is what a whole-object PUT would do
the first time two clients disagree about the list. An empty value forgets a key,
so a preference put back to its default leaves no row rather than one repeating
what the default already says.

A name over sixty characters is refused rather than trimmed - a caller writing
one has a bug, and trimming would make two different keys collide silently - and
anything refused is named back in `meta.rejected` rather than swallowed.

Full suite: still 1 of 25, unchanged.

This package is **build 106**.

**The video and audio examples file themselves into a genre.**

They landed on Movies, TV Shows and Music - the branch head, not a genre -
because that was as deep as the tree went when they were written. It goes deeper
now, and an example sitting at the branch head is a worked example of the wrong
thing: it is the first entry anybody sees, and it teaches where entries go.

    Metropolis Nights      Movies    > Thriller
    Late Shift Detective   TV Shows  > Crime
    Nightbound Sessions    Music     > Jazz
    Analogue Horizon       Music     > Electronic

The audio seeder had `recordings` hardcoded for both records rather than reading
the example's own row, so it could not have filed them differently even with the
genres present. It reads the row now, like the video one.

Both seeders fall back to the branch above when the genre is missing. An instance
whose structure feed predates the genres has Movies and TV Shows and nothing
under them, and `continue` alone meant it got no examples at all - filing one
level up is worse than filing properly and much better than skipping. The
fallback is per kind, so a series lands on TV Shows rather than on Movies.

Full suite: still 1 of 25, unchanged.

This package is **build 105**.

**`non_empty` on the category list: only branches that hold something.**

An empty branch is exactly what a picker for *filing* an entry needs most - you
cannot file the first pinball game under Pinball if Pinball is not offered. It is
exactly what a picker for *filtering* does not need: an option that can only ever
return nothing. One endpoint serves both, so this is a parameter rather than a
change of behaviour, and it is off by default.

Computed from the distinct `category_path` values rather than by joining
categories to items on `LOCATE()`. There are a handful of distinct paths and no
index can serve that join, so this is one cheap scan and a set-membership test
instead of a row comparison per category per item. A branch counts as occupied
when anything is filed at it *or* beneath it - which is what makes Adventure
offer itself when everything under it is filed as Point and click.

Scoped by the caller's library access, and by `platform_id` when one is given, so
"which genres does the Amiga actually have" is one request.

Full suite: still 1 of 25, unchanged.

This package is **build 104**.

**A genre filter that spans formats, and Movies/TV Shows as a kind.**

## `genre=` asks about the branch, not one platform's copy of it

`category=` names one node in one platform's tree. That is right for hardware and
software, where the platform is part of the answer - an Amiga graphics card is a
different thing from a PC one, filed apart on purpose.

It is wrong for films and records. The tree is copied per platform, so Action
exists once per format, and `category=blu-ray-movie-action` means *action films
on Blu-ray* with the DVD and VHS copies sitting under different rows of the same
name. There was no way to ask for action films.

`genre=movie-action` matches every platform's copy at once, by `source_slug` -
what each copy carries to name the template it came from, and what is already
indexed. Everything at or beneath each copy is included, so `genre=adventure`
also finds what is filed under Point and click. Narrowing to one format is what
`platform=` is for, and the two combine.

`category_to_api()` now reports `source_slug`, which is what lets a client offer
a genre once instead of once per platform. Null for a branch somebody added by
hand - it has no template behind it and nothing to collapse with.

## kind accepts movie and tv_show

Both are real `category_role` values, so both are the same column test that
already answered machine and peripheral. Video needed it for the reason hardware
did: Movies and TV Shows are two different things to browse and were sharing one
list. `music` is accepted too, for symmetry, though audio has only the one branch
today.

Full suite: still 1 of 25, unchanged.

This package is **build 103**.

**Games and Applications get real trees - 32 more branches, so a shelf of Amiga
boxes divides into something a person would recognise.**

Games had four genres, one of which was Shoot 'em up and none of which was
Adventure. Applications had Graphics and CAD with Paint under it and nothing
else, so a word processor and a disk utility were both filed as "Applications".

    Games          Action, Adventure (Point and click, Text adventure),
                   Beat 'em up, Board and card, Educational, Fighting, Pinball,
                   Platformer, Puzzle, Racing, Role-playing, Shoot 'em up,
                   Simulation, Sports, Strategy

    Applications   Business and productivity (Database, Spreadsheet,
                   Word processing), Communications, Education and reference,
                   Emulation, Graphics and CAD (3D and rendering, CAD,
                   Desktop publishing, Paint), Music and audio (Sampling and
                   editing, Tracker and sequencer), Programming and development,
                   System software, Utilities (Backup, Disk and file tools),
                   Video

Pinball and Text adventure are on the list because they divide a retro shelf in a
way they would not divide a modern one. Point and click sits under Adventure
rather than beside it, because that is what it is a kind of.

The four rows that already existed keep their slugs and are re-placed rather than
replaced - a slug is what `source_slug` joins a library's copy back to its
template, and re-slugging Action would orphan every copy of it for no gain.

Checked, rather than assumed, across all four feeds at once:

- Every genre declares `role: other` and resolves to its branch's kind. A
  genre resolving to nothing would be invisible to both the stock pictures and
  the metadata sources, and silently so.
- **No game genre is machine-class gated.** A console game is still a game, and
  a `classes` value copied down from Applications would have hidden the whole
  Games tree from every console in the library.
- **Every application type stays `computer`-only**, matching Applications
  itself, so a Game Boy is not offered Desktop publishing.
- No branch in software, video or audio declares a stock picture. A declared
  picture beats the format rules, and the rules already know a boxed Amiga game
  looks different from a jewel-cased PC one.
- All 126 template category slugs are still unique. The slug is the global key -
  `structure_apply()` looks a category up by slug alone among the rows with no
  library - so a collision would not error, it would silently overwrite another
  section's branch.

Full suite: still 1 of 25, unchanged.

This package is **build 102**.

**Genres for films, series and records - 49 branches the video and audio sections
have been missing since they were added.**

Software has had Action, Platformer, Shoot-em-up and Strategy under Games from
the beginning. Video and audio had two branches and one branch respectively:
Movies, TV Shows, Music, and nothing beneath any of them. A shelf of four hundred
records that can only be filed as "Music" is a list, not a catalogue.

    Movies      Action, Adventure, Animation, Comedy, Crime, Documentary,
                Drama, Family, Fantasy, Horror, Musical, Mystery, Romance,
                Science fiction, Thriller, War, Western
    TV Shows    Animation, Children's, Comedy, Crime, Documentary, Drama,
                Factual, Fantasy, Mystery, Reality, Science fiction, Sitcom,
                Soap opera, Thriller, Western
    Music       Blues, Classical, Country, Dance, Electronic, Folk, Funk,
                Hip hop, Jazz, Metal, Pop, Punk, R&B and soul, Reggae, Rock,
                Soundtrack, World

Each carries `role: other` and inherits its kind from the branch above, which is
the shape software's genres already use and the reason `category_effective_role()`
walks upward. Confirmed rather than assumed: a Sitcom resolves to `tv_show`, an
R&B record to `music`.

**The slugs are prefixed - `movie-drama`, `tv-drama`, `music-rock` - because a
template slug is the global key.** `structure_apply()` looks a category up by
slug alone among the rows with no library, so a movie genre called `action` would
have collided with the game genre that already exists and quietly overwritten it.
Two of them are given explicit suffixes where slugifying the name produces
something nobody would recognise: Science fiction is `sci-fi`, not
`science-fiction`, and R&B and soul is `rnb-soul` rather than `randb-and-soul`.

**No genre declares a stock picture, deliberately.** A declared picture beats the
format rules, so putting one on Drama would have given a Blu-ray drama and a VHS
drama the same image - the rules already know that a film on Blu-ray comes in a
Blu-ray case and one on VHS in a slip. Checked both directions: no genre carries
`stock_image`, and a film resolves by format through them.

Metadata sources are unaffected. Seeding writes at the topmost branch of each
kind and lets it inherit downward, so this adds 49 branches and no provider rows
- Movies still covers every genre beneath it.

Sorted alphabetically and spaced by ten, so a genre can be slipped between two
later without renumbering the rest.

Full suite: still 1 of 25, unchanged.

This package is **build 101**.

**Three more pictures: a monitor, a memory board and an accelerator card.**

Displays, Memory and Accelerator had been inheriting the generic expansion card
from the group above them - honest, in that they are peripherals, and wrong about
all three. Each now declares its own.

The catalogue is 37 pictures across 74 files, 5.4 MB. Storage and the four drives
under it are still the outstanding gap: a hard drive shows a picture of a card,
because there is no drive in the shipped set.

Full suite: still 1 of 25, unchanged.

This package is **build 100**.

**Storage gains the four kinds of drive, and Input devices is just Input.**

    Peripherals
      Input              Gamepad, Joystick, Keyboard, Mouse
      Displays
      Storage            Hard drive, Floppy drive, Zip drive, Tape drive
      Adapters           Network adapters
                         Storage controller  SCSI, IDE, RAID
                         I/O card            Serial/parallel, Multi-I/O
                         Graphics card
      Expansions         Memory, Accelerator, Sound card
      Modifications      Modchip, Flash cartridge

Storage now holds the drives themselves, one level below the branch, the way
Storage controller holds SCSI, IDE and RAID. The two are worth keeping apart and
now visibly are: a Zip *drive* is a peripheral you own, and the card it hangs off
is filed under Adapters.

**Input devices is renamed and not re-slugged.** The slug stays `input-devices`,
because it is what `source_slug` joins a library's copy back to its template,
what the unique key is on, and what the stock-image repair matches on - changing
it would orphan every existing copy of the branch for the sake of tidiness. What
anybody reads is the name.

The four drives are in sentence case - "Hard drive", not "Hard Drive" - matching
"Graphics card", "Sound card" and "Network adapters" already in the tree. Zip is
Iomega's brand rather than an initialism, so it is not shouted.

They declare no picture of their own and inherit the generic card from
Peripherals, which is honest but not good: a hard drive is not a card, and there
is no drive picture in the shipped set to give them. Four more images would fix
it, and until then the fallback is at least not wrong about the kind of thing.

`classes` unchanged, so the console and handheld trees are still nine branches
apiece and see none of this. All three structure checks re-run clean.

Full suite: still 1 of 25, unchanged.

This package is **build 99**.

**The cards are grouped again, this time on what the card is *for* rather than on
where it physically sits.**

Two branches under Peripherals, beside the things that were never cards:

    Peripherals
      Input devices      Gamepad, Joystick, Keyboard, Mouse
      Displays
      Storage
      Adapters           Network adapters
                         Storage controller  SCSI, IDE, RAID
                         I/O card            Serial/parallel, Multi-I/O
                         Graphics card
      Expansions         Memory, Accelerator, Sound card
      Modifications      Modchip, Flash cartridge

The rule, stated so the next card has an obvious home: an **adapter** connects
the machine to something else - a network, disks, ports, a monitor - and an
**expansion** makes the machine itself more capable, with memory it did not have,
a faster processor, or sound it could not previously make.

Two placements are arguable and easy to flip if the rule reads differently to
you. A **graphics card** is filed as an adapter, on the grounds that it is
literally a display adapter and the thing it connects to is the monitor; the case
against is that a Picasso II makes an Amiga capable of resolutions it had no way
to produce. A **sound card** is filed as an expansion, because a Sound Blaster
gives a PC synthesis it did not have; the case against is the row of jacks on its
bracket. Each is one line in `structure/hardware_categories.json`.

Memory, Accelerator, Displays and Storage declare no picture of their own and
inherit the generic card from the group above them, which is checked rather than
assumed - the walk has to pass through the new mid-level nodes without stopping
at them, and a leaf that stopped early would show a blank card where a specific
picture exists.

`classes` still gates per row, so the console and handheld trees are unchanged at
nine branches apiece and neither is offered any of this.

Full suite: still 1 of 25, unchanged.

This package is **build 98**.

**Expansions is gone. Its branches sit directly under Peripherals, which is now
the only place a peripheral goes.**

Build 96 nested Expansions under Peripherals instead of merging it, on the
grounds that eleven direct children with a mouse beside a RAID controller loses a
distinction worth keeping. That was the wrong call to make unilaterally: the
complaint was that the tree offers two answers to "where does a card go", and
nesting still shows two branches. It now shows one.

Peripherals, in order: Input devices, Displays, Storage, Adapters, Memory,
Accelerator, Graphics card, Sound card, Storage controller, I/O card,
Modifications. Outside the case first, then what goes inside it, then what is
done to it. The cards that had been grouped under Expansions are still adjacent,
which is most of what that node was doing.

`classes` gates per row and is unaffected by where a row sits, so nothing
widened. Checked by building the tree each machine class would actually receive:
a computer gets 25 branches, a console and a handheld 9 apiece - Gamepad and
Joystick yes, Keyboard, Sound card and SCSI controller no.

`category_repair_roles()` keeps `expansions` in the list of hardware names it
recognises, although the shipped tree no longer produces that branch. That list
exists to repair instances whose feed predates the current shape, and one of them
is now any instance built before this build - a name matching nothing costs a
comparison, and removing it would strand exactly the trees it is for.

Full suite: still 1 of 25, unchanged.

This package is **build 97**.

**Expansions moves under Peripherals rather than beside it, and Packaging models
moves to Global.**

## Expansions is a kind of peripheral, not a rival to one

Both branches carried `role = peripheral`, sat at the same level, and differed
only in `classes` - so the tree offered two top-level answers to "where does a
card go", with nothing on screen to say which. Expansions is now a child of
Peripherals, and Peripherals' children are ordered outside-in: Input devices,
Displays, Storage, Adapters, Expansions, Modifications.

Not merged flat, which is what a first reading of the complaint suggests. That
would give Peripherals eleven direct children with a mouse beside a RAID
controller and no grouping left at all - the two top-level branches were
confusing, but the distinction they drew is real and worth keeping one level
down. Nesting removes the ambiguity without losing it.

`classes` still gates per row, so a Game Boy is offered Gamepad and Joystick and
none of the cards, exactly as before - the gate is on each branch and not
inherited from where it sits.

The branch keeps the name "Expansions" rather than gaining a clarifying
parenthetical. `category_repair_roles()` matches the shipped hardware tree by
lower-cased *name* when repairing an instance whose feed predates the kinds, and
renaming it would have quietly broken that path for a cosmetic gain.

## Packaging models is global

It sat under Software and never only meant software. The shipped set has always
carried VHS clamshells, vinyl sleeves and CD jewel cases beside boxed Amiga
disks, and the category picker on its own form deliberately offers all four
sections. Filing it under Software said something untrue about it, in the same
way listing Platforms under Hardware did before it was moved to Global for the
same reason.

The table is still `software_models`. Renaming it is a migration for no gain, and
the screen has said "Packaging models" throughout.

Software now holds Environments alone, which is right: what a machine can run is
a fact about software and about nothing else here.

Full suite: still 1 of 25, unchanged.

This package is **build 96**.

**Seventeen more hardware pictures, and - more usefully - the taxonomy can now
say which picture a branch's things get, so the next one is a line of JSON
rather than a case in PHP.**

## The structure feed decides

Until now a stock picture was chosen by role and format alone, and that works for
releases because the format *is* the shape: a Blu-ray really does come in a
Blu-ray case. It does not work for hardware. A sound card and a SCSI controller
are both `peripheral` on the same platform with the same media, and no rule
reading a media string can tell them apart. The thing that knows is the branch
the entry is filed under, and the branch had no way to say so.

Category rows in the structure files now carry an optional `stock_image`, held in
a new `categories.stock_image` column (migration 009) and inherited down the
branch - declared once on *Input devices*, it covers Gamepad, Joystick, Keyboard
and Mouse beneath it. It beats the format rules and the per-kind fallbacks, and
loses to a picture a curator uploaded for the branch.

Deliberately a second column rather than a reuse of `default_image_filename`.
That one holds a decision somebody made; this one is rewritten on every structure
import. In one column the import would either silently overwrite a curator's
choice or be unable to tell it apart from its own - so, two columns, and the
curator's wins.

A slug naming a picture the running release does not ship is ignored rather than
refused, on the way in and again on the way out. The feed can name pictures ahead
of the release that adds them, and an instance that has not updated falls back to
the per-kind picture - the same thing that would have happened had the feed said
nothing.

Also carried into each library's own copy of the tree, which the copy statement
was not doing. `default_image_filename` deliberately is not copied - it names a
file on this instance's disk and a template has none - but a shipped picture
exists on every install by definition, so a template can safely name one.

## Sixteen new peripheral branches

`hardware_categories.json` grows from 14 rows to 30: Sound card, Storage
controller with SCSI/IDE/RAID beneath it, I/O card with Serial/parallel and
Multi-I/O, Input devices with Gamepad/Joystick/Keyboard/Mouse, and Modifications
with Modchip and Flash cartridge. Twenty-four of the thirty now name a picture.

Keyboard and Mouse are `computer`-class; Gamepad and Joystick are not, because a
pad is as much a console thing as a computer one. Flash cartridge is
`console,handheld`.

## A judgement call worth flagging

The `isa_` and `pci_` in these slugs describe the picture, not a rule about where
it may be used - the generic *Sound card* branch uses the ISA image on every
platform, Amiga included. An ISA sound card and a Zorro sound card are the same
silhouette at thumbnail size, and insisting on the difference would need a
picture per bus per function and still be wrong about the next machine. Anyone
who disagrees for a particular platform can set that branch by hand: the trees
are per-platform copies, so the Amiga *Sound card* branch is a different row from
the PC one and the existing picker already sets it.

## Applying it to an install that already exists

New maintenance job, **Branch pictures not carried into libraries**. A library
gets its copy of the tree when it is made, so one made before this version has
branches with nothing declared while their templates now declare something. The
repair copies the template's answer down, matched on the indexed `source_slug`,
and never touches a branch somebody has given a picture of their own. Branches
added by hand carry no `source_slug` and are left alone - they never came from a
template, so there is nothing to be out of step with.

The images arrived at mixed sizes with off-centre content and were trimmed to
their alpha bounds and re-centred at the same relative scale as the rest, so the
grid does not jump. Two of the seventeen - the compact graphics card and the PCI
network card - are variants no branch names, reachable only by picking them by
hand. That is on purpose rather than an oversight.

Full suite: still 1 of 25, unchanged.

This package is **build 95**.

**Hardware gets stock pictures after all - a beige desktop for machines, an
expansion card for peripherals - reversing the judgement in build 88.**

That build left hardware out deliberately, on the grounds that a generic
computer is a weaker claim than a generic DVD case: every keep case really does
look like that, and no two machines do. The reasoning still holds and is worth
keeping in the file, but it was the wrong call. What it left on a hardware shelf
was a grey rectangle saying nothing at all, and "this is a computer" is more
than nothing. The entry's own page already captions a stock picture as not being
a photograph of this copy, and the whole feature can be switched off, so nobody
is misled by it who does not choose to be.

Both are reached by kind alone, with no format rules above them. Hardware has no
packaging axis to vary on - what a machine "comes on" is not a question - so
every machine gets the same picture, which is the honest limit of what a generic
image can say here.

The two arrived 1536x1024 with their content off-centre, against a catalogue
that is uniformly 1024 square. They are trimmed to their own alpha bounds and
re-centred at the same relative scale the existing fifteen use, so a card does
not sit in a 3:2 frame among square ones and make the grid rows jump. 2.2 MB and
2.6 MB of PNG down to 163 KB and 104 KB of WebP, transparency intact.

Checked against the case that would have been easy to miss: a machine whose
platform slug is `cd`, or whose media reads `CD-ROM`, still gets the computer
rather than being dragged into the music or film rules. Role gates before format
does, so it never reaches them. The existing fifteen are unchanged, confirmed by
running the same twelve cases again.

Full suite: still 1 of 25, unchanged.

This package is **build 94**.

**The already-installed check from build 88 exempted the one machine it needed
to cover.**

`api_link_refusal()` learned to refuse a peripheral already fitted somewhere -
and then exempted the machine being edited:

    if ($fittedIn !== null && (int) $fittedIn['parent_item_id'] !== (int) $machine['id'])

So a card in another machine was correctly withheld, and a card in *this* one was
still offered. That is the only case anybody actually meets: you open an Amiga
2000, see the BigRAM 2008 listed under Installed peripherals, and find it in the
picker below as though it were free. The exemption was written for the
peripheral's own form, which asks the same question from the other end and needs
its current host to stay selectable - but that screen already re-offers the host
itself, so nothing needed the exemption at all.

Refused now whenever the part is fitted anywhere, with the two situations
worded apart: "already installed in Amiga 2000" when it is here, and "already
installed in X. Remove it from there first" when it is elsewhere.

Full suite: still 1 of 25, unchanged.

This package is **build 93**.

**Compatibility is editable at last - both halves of it. The three tables have
been enforced since they were added, against lists nothing outside the engine's
own interface could supply.**

`api_link_refusal()` consults `effective_compatibility()` before letting a card
into a machine, and has done throughout. But `item_to_api()` reported neither
`item_compatibility` nor `item_environments`, and `hardware_model_to_api()`
reported no `model_compatibility` - so the rule was running against data no
client could read or write. A rule enforced on data nobody can edit is worse
than no rule at all: it refuses, and the person refused has nowhere to go and
correct it.

- `item_to_api()` gains `compatibility` and `environments` behind the detail
  flag, with the rest of the per-row lists. `compatibility` carries the
  effective answer, the names, `from` (`model`/`item`/`none`), and
  `own_model_ids` - what the entry itself says as against what it inherits. A
  client drawing tick boxes needs that last one: the boxes edit the item's own
  list, and pre-ticking an inherited answer would make clearing a box appear to
  do nothing.
- `POST`/`PATCH /items` accept `compatibility` and `environments` as id arrays,
  through `api_apply_item_lists()` beside media and links. Replaced wholesale
  when the key is present, left alone when absent - so an empty array clears and
  an omitted key preserves. Environments are constrained to the entry's own
  library, matching what `sync_item_environments()` enforces for the web form.
- `hardware_model_to_api()` gains `compatible_model_ids`, and both write
  endpoints accept it. This is the authoritative half: a model's list beats a
  card's own, because a copy of a BigRAM 2008 cannot fit something a BigRAM 2008
  does not. A machine sending one is **refused** rather than ignored - a machine
  is what things fit into, and accepting the list would be recording the
  relationship backwards.

Silence still means "any machine on its platform" everywhere, which is what it
has always meant here - ticking nothing is not the same as fitting nothing, and
reading it that way would refuse every properly-filed card in a fresh catalogue.

Full suite: still 1 of 25, unchanged.

This package is **build 92**.

**Three more gates carrying the same unreachable administrator exemption the
admin gate had - found by looking for the shape rather than waiting for the
symptom.**

`api_require_admin()` was fixed in build 88: it called `api_require_write()`
first, which requires a library *membership*, so an administrator promoted by an
LDAP group was refused before the role was ever consulted. Three more functions
had the identical structure, and each had an explicit administrator exemption
written on the line immediately after the check that made it unreachable:

- `api_require_curates_library()` - the category tree, locations, companies
- `api_require_owns_library()` - hardware and packaging models
- `api_require_curates_any()` - tags

Every one reads `if (!is_admin_user(...) && !can_...)`. The exemption was
written, deliberately, for exactly the accounts that could never reach it. All
three now take `api_require_auth()` plus `api_guard_mutation()` - the same CSRF
and write-scope rules as any other call - and then ask the question they meant to
ask. Membership is still the whole of a non-administrator's access, which is the
part `acl.php` means to be strict about, and the gate was checked against an
ordinary account with no memberships to confirm it still refuses.

Full suite: still 1 of 25, unchanged.

This package is **build 91**.

**Pictures can now be filed as the publisher's artwork or as somebody's own
photograph, from outside the engine - the axis `item_images.provenance` has
carried since it was added, and which nothing but a metadata agent could ever
set.**

`store_item_images()` has taken a `$provenance` argument throughout and
`image_to_api()` has reported it throughout. What was missing was any way in:
`api_item_images_upload()` read `kind` from the request and hardcoded the other
half, so a scraper could file the publisher's box art as official and a person
scanning that same box by hand could not. One of the two axes was writable and
the other was not.

- `POST /items/{id}/images` accepts `provenance`, on both the multipart and the
  base64 paths. Anything that is not exactly `official` is `personal` - the safe
  direction, since mistaking somebody's snapshot for the publisher's artwork
  misrepresents it while the reverse merely under-claims. The base64 path was
  also never writing the column at all, so every picture that arrived that way
  took the schema default regardless of what was asked for.
- `GET /items/{id}/images?provenance=` filters to one side, for a client drawing
  two galleries.
- `PATCH /images/{id}` accepts `provenance`, so a picture can be moved between
  the two without being deleted and re-uploaded - it keeps its id, its caption,
  and its place as the cover. Here an unknown value is **refused** rather than
  rounded down: a move that silently did nothing would read as the request being
  ignored, which is a different bug to chase than a validation error.

Full suite: still 1 of 25, unchanged.

This package is **build 90**.

**Packaging models can now say what they are for. The three child lists the
`software_models` table was designed around - the fields a title is asked, what
the box should hold, and what it comes on - are exposed by the API and writable
through it for the first time.**

The tables have existed throughout and the engine's own screen has edited them
throughout. What was missing was the API: `software_model_to_api()` returned a
name, a platform, a category and a note, and `api_software_model_payload()`
accepted the same four. So every client other than the engine's own interface
saw a packaging model as a label with nothing behind it - which is what a
"Packaging models" page with no packaging on it amounts to.

`GET /software-models/{id}` now carries `fields`, `contents` and `media_list`.
The index carries `field_count`, `content_count` and `media_count` but not the
lists: three child queries per row would be a hundred and twenty of them to draw
a table of forty models that shows none of it. The counts come down as
subqueries on the one statement rather than being filled in per row afterwards.

POST and PATCH accept all three. Each list is replaced wholesale when its key is
present and left entirely alone when it is absent - the engine's own rule, and
the hardware model editor's beside it: the rows that arrive are the model's
complete answer, and merging them with what was there would invent a third list
nobody wrote. Absent and empty stay different instructions, which is what makes
`PATCH {"name": "..."}` safe and still lets a list be emptied with `[]`.

A row with a blank label is dropped rather than refused, because a form that
keeps a spare row at the bottom to type into posts an empty trailing row every
time and that is the ordinary state of the thing.

Media rows are checked against `media_option_values()`, the same vocabulary the
engine's own select is built from - free text there is how a library ends up
holding both `3.5" disk` and `3.5 inch disk` and being able to count neither. An
unrecognised medium is dropped and **named back** in `meta.media_ignored` rather
than refusing the whole save: a model that saves with one row fewer than was sent
looks exactly like a save that failed, and silence there is the worst of both.

`GET /meta` now carries the media vocabulary, grouped as the engine groups it, so
a client can build the same select instead of hardcoding twenty strings and
drifting out of step with the validator that will silently drop them.

`software_model_media()` joins its two siblings in models.php. Both existing
callers had written the query inline, which is part of why the API had no obvious
thing to call.

`media` and `year_from` remain readable and remain unwritable, matching the
engine's own form: the media list is a child table now, and the year belongs to
the title rather than to a shape of release. The columns stay so an old value is
still readable.

Full suite: still 1 of 25, unchanged.

This package is **build 89**.

**Fifteen generic packaging pictures now ship with the package, and an entry with
no photograph of its own falls back to whichever one matches what it is - plus
four real bugs found and fixed along the way, three of them pre-existing and one
of them the reason metadata lookups on films and records found nothing at all.**

## Generic pictures for entries with no photograph

A catalogue with no photographs in it is a wall of grey rectangles saying "no
photo yet", and most catalogues start that way: an agent finds cover art for the
famous releases and nothing for the rest, and photographing two hundred boxes is
a weekend nobody has. `public/stock/` now holds fifteen blank mock-ups of the
packaging itself - a big box, a jewel case, a VHS in its slip, a record half out
of its sleeve - re-encoded as WebP with their transparency intact, 21 MB of PNG
down to 2.1 MB with no visible loss. Quantised PNG was tried first and rejected:
the gradients and drop shadows posterise.

`cover` now resolves in three steps rather than two - a real photograph, then the
branch's own picture, then a generic one - and reports which answered in a new
`source` field (`photo`, `category`, `stock`, or null). `is_default` keeps its
old meaning exactly, so a client reading only that needs no change.

The stock step sits *below* the branch's own picture deliberately. Setting a
picture on a branch is something somebody did on purpose; this is an automatic
guess, and if the guess won, the deliberate act would be an override that
overrode nothing.

Nothing is written to the database. A `stock:` reference is resolved at read
time by `image_url()`, so an entry that gains a real photograph tomorrow stops
resolving to one on its own and there is no cleanup to forget. The files sit
outside the uploads directory entirely: they are part of the package, identical
on every install, restored by a redeploy for free, and invisible to everything
that manages uploads.

Which picture is chosen comes from what the entry already says - its kind, what
it comes on (media rows first, then `media_type`, then the platform, which for
the video and audio sections *is* the format), and whether `completeness` says
`loose`, which is the whole reason the bare-tape and bare-disc pictures exist.
Twenty cases were run against the real matcher rather than reasoned about,
including the two that collide by substring: a game on CD-ROM correctly gets the
big box rather than being caught by the music CD rule, and "VHS tape" correctly
matches VHS rather than cassette.

Hardware gets nothing, on purpose. A generic picture of "a computer" is a lie
about a specific machine in a way that a generic picture of a DVD case is not.
Software gets one picture per kind rather than one per era, because the big box
is what boxed software looked like across every platform this catalogue covers.

`GET /stock-images` lists them, and `POST /categories/{id}/image` now accepts a
`stock` slug as well as a file, so a branch can be pointed at one deliberately
without uploading a copy. Stored as a reference, so removing it later deletes no
file and leaves every other branch pointing at the same one alone. The whole
feature can be switched off with the new `stock_images` setting, which is an
honest position: a generic picture describes a format, not an object.

## Metadata lookups on films, series and records asked no source at all

Looking up a film against an instance with TMDB configured and working found
nothing, and logged nothing - which read as a broken source and was in fact a
question that was never asked.

`seed_library_provider_scopes()` enumerated four kinds: machine, peripheral,
game, application. Video and audio branches were never given a `provider_scopes`
row, so `providers_for()` returned an empty set for them, so `metadata_search_all()`
consulted nobody. This is the same gap `category_effective_role()` had and had
fixed - roles were added to the template data and the lists that enumerate them
were not extended to match - and it is the third time that particular omission
has surfaced.

The kinds list is fixed, but that only helps libraries seeded afterwards, so
there is now a maintenance job - **Branches no source is switched on for** - that
reports every top-of-kind branch nothing is switched on for and repairs them by
running the same seeding, which only ever adds and never overrides a decision
somebody has made.

And the message was wrong in a way that hid the cause. "No source recognised that
title" is a claim about what the sources answered; the truth was that there had
been no question. `metadata_search_all()` now returns a `consulted` count, and
both lookup screens say "No source was asked" when it is zero, naming the two
places to fix it.

## An administrator from a directory could reach no admin screen

`api_require_admin()` called `api_require_write()` first, which requires library
membership. That is deliberate for libraries - `acl.php` says so, so that an
administrator does not silently acquire the ability to read everybody's private
shelves - but instance administration has nothing to do with it. An account
promoted to administrator by an LDAP group mapping has no membership anywhere, so
every instance endpoint answered 403 "This account has no library it is allowed
to change" to a genuine administrator. The web interface showed the admin menus,
because it asks the role; the API refused them, because it asked membership.

Worse, the same fact had already downgraded their token: both sign-in paths
issued a read-only token to any account that `can_edit_anything()` said no to, so
the token was refused even for reads on those screens.

Fixed in three places. `api_require_admin()` now applies the CSRF and write-scope
guards - factored out as `api_guard_mutation()` - and the admin role, and does
not consult membership. The write-scope guard is asked per method rather than per
endpoint, so a read-only token may now read admin screens, which are all GETs,
and still cannot write. And both token paths make an administrator an exception
to the downgrade.

## A peripheral already installed somewhere was still offered

`api_link_refusal()` checked domain, kind, compatibility and platform, and never
asked whether the part was already fitted. So the picker on a machine's edit page
listed every peripheral in the library including the ones already inside other
machines - and choosing one did not merely record something false, it hit the
`uq_fitted_once` key the schema already carries and failed. The rule was
enforced; it was just enforced at the worst possible moment. Now refused by name,
saying where the part currently is, which corrects the picker and the write path
together.

## Category default pictures were deleted by the orphan sweep

Both `bin/cleanup-uploads.php` and `maintenance_upload_is_orphan()` built their
set of referenced filenames from three tables and there are four:
`categories.default_image_filename` was never counted. A picture uploaded as a
branch default read as an orphan, and the repair deletes what the check reports -
so uploading one and later running the sweep deleted the file and left the row
pointing at nothing. Pre-existing, unrelated to the stock pictures, and found
while checking that the new shipped files could not be eaten the same way. They
cannot: they are not in the uploads directory.

## Renames

**Logs** is now **Instance Logs** and **Maintenance** is now **Instance Status**,
in both the engine's own interface and the web client.

Full suite: still 1 of 25, unchanged.

This package is **build 88**.

**A full audit of `structure/`, checked against everything built this session rather than
assumed current - found and fixed one real, genuine gap.**

`structure/metadata_agents.json` - the canonical home for a provider's own tested-platform list
and default-kind assignment - never got a MusicBrainz entry. The provider itself works correctly
regardless, since the code carries a matching hardcoded fallback, but the file that's supposed to
be the real source of truth for this data was simply never updated when the provider was added.
Added, matching the same shape TheAudioDB's own entry already uses.

Everything else checked came back genuinely correct, not just assumed so: all twelve packaging
models present and correctly linked to their real platforms; both audio and video category files
using the extended role values; all seven video/audio platforms present; the hardware role fix
for memory, graphics cards, and accelerators still holding; a real `director` credit role
present for the credits feature to use. Confirmed by actually running a fresh `structure_sync()`
against a real database and reading its own summary, not by eyeballing the JSON files alone -
every one of the fifteen structure types synced with zero errors, and MusicBrainz's own
`tested_with` and `default_for_kinds` confirmed genuinely populated from the file after the fix,
not merely believed to be.

Full suite: still 1 of 25, unchanged.

This package is **build 87**.

**A real metadata source for music - MusicBrainz, read from their own documented API and
respecting both requirements their docs call out explicitly rather than treating as optional:
a meaningful User-Agent (their docs are specific that an anonymous one is throttled separately,
on top of the ordinary rate limit) and roughly one request per second per IP, the strictest of
the three rate checks they describe. The rate limit here is set deliberately closer to a full
second than the shorter delay other providers use, matched to what their own docs actually say
rather than reused from a source with a more generous limit.

A genuine release-level search, not an artist-only one - title, artist, label, catalogue number,
country, format, and where the release actually carries one, a real barcode. The first metadata
source in this catalogue able to fill that field in at all; `metadata_to_item_fields()` gained
barcode support alongside this provider, closing a gap that's existed since the field itself was
added several rounds back with nothing populating it.

Refuses outright, with a clear reason, when no contact URL or email is configured - not a
convenience refusal but their own API's real requirement, surfaced honestly rather than sending
a request likely to be throttled.

Proved live against a response shape built from MusicBrainz's own confirmed documentation
examples, not guessed: a full successful parse including the real barcode and catalogue number;
the User-Agent header confirmed correctly formed and sent; every real failure path checked - no
contact configured, a genuinely empty result, and a network failure, each handled and reported
rather than swallowed.

Full suite: back to 1 of 25 on the first attempt this time, not after a follow-up fix - confirmed
by name, not just by count.

This package is **build 86**.

**`item_specs` - a real, working way to write a non-hardware entry's own spec rows through the
API, closing what the previous round left as data with nowhere real to be written.**

Worth being direct about how this actually went: a first attempt at this landed the new handling
inside the wrong function entirely - `api_apply_item_hardware()`, which is called after an item
already exists and only ever writes to `item_hardware`. Setting a `specs` value there built a
variable nothing read; the item saved successfully and the field stayed null, silently. Found by
testing the actual write, not the code that looked right - a live PATCH request confirmed the
value never reached the database, which is what led to tracing it to the wrong function. Moved to
`api_item_input()`, the function whose return value genuinely reaches the `items` table, and
given its own accumulated-error handling to match every other field around it rather than the
hard-exit-on-first-problem behaviour it briefly had.

Proved live end to end this time, not just at the API boundary: a real spec row applied through a
direct PATCH, confirmed in the database; the same thing again through the real web form -
submitted, confirmed stored, confirmed pre-filling correctly on a second edit, confirmed showing
on the entry's own page. A hardware entry's own form confirmed unaffected throughout.

`docs/openapi.yaml` updated with the new field. Full suite: back to 1 of 25, unchanged.

This package is **build 85**.

**A real schema change: `items.specs`, so every domain has somewhere to keep a metadata
lookup's own genre, director, running time, or catalogue number - not just hardware.** A JSON
column, same shape as `item_hardware.specs`, added with a real migration
(`008_item_specs.sql`). Hardware keeps its own dedicated column rather than sharing this one -
`item_hardware.specs` belongs to the hardware detail row itself, a genuinely separate record
from the item, and splitting a machine's specs across two places would be worse than the two
columns existing side by side.

`metadata_spec_rows()` and `metadata_apply_specs()` now check hardware's own detail row first,
falling through to the entry's own column when there isn't one - no domain lookup needed, since
only one of the two places can ever hold a row for a given entry. The hardware-only gate on both
the preview and apply endpoints is gone, now that there's somewhere real for a non-hardware
entry's spec rows to land rather than nowhere at all.

**Two real regressions caught by the full suite and fixed before anything shipped, not
discovered later.** This project keeps a hardcoded, exhaustive list of every column the `items`
table is expected to have, specifically so an unclassified column - one added without anyone
remembering to say what it's for - gets caught immediately rather than drifting unnoticed;
`specs` is now on that list. Separately, three metadata providers added earlier this session
(TMDB, TheTVDB, TheAudioDB) had shipped with an empty, unfilled `tested_with` placeholder - real
platform slugs belong there for any source that doesn't filter by platform itself, the same real
list `structure/metadata_agents.json` is the canonical home for. Filled in properly, in both the
structure data itself and the code's own fallback default, not just whichever one the failing
test happened to read.

Proved live, with real database confirmation, not assumed from the code: a movie's genre and
director applied through the real API landed in `items.specs`, with zero `item_hardware` rows
created for it; a machine's chipset and RAM, applied the same way, correctly still landed in
`item_hardware.specs` with `items.specs` left untouched - the regression check that actually
matters here, confirmed rather than assumed safe.

Full suite: back to 1 of 25, the same baseline as every round tonight - confirmed by name, not
just by count, that the two real failures this round found are genuinely gone and nothing else
broke alongside them.

This package is **build 84**.

**`GET /admin/metadata-providers`'s own `meta.types` gained a `credentials` field - the piece a
client needed to render a provider's api_key as a real, labeled, masked field rather than one
more row in a generic list.** The `credentials` metadata itself has existed on every provider
that needs one (TMDB, TheTVDB, TheAudioDB) since each was added, but was never actually reachable
through the API - server-side data describing a shape nothing outside the server could read.
Closed the same way the last few gaps this session were: found by checking what already existed
before building anything new, not assumed missing.

`docs/openapi.yaml` gained real documentation for this endpoint too, which previously had none
beyond a bare "200: OK".

Full suite: still 1 of 25, unchanged.

This package is **build 83**.

**`item_kind_label()` now recognises `movie`, `tv_show`, and `music` - closing a gap flagged
explicitly, more than once, as deliberately deferred earlier this session rather than fixed on
the spot, now actually closed.** The function already correctly returned `machine`, `peripheral`,
and `game` from a category's own declared or inherited role; `movie`, `tv_show`, and `music` sat
in the same role enum, recognised everywhere else added this session (the category tree's own
Kind picker, the role-based category filter, the platform-matching "Add a movie" entry point) but
never here, where it silently fell through to an empty string on every video or audio entry.

A small, related polish caught while fixing this rather than left half-done: `kind_label`, the
capitalised version this powers, used a bare `ucfirst()` that would have rendered `tv_show` as the
literal "Tv_show" - an underscore left in a display label. A small, explicit map instead of a
generic transform, so "TV" reads as the acronym it is.

Proved live against real seeded entries, not assumed from the code alone: a movie and two
different music entries confirmed showing `kind`/`kind_label` correctly populated for the first
time, while a machine and a game were confirmed unaffected - a genuine regression check, not just
new coverage. The TV-show label specifically checked at the function level too, since no seeded
entry of that kind exists to fetch through the API.

A real mistake caught before it shipped, worth naming rather than glossing over: the first attempt
at documenting this in `docs/openapi.yaml` mixed YAML's flow and block styles in a way that's
invalid together, breaking the file outright - caught immediately by validating it, not assumed
correct because the edit looked reasonable.

Full suite: still 1 of 25, unchanged.

This package is **build 82**.

**Round 2 of the title/credits system: metadata lookups can now write real, linked credits -
`GET /metadata/preview` gained a `credits` field, closing the actual, narrow gap once a check of
what already existed turned up more than expected.**

Before writing anything, `metadata_apply_credits()` - the function that turns a candidate's
credits into a real row linked to a title, auto-creating the title itself if none is linked yet -
turned out to already exist and work correctly. So did TMDB's own candidate builder, which has
been populating `candidate['credits']` with the director since the round that added TMDB itself;
an earlier summary calling this an unbuilt gap was simply wrong, and worth saying so plainly
rather than letting stand. The one thing genuinely missing: the preview endpoint never surfaced
`candidate['credits']` at all, so nothing on a review screen could ever show or offer it, however
complete the write side already was.

Proved live, twice, with real database confirmation rather than trusting the API's own response:
a director credit applied to a movie already linked to a title landed as a new, real row
alongside an existing one, not a replacement; the same credit applied to a completely unlinked
item correctly auto-created a title from the item's own fields and attached the credit to it.

`docs/openapi.yaml` updated to match. Full suite: still 1 of 25, unchanged.

This package is **build 81**.

**`GET /hardware-models` gained `?platform_id=` filtering** - the same narrowing
`/software-models` already had, needed for the client's own new "known model" picker on the
item form to filter its list to the platform already chosen, rather than showing every
catalogued hardware model regardless of machine.

`docs/openapi.yaml` updated to match. Full suite: still 1 of 25, unchanged.

This package is **build 80**.

**`GET /admin/system-status` gained `top_clients` - up to ten of the most recently active real
devices, with the account they belong to and the IP address they were last used from.** Built on
`api_tokens`, the only table that actually tracks individual devices with an address - a token's
own last-seen stamp, not a request-count table this endpoint didn't otherwise have. Revoked
tokens excluded, since a device already cut off has nothing to say about who is using the
instance now. Named honestly rather than oversold: this is "most recently seen," not "most
active" in any volume sense - the table behind it has no per-device call tally to rank by.

Proved live: real tokens inserted, including one deliberately revoked, and confirmed the
endpoint returns the two live ones with correct account, IP, and timestamp while genuinely
excluding the revoked one - not merely assumed from the query.

`docs/openapi.yaml` updated to match. Full suite: still 1 of 25, unchanged.

This package is **build 79**.

**A real metadata source for music - TheAudioDB, and a genuine correction of what the free key
actually does versus what its docs describe, checked by hand against the live API rather than
taken on faith.** Their own documentation's search-by-album method (`searchalbum.php`) and
discography listing (`discography.php`) both looked like the obvious fit for "add a music
record" - tried both directly against the real, live API using the exact example from their own
docs, and both come back essentially unusable on the free key: `searchalbum.php` refuses outright
even on their own documented example, and `discography.php` answers with a single, id-less album
carrying no artwork at all. What the free key does answer well, confirmed the same way, is a plain
artist search - real biography, genre, style, record label, and genuine artwork.

Built around what actually works rather than what the docs suggested first: an artist lookup, not
an album-specific one. Documented plainly in the provider's own description, not left for someone
to discover the hard way - a candidate's title reads as the artist's name, and the record label
comes through correctly as the "publisher"/"label" field this catalogue already uses for audio
entries.

Proved live against the real response shape captured directly from the API, not a synthetic
guess - genre, style, country, biography, three separate images, and the real front-end URL
pattern (confirmed by search, not assumed) all mapped correctly. Every real failure path checked
too: no key, the confirmed live shape for no matches, and a network failure, each handled and
reported honestly rather than swallowed.

Full suite: back to 1 of 25, the same baseline as both metadata additions before it.

This package is **build 78**.

**A real metadata source for TV shows - TheTVDB, read straight from their own v4 OpenAPI spec
rather than assumed.** A genuinely different shape from TMDB's own provider: TheTVDB requires a
separate login step first - the API key is exchanged for a JWT bearer token, valid for a month
per their own docs, rather than being sent as a static credential on every call the way TMDB's
own key works. The token is cached rather than fetched fresh on every search - proved directly, not
assumed: a second search against the same key made exactly one request, not two, confirming reuse
actually happens rather than merely being intended.

TheTVDB's own search index turned out to already carry most of what a candidate needs directly -
overview, year, network, genres, a poster - so unlike the movie provider, no second details call
per result. Network stands in as the answer to "whose is this," the same way a film's own studio
does - a network commissions a show rather than producing it in the film sense, but it's still the
one-word answer this field means everywhere else in this catalogue.

Declares no platform opinion, the same reasoning the movie provider already has - a series has no
real per-machine release the way a game does.

Proved live against realistic response shapes for the full flow and every real failure path:
login then search on a cold cache, confirmed making both requests with the correct bearer token
on the second; a second search against a warm cache, confirmed making only the search request,
not a second login; a missing key refused outright; a login itself failing with 401, surfaced
rather than swallowed; a genuinely empty result set returned cleanly.

Full suite: back to 1 of 25, the same baseline as the movie provider before it - confirming this
addition, unlike the near-miss two rounds back, left nothing else broken.

This package is **build 77**.

**A real metadata source for movies - The Movie Database (TMDB), read straight from its own API
docs rather than assumed.** Search, then a details call per candidate for what the search
endpoint doesn't carry - overview, runtime, genres, production companies, and the director by way
of `append_to_response=credits`, all in the same request rather than a second round trip.
Authenticates with TMDB's own Bearer-token method, the one their docs recommend over the shorter
v3 key. Poster and backdrop both come through as real candidate images, at real, appropriately
different sizes - a poster wants to be seen fully; a backdrop is worth a smaller preview.

Declares no opinion on platform - a film has no real per-machine release the way a game does, so
`metadata_rank_results()` correctly falls back to title closeness alone rather than being handed a
comparison it has nothing to answer.

**Worth being direct about a real, severe near-miss caught before it went anywhere**: an editing
mistake while inserting this new provider left `metadata_search_wikipedia()`'s own function
signature stripped from the file, its entire body orphaned as an unreachable block that `php -l`
had no way to flag, since a bare `{ }` block is syntactically valid PHP on its own. Caught not by
linting but by directly searching the file for the function's own name and finding nothing -
wikipedia lookups would have silently, completely stopped working the moment this shipped. Fixed,
and the full test suite was run specifically to confirm the fix actually took, not merely assumed
to have.

Proved live against realistic response shapes for both success and every real failure path TMDB's
own docs describe: a working search and details call parsed correctly end to end, including a
director found through the appended credits; a missing API key refused outright with a clear
message; a real, live TMDB behavior worth knowing - it answers a bad key with an ordinary 200 and
a `status_code`/`status_message` pair rather than an HTTP error - correctly surfaced rather than
silently swallowed; a genuinely empty result set returned cleanly with no error at all.

Full suite: back to 1 of 25 - the same baseline, now including live confirmation that the near-miss
above left nothing broken.

This package is **build 76**.

**`software_models` gained platform filtering and the `media`/`year_from` fields it always had at
the schema level but never exposed - closing the gap for a real "pick a packaging shape" feature
on the client.** `media` in particular is what the new picker needs to actually do anything -
found missing while building it, not assumed present.

Proved live: the endpoint's real response now carries `media` for every one of the twelve
templates this repo ships; `?platform_id=` correctly narrows the list to one machine's own
shapes rather than returning all twelve regardless of what's being asked for.

Full suite: still 1 of 25, unchanged.

This package is **build 75**.

**Seven real packaging templates added for video and audio - VHS clamshell, LaserDisc, DVD, Blu-ray,
vinyl sleeve, CD jewel case, cassette - reusing `software_models` rather than inventing a parallel
table.** The table's own schema was already genuinely domain-agnostic (platform, category, media,
name - nothing hardware- or software-specific about any of it), and the column that references it
(`titles.software_model_id`) already carries no domain restriction either; a video or audio title
could already point at one of these rows, it just never had any to point at. Renaming the table
itself to something less misleading was considered and set aside - the "music" section rename
earlier this session showed exactly how much a rename like that can touch, and the functional
need here doesn't require it.

Each new model carries real specifications and real contents, the same as every other model this
repo ships - this repo's own test suite checks both are present on every shipped row, and would
have refused a version that only had a bare name and platform.

Proved live: a fresh `structure_sync()` added all seven with zero errors; every one confirmed
carrying both fields and contents; every one confirmed linked to its own real platform (VHS, DVD,
Blu-ray, vinyl, CD, cassette, LaserDisc) rather than left dangling.

Full suite: still 1 of 25, unchanged.

This package is **build 74**.

**`GET /categories?role=` fixed to use the effective, inherited role - the foundation for the new
"Add a game"/"Add a machine" style entry points, and a real, significant bug on its own.** The
filter only ever compared a row's own literal `role` column, never the inherited value
`category_effective_role()` already computes - the same walk `item_kind_label()` uses to decide
what an entry itself is. Since the ordinary case is a branch declaring its kind once at the top
and letting everything below inherit it, the old filter answered "what can I file a game under"
with only the handful of branches that happened to say `game` on their own row, missing every
leaf that inherited it - which, on a real library, is most of them.

Extended the same filter's own whitelist to the full role enum - `game`, `application`, `movie`,
`tv_show`, `music` - alongside the `machine`/`peripheral`/`other` it already had. `role` on
`POST`/`PATCH /categories/{id}` already gained these in an earlier round; this closes the read
side to match.

`docs/openapi.yaml`'s own documentation for `GET /categories` was close to nonexistent - no query
parameters described at all despite four being real and load-bearing. Documented properly.

Proved live against a real seeded library: `role=game` correctly returned 45 categories (not the
single branch that declares it directly), `role=music` returned real audio categories, and
`role=machine`/`peripheral` were confirmed unaffected by the fix - a genuine regression check, not
assumed safe.

Full suite: still 1 of 25, unchanged.

This package is **build 73**.

**Audio, actually fixed at the root - `structure/music_categories.json` renamed to
`audio_categories.json`, closing a real bug the client-side rename alone left standing.**

The `sections` table itself already read "audio," with a comment explaining exactly why -
audiobooks and podcasts are audio, and neither is music. What that comment didn't anticipate:
`structure_sync()` derives which section a category file belongs to from the file's own name
(`music_categories.json` looks up a section slugged `music`). With the section genuinely renamed
to `audio` and the file still called `music_categories.json`, every attempt to seed the audio
branch of the category tree failed outright with a foreign key violation - caught live, not in
review, the moment a real seed was attempted end to end. Fixed by renaming the file itself and
the four places in `structure.php` that reference it by name, matching the same
file-name-declares-section convention every other domain already follows.

**`role` extended to accept `movie`, `tv_show`, and `music`** - `POST`/`PATCH /categories/{id}`
only ever accepted the hardware/software half of the kind enum; a branch could never be set to a
video or audio kind through the API at all. Now cascades its section exactly the way
machine/peripheral and game/application already do - `movie`/`tv_show` move a branch into Video,
`music` moves it into Audio.

Proved live: a fresh `structure_sync()` seeded the audio category branch with zero errors,
confirmed against the real database; the API's own role-update endpoint confirmed accepting
`music` and correctly cascading the section.

`docs/openapi.yaml` updated to match. Full suite: still 1 of 25, unchanged.

This package is **build 72**.

**A real, pre-existing gap found while checking the full suite after unrelated client work -
`GET /directory` was never documented in `docs/openapi.yaml`, caught by this repo's own
completeness test.** Fixed. Nothing about the endpoint itself changed.

This package is **build 71**.

**"What a library holds" - `GET /libraries/{id}/contents`, a client for the real app's own
library_contents_index() and library_contents_summary(), built for the same reason the real app
built it: a bare item count is a poor thing to make a delete decision against.** Every entry,
paginated, plus the platforms, makers, models, and places the library defined for itself - the
things people forget a library owns until it's gone. Owner or instance administrator, matching the
real app's own comment about who should see this: it was administrator-only originally, which that
comment itself calls the wrong way round.

Proved live with real data, not assumed: the endpoint correctly returned 14 real entries, 16 real
platforms, 25 real companies, 6 real locations, 10 real hardware models, 5 real software models,
and the real owner membership, matching a genuinely seeded library exactly.

Worth being direct about the rest of this round's testing: this session hit severe, repeated
environment instability while proving this - the database process died mid-test more times than
any other round tonight, including within single, unbroken scripts. The core endpoint above was
directly, thoroughly proven with full real data despite that. What could not be completed was a
full live HTTP round-trip through the web client on top of it; that half was instead verified by
rendering the real client's own template directly against the exact data shape the live API had
already confirmed, which succeeded cleanly with no warnings - a genuine, if narrower, form of
proof than the live browser test this session has otherwise held to throughout.

A real regression caught by the full suite, the same shape as before: the new endpoint wasn't in
`docs/openapi.yaml`, caught by this repo's own completeness test, fixed, confirmed the suite is
back to 1 of 25 afterward.

This package is **build 70**.

**Public libraries are always read-only to join now - a real behavior change, not a rename.**
Confirmed against the current design in conversation first: the six access levels and the
private-library invite flow already matched what was described almost word for word: the one
genuine difference was that a shared library could previously be published two ways, read-only or
read-write, letting anyone who joined the general way become a Contributor outright. That option
is gone. Joining a public library now always grants Viewer, nothing more - a higher role for a
specific person still goes through the same invitation mechanism a private library already uses,
which grants any level up to Administrator and is entirely unaffected by this.

Fixed at the source rather than hidden behind a form: `library_visibility_flags()`, shared by
every path that can set this, no longer has a write-granting state - a caller that still sends the
old `public_write` value is treated exactly as `public` now, not refused and not silently
different. Every "set" site across both the still-live original app and the newer API-driven one
was checked and fixed the same way, not just one of them.

A migration clears the now-invalid state on any library that already carried it, rather than
leaving an upgraded instance able to show a state nothing can select or reproduce again.

Proved live: updating a library with the old, removed value now correctly leaves it read-only, not
refused and not read-write; joining it the general way was confirmed to grant Viewer and nothing
else; an administrator explicitly inviting somebody to Editor on that same public library was
confirmed to still work exactly as before - the two mechanisms are genuinely independent. The
migration itself was proved the same way every schema change has been this session: a real,
simulated old instance carrying the old state was correctly caught and corrected.

Full suite: still 1 of 25, unchanged.

This package is **build 69**.

**Five new endpoints, a client for the real app's own "Library access" page - what you already
have, what's waiting on an answer, and what's open to join.** `GET /profile/libraries` combines
all three tabs' worth of data in one call, matching the real page's own single render rather than
three round trips. `POST /libraries/{id}/join`, `/leave`, `/invite/{accept,decline}`, and
`/ownership/{accept,decline,withdraw}` are direct clients for library_join(), library_leave(),
and the invitation/ownership halves of library_admin_save() and library_ownership_respond() -
copied field by field, not re-derived, including the parts easy to get wrong: leaving is refused
on any personal library regardless of whose it is, not just this account's own; accepting an
ownership offer swaps both the owning column and the membership rows in one step, with the
outgoing owner kept on as an admin rather than dropped to nothing.

`library_to_api()` gained `access_label` - a human label for the raw access string every caller
already got, so a client never has to carry its own copy of what "curator" means.

Proved live, thoroughly, covering every real state rather than just the happy path: a real pending
invitation showed correctly and was accepted through the real endpoint, with the database
confirmed changed; joining a real published library correctly granted exactly what it offers, no
more; leaving was confirmed genuinely refused on a personal library even when it wasn't the
caller's own, and refused again on a library the caller owns outright; a real ownership offer was
accepted and the outgoing owner's own membership row was confirmed demoted to admin, not curator,
not removed.

A real regression caught by the full suite, the same shape as before: the new endpoints weren't in
`docs/openapi.yaml`, caught by this repo's own completeness test, fixed, confirmed the suite is
back to 1 of 25 afterward.

This package is **build 68**.

**Default category images - what an entry looks like with no photograph of its own, inherited
down the branch the same way "kind" already is.** `categories.default_image_filename`, migration
005; `category_effective_default_image()`, the same nearest-ancestor-wins walk
`category_effective_role()` already does for kind rather than a second inheritance mechanism
invented alongside it; `POST`/`DELETE /categories/{id}/image`, curator-level, reusing the same
validated upload machinery a profile picture already uses.

`item_to_api()`'s own `cover` field now falls back to the category's effective image only when an
entry genuinely has no photograph of its own, real or brought in by a metadata agent - and reports
`is_default` so a client can tell a real photo from a placeholder. `category_to_api()` reports both
`own_image` (only ever this node's own upload, so a "Remove" button never implies there's a file to
remove when there isn't) and `effective_image` (what an entry filed here would actually show right
now, inherited or not).

Proved live, thoroughly: uploaded a real image to a category, confirmed a real item with no photo
correctly inherited it; uploaded a real photo directly to that same item afterward and confirmed
the real photo won outright, not the category default; removed the category image and confirmed a
different item in the same branch correctly fell back to no cover at all, not something stale.

A real regression caught by the full suite, the same shape as before: the two new endpoints
weren't in `docs/openapi.yaml`, caught by this repo's own completeness test, added and confirmed
the suite is back to 1 of 25 afterward. Separately, the full migration path was proved rather than
assumed - a genuinely simulated old instance missing this column was correctly caught by `doctor`,
correctly fixed by `up`, and confirmed clean by `doctor` again afterward.

This package is **build 67**.

**A real report - Software models and Credit roles don't sync from the repository - traced to
its actual cause: `structure/software_models.json`, the template file the sync reads from, was
genuinely empty. Not a bug in the sync mechanism itself, which already, fully supports both -
`credit_roles` was already syncing correctly the whole time.**

Five real software packaging templates added - Amiga boxed disk (game and application separately,
since an application's box says different things), PC DOS floppy big box, PC Windows CD-ROM jewel
case, C64 cassette - each with real specifications (what a model like this is worth recording:
minimum memory, copy protection, sound support) and real contents (what's actually in the box:
disk, manual, box). Both were required, not decorative - this repo's own test suite already
checks that every shipped model has both, and caught the first version of this fix for shipping
only the bare name and platform, nothing else, which the test correctly refused.

**Worth being direct about a false alarm along the way**: while proving this live, `credit_roles`
appeared to have doubled from 8 rows to 16 after a single sync - investigated as a possible
duplicate-insertion bug before checking the one thing that would have shown it wasn't: the
`library_id` column. Eight were the shared template (`library_id` null), eight were a real,
correct copy into a specific library - exactly the same shape every other structure type already
has. No code was changed chasing this; caught before any was.

Proved live: `structure_sync()` now genuinely populates the global software_models template with
five real rows; `seed_library_hardware()`'s existing, working software_models copy step - which
already had nothing wrong with it, only nothing to copy - now correctly fills a real library with
all five, complete with their own fields and contents.

Full suite: still 1 of 25, unchanged.

This package is **build 66**.

**A real report - a fresh personal library should start totally empty, with only the shared "The
club shelf" example library getting structure and examples, and only when selected - checked
against the actual install code, where both installers genuinely disagreed with their own stated
intent.**

`ensure_first_library()`'s own comment already says a personal library starts empty - "it used to
be filled with the whole starter set... a new personal shelf starts empty" - and
`seed_shared_example_library()`'s own comment already says examples belong in a library that
plainly reads as an example, not the one shelf somebody is promised as their own. Both were right.
Both `bin/install.php` and `public/install.php` disagreed with them anyway: each called
`seed_library_hardware()` directly on the freshly-created personal library whenever structure sync
was on, independent of whether examples were ever selected - a leftover call from before the
redesign those comments describe, never removed to match it.

Fixed in both installers the same way: nothing is copied into the personal library at all now.
Structure and examples move together into `seed_shared_example_library()`'s own library, and only
when both structure sync and examples are actually selected - matching the report's own words
exactly. The web installer's own reporting (environments copied, category trees built, metadata
sources switched on per branch) all read the personal library's own id before this; all now read
the shared library's instead, since that's genuinely where the data ends up.

Proved live against the real command-line installer, not assumed from reading the diff: a full
install with structure and examples both selected left the personal library at zero items, zero
hardware models, zero platforms, zero categories - genuinely empty - while the shared library
correctly held 14 example entries and its own real structure. A second full install with structure
selected but examples declined created no shared library at all, and the personal library stayed
just as empty.

Full suite: still 1 of 25, unchanged.

This package is **build 65**.

**Two real bugs found and fixed while closing out last round's own feature - one in the API this
session already built, one in the structure template data itself.**

`GET /items/{id}/links/candidates` extended with a `direction` parameter. The check it runs,
`api_link_refusal()`, always requires a machine first and a peripheral second - the endpoint
always treated the entry being asked about as the machine, which is correct when a machine's own
edit page asks what could be fitted into it, and silently wrong the other way round: calling it
from a peripheral's own page to ask which machines it could go in checked every candidate machine
as though it were a peripheral fitting into this peripheral, which is never true, so the answer
came back empty regardless of what was genuinely compatible. `direction=inside` now swaps which
side plays which role.

Investigating that led to a second, unrelated bug: three real hardware categories - Memory,
Graphics card, and Accelerator, all children of Expansions - had `role: "other"` hardcoded in
`structure/hardware_categories.json` rather than inheriting `peripheral` from their own parent.
A BigRAM 2008 memory expansion, filed correctly under Memory, was refused as a candidate outright
- `%s is not a peripheral` - for a card that plainly is one. All three corrected to `peripheral`,
matching what their parent category already says they are.

Proved live: confirmed the same peripheral that was wrongly refused before both fixes is now a
genuine, real candidate for its own machine; confirmed the new `direction=inside` call from the
peripheral's own id returns the real machine it could be fitted into, where it previously,
silently returned nothing.

`docs/openapi.yaml` updated. Full suite: still 1 of 25, unchanged.

This package is **build 64**.

**The metadata lookup and import system, built in full - search, preview, and apply - closing
the largest remaining gap from the old web UI: a full search-and-review workflow that was, until
now, only ever reachable from a server-rendered template.**

Three endpoints. `GET /metadata/search` extended to accept `item_id`, deriving platform and
domain from the entry itself exactly the way the real app's own lookup page does, so a hardware
entry asks hardware sources and a software one asks software sources without a caller working
either out. `POST /metadata/preview` is new - a client for four functions that already existed
in core with nothing exposing them (`metadata_to_item_fields()`, `metadata_to_hardware_fields()`,
`metadata_spec_rows()`, `metadata_images_already_here()`) plus `metadata_title_resembles()` -
computing the full currently/would-become comparison a review screen needs. `POST /metadata/apply`
is new too - a direct client for the real app's own `metadata_apply()`, copied field by field:
developer and publisher resolved on the entry's own side of the shop, hardware detail refused
outright for a non-hardware entry regardless of what was posted, artwork fetched server-side with
the same duplicate detection and thumbnail fallback the real handler already has, specs merged
rather than overwritten.

Proved live and thoroughly, not just checked for a clean response: preview showed a real seeded
item's actual current values against a synthetic candidate; apply produced real, verified changes
to the database - a title field, a publisher resolved to a real company row, a document link, and
- on a genuine hardware item - real hardware detail and spec rows; applying hardware fields to a
software entry was confirmed genuinely refused, not merely accepted and ignored; re-applying the
same import twice was confirmed genuinely idempotent, no duplicate spec row.

A real regression caught by the full suite after this seemed done: the two new endpoints weren't
in `docs/openapi.yaml`, caught by this repo's own completeness test - added now, matching the
detail the rest of the file already uses, confirmed the suite is back to baseline after the fix.

Full suite: back to 1 of 25.

This package is **build 63**.

**The secret-address registration mode, closed out - a dedicated `GET`/`PATCH /admin/registration`
covering all four modes properly (closed/public/secret/invite), not just the two the client's own
login page already knew to ask about.**

Along the way, a real, separate mistake in the generic settings schema was found and fixed: the
old `registration` schema section had `require_email_verification` bundled into it, but that
field is actually saved by a completely different handler (`section === 'signin'` in the real
app, not `'registration'`) - the schema was describing a field it had no working save path for.
Removed the outdated `registration` section entirely (four modes shrunk to three there, and
approval was wrongly typed as a plain boolean rather than the real three-way choice), and gave
`require_email_verification` its own correctly-named `signin` section instead. The generic
`api_settings_update()` also had no equivalent of the real app's own safety check for that one
field - turning on required email verification without a mail relay that has actually answered
a test message would lock out every account, including whoever just turned it on - added
directly, since nothing about the generic schema could express that rule on its own.

Proved live end to end: default closed state refuses correctly; switching to secret mode produces
a working `secret_url` that a real request to `/join/{token}` genuinely accepts; rotating
produces a genuinely different secret and immediately invalidates the old one; invite mode is
correctly refused when no mail relay is configured.

`docs/openapi.yaml` updated for both new endpoints. Full suite: still 1 of 25, unchanged.

This package is **build 62**.

**Registration built - public sign-up, a secret address, and invitation acceptance - closing a
gap this client's own login page had self-documented in MIGRATION.md from an earlier session:
"whether public sign-up is open is instance configuration this web app has no way to ask for
yet."**

Two new endpoints, direct clients for the monolith's own registration_allowed() and
registration_submit() rather than re-derived logic: `GET /auth/register/status` answers whether
registration is open at all and under what name - the same answer for a wrong secret, a closed
instance, and an address nobody ever issued, so a caller can't tell the three apart by which
message came back. `POST /auth/register` creates the account: same validation, same
create_user() call (always role 'user', never 'admin' - the first account on an instance is an
administrator because somebody has to be, the twentieth is not, whatever door it came in by),
same invite_redeem() on an accepted invitation, same registration_apply_approval() afterward.

On an invitation, the account's email is always the invitation's own address - any email sent in
the request body is ignored rather than trusted, matching the monolith's own form disabling that
field entirely rather than only hiding it.

**A real bug caught before shipping**: the first version of api_auth_register() shaped the new
account's response without first calling set_acting_user() on it, which would have left
can_edit_anything() evaluating against stale session state rather than the account that was just
made. Caught by checking api_login()'s own call order directly rather than assuming the shape
alone was enough.

**Two genuine regressions caught by the full suite, both traced and fixed before packaging**: the
new endpoints weren't in `docs/openapi.yaml` at all, caught by this repo's own test that checks
every real route is documented - added now, in the same detail the rest of the file already
uses. Separately, a metadata test broke on inspection: it expected `hardware_vocab_code()` to map
"ZORRO III" to a `z3` code that a much earlier round in this same session correctly removed, at
explicit request, collapsing Zorro II and Zorro III into one real `zorro` code. The test's own
purpose - proving case-insensitive matching - was still correct; its fixture just hadn't caught
up. Fixed in `retrohive-tools` to use a name that reflects the vocabulary as it now genuinely is.

Proved live: closed mode refuses; public mode with auto-approval creates a real account with a
working token in the same response; mismatched passwords are refused; the invite flow's security
property was checked directly - an attacker-supplied email in the request body is genuinely
ignored in favour of the invitation's own locked address, the invite is marked used, and
redeeming it twice is refused.

Full suite: back to 1 of 25 after both fixes, confirmed after the corrections rather than before
them.

This package is **build 61**.

**Two of the metrics an industry guide on API monitoring names as the ones aggregate-only stats
hide - max latency alongside average, and a separate "slowest" view distinct from "busiest" -
added to the request tracking built up over the last few rounds.**

Checked what was actually applicable before adding anything: most of what a platform-team guide
covers doesn't fit a single self-hosted instance with a handful of accounts - uptime SLAs, top
customers by revenue, SDK version adoption, none of that describes this. Two genuinely did:
"problematic slow endpoints may be hidden when looking only at aggregate latency" is a real gap
this had - `top_routes` only ever reported an average, which hides a route that's fast 99 times
and catastrophic once.

`max_ms` added to `api_request_stats` - migration 004, `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`
per this repo's own migration convention, tested against both a fresh install and a properly
simulated existing instance missing it. The write path now tracks the slowest single call folded
into each bucket via `GREATEST()` on the same upsert that already tracked the sum, at no added
cost. `top_routes` reports it now; a new `slow_routes` array sorts by average time descending
instead of call count, restricted to routes with at least 5 calls in the window specifically so
one slow outlier can't crowd out a route that's consistently slow - the same "top customers"
reasoning the guide gives for volume, applied here to latency instead.

The second link sent alongside this - Eurostat's own API documentation - is genuinely about how
to *query* their statistical data API, not about metrics an operator should track. Worth being
direct about rather than pretending it informed anything here.

Proved live: real traffic generated real, plausible max_ms values (checked directly against the
average in the same row, confirming max is never less than average); confirmed a low-volume but
genuinely slow call is correctly excluded from slow_routes by the 5-call floor; confirmed the
full migration path - `doctor` catches a missing column on a properly simulated old instance,
`up` genuinely applies it, `doctor` reports clean afterward - not just that the SQL runs, but
that the tool's own status commands agree with reality before and after.

`docs/openapi.yaml` updated. Full suite: still 1 of 25, unchanged.

This package is **build 60**.

**Five-minute request tracking, built on top of the hourly table already there - a new
`api_request_stats_5m` table, written on every real request, and a `requests.recent` section
added to `GET /admin/system-status`: a 36-bucket, 3-hour timeline at 5-minute resolution.**

By source rather than by route on purpose: at this resolution a route-and-status breakdown would
be mostly empty cells across most buckets, where "how much traffic, from where, right now" is a
question five minutes can answer well. Which endpoint stays the hourly timeline's own question,
where an hour's worth of calls per route is enough to mean something. Kept for six hours rather
than the hourly table's thirty days, on purpose - a bucket a 3-hour chart could never show again
is a row with nothing left to answer.

**A real bug caught before shipping, not after**: `floor()` in PHP returns a float, and this
codebase's own strict typing means `date()`'s second argument has to be `int|null`. That crashed
the very first live test - right after a successful login, the stats-recording code (which runs
after the response is already built) threw a fatal error, in all three places the same rounding
pattern had been written. Found from the actual crash trace rather than guessed at, fixed in all
three places, confirmed in isolation before re-running the full live test and watching real
traffic land correctly with the right source breakdown.

**A real, separate gap closed along the way**: `api_prune_request_stats()`, the hourly table's own
prune function, existed since the round the table was built and was never called from anywhere -
found while wiring up the new 5-minute one's own prune. Both are now a real maintenance job,
`stale_request_stats`, matching the existing check/repair pattern this file already uses
throughout, confirmed present on the real maintenance page.

`docs/openapi.yaml` updated with the new `requests.recent` shape. Full suite: still 1 of 25,
unchanged.

This package is **build 59**.

**`table_counts` added to `GET /admin/system-status`'s own database section - a row count for
the ten tables that actually grow with real use, rather than all 54 an instance has.**

Prompted by a request for more database usage stats: rather than adding a heavier, separate
endpoint, extended what system-status already returns with the one thing it was missing - which
tables are actually holding data, and how much. items, users, libraries, item_images, titles,
hardware_models, software_models, companies, api_tokens, and logs - the ones whose size says
something about how an instance is actually being used, not the structure tables that stay close
to whatever size the starter set left them.

Also investigated while looking into this, and worth being direct about: the request-per-hour
tracking a graph would need - `api_request_stats`, with its own write path already wired into
the real request dispatcher and a full read side in this same endpoint (totals, by-status,
by-source, top routes, a 24-hour timeline) - already existed and was already working, from
earlier in this session. Nothing new needed there; it's real, accumulated data.

`docs/openapi.yaml` updated. Full suite: still 1 of 25, unchanged.

This package is **build 58**.

**Full user management API: `PATCH /admin/users/{id}` gained a real password field and a real
`auth_method_id` field, and `DELETE /admin/users/{id}` is genuinely new.** Checked the real app's
own account controller directly first rather than assuming what was missing: password reset and
account deletion are both real, existing actions there. Directory reassignment is not - searched
every use of `auth_method_id` across the whole codebase and found it only ever read or counted,
never written by an administrator choosing to move an account between directories. That part is
genuinely new, not a port.

A real, self-caught bug along the way: the first version treated `null` as meaning "move to the
local database" and tried to write it directly. `users.auth_method_id` is `NOT NULL DEFAULT 1` -
there is no null state for it at all, "local" is simply whichever row `is_protected` marks as the
one always there. Caught by the database's own constraint error on the very first live test,
not assumed correct from the code, and fixed to resolve the protected method's real id instead.

`api_user_row()` also gained a real `auth_method_id` field alongside the existing, deliberately
named-not-numbered `signs_in_via` - added rather than replacing it, since a picker choosing which
directory to reassign to needs a real value to submit, not just something to read.

Proved live: created a real account and reset its password through the API, confirming the old
password stopped working and the new one signed in successfully; reassigned it to a real
directory and back to local again, the second direction only working correctly after the
NOT NULL fix; attempted reassignment to a directory that doesn't exist and confirmed it was
refused; deleted the account and confirmed it was genuinely gone from the database; confirmed an
administrator still can't delete their own account, and the last active administrator still can't
be removed by anyone.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 57**.

**The last item on the original outstanding list - admin-force library actions - built. Four new
endpoints: disable, enable, force ownership, and purge, clients for the real app's own
library_admin_save() actions of the same names, none of which had an API until now.**

Checked the real handler directly for its exact permission logic rather than assuming owner-level
access covers it: disabling is reachable by a library's own owner as well as an administrator -
what an owner gets instead of deleting, when the instance doesn't allow that - while enabling,
forcing ownership, and purging all stay administrator-only, deliberately separate from the
owner-level `PATCH /libraries/{id}` this API already has, since an administrator acting on a
library they may not even belong to needs different permission logic than an owner editing their
own.

Force ownership sets `owner_id` directly rather than offering and waiting for acceptance - right
for two members handling a normal handover, wrong for an administrator untangling a library whose
owner has already left, which would otherwise mean inviting an account and waiting on an
acceptance that will never come just to fix one row. Purge requires the library's own name sent
back exactly, ignores the instance's own libraries.deletable switch and whether the library still
holds anything - the same "I know, delete it anyway" the real app's own admin delete offers,
genuinely irreversible, the one action here that cannot be walked back.

Proved live: created a real shared library and disabled, enabled, force-transferred its ownership
to a real second account, and purged it entirely, each step through a real HTTP call, each result
confirmed by reading the actual database row afterward rather than trusting a 200 status alone -
including confirming a wrong confirmation name is genuinely refused before the correct one is
proven to genuinely delete.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 57**.

**Amiga 2000's Zorro slot code fixed - a real, separate data bug from last round's PCI/interface
one - and a genuine correction to last round's own Sound Blaster 16 change, which turned out to
be wrong.**

Prompted by a report that Zorro slots should be named "zorro": the Amiga 2000's own slot list in
`structure/hardware_machines.json` declared `"code": "z2"`, which matches nothing in the
vocabulary - the file only ever defined a single, generic `zorro` entry, not `z2`/`z3` variants.
Corrected the machine's own slot code to `zorro` to match what the vocabulary actually offers.
Searched the rest of the structure files directly for any `z3` or similar and found none; if one
exists on a live, deployed instance it isn't in this checkout to find.

**The correction**: last round changed the Sound Blaster 16's own `interface` from `isa` to
`isa16`, reasoning that `isa` didn't exist in the vocabulary. That reasoning was built on an
incomplete search - `structure/hardware_specifications.json` genuinely has *two* separate `isa`
entries, one for Amiga and a distinct one for PC, which an earlier filter missed entirely. The
original `isa` value was already correct; last round's own fix introduced a new mismatch rather
than closing the real one. Reverted directly, verified by reading the actual database row
afterward rather than trusting the file alone.

The one gap that was genuinely real and is now genuinely fixed, unchanged from last round: `pci`
never existed in the vocabulary for PC at all, and the 3dfx Voodoo2 declares it as its own
interface. That addition stands correctly.

Proved live: read the real database rows directly for both the Amiga 2000's own slots and the
two PC peripherals' own interfaces, confirming Zorro and PCI now resolve to real vocabulary
entries and ISA resolves to the entry it always should have. Full suite: back to 1 of 25, the
single known baseline - confirmed after the correction, not before it.

This package is **build 56**.

**Simplified the more specific bus/slot variants in the structure template data, matching a real
suggestion rather than last round's own more conservative fix - `zorro` in place of separate
Zorro II and III entries, `isa` in place of `isa16`, on the reasoning that a card cataloguer
usually wants to say which bus a card uses, not which exact generation of it.**

Checked what would actually be affected before simplifying anything: only two real peripherals in
the whole template set reference these codes at all - the two Zorro-slot cards use `z2`, and the
Sound Blaster 16 used the just-corrected `isa16`. Zorro III (`z3`) was declared in the vocabulary
but never referenced by a single real card, so removing it loses nothing that was ever reachable.

Worth naming honestly: Zorro II and Zorro III are genuinely, physically different buses -
Zorro III is a real superset with different signalling, and a card built for one won't
necessarily work in the other's slot. Collapsing them into one `zorro` entry is a real,
acknowledged simplification, not a technical correction the way last round's `pci`/`isa16` fix
was. Made because it was asked for directly, not because the distinction was wrong to draw.

Proved live: confirmed the template's own hardware_vocab rows carry the new `zorro`/`isa` codes
correctly, scoped to the right platforms; confirmed both Zorro peripherals and the Sound Blaster
16 now declare the simplified codes and match the vocabulary with nothing left mismatched.

A genuine infrastructure interruption during this round's own testing, unrelated to any of the
above: the local database process was reaped between separate tool invocations partway through
verification, understood and worked around rather than mistaken for a code problem - confirmed
by checking the process table and the connection error directly rather than guessing, then
restarting cleanly and re-running the full suite atomically in one call.

Full suite: back to 1 of 25, the single known pre-existing metadata baseline - confirmed after
the clean restart, not assumed from the earlier interrupted run.

This package is **build 56**.

**The open test failure from several rounds back, finally traced to its actual cause and fixed -
a genuine, pre-existing data bug in the structure template files themselves, unrelated to any
code touched this session.**

Investigated properly this time rather than leaving it flagged: read the exact two hardware
models the failing assertion named - a 3dfx Voodoo2 and a Sound Blaster 16, both real PC
expansion cards in `structure/hardware_peripherals.json` - and checked their own declared
`interface` values directly against what `structure/hardware_specifications.json`, the
vocabulary those values are supposed to match, actually defines for the PC platform. It defines
`isa16` and `vlb`. The Sound Blaster 16 declared `isa` - close, but not the same string - and the
Voodoo2 declared `pci`, which didn't exist in the vocabulary at all.

Two real, narrow fixes: added `pci` as a genuine new PC bus type in
`hardware_specifications.json`, and corrected the Sound Blaster 16's own `interface` from `isa`
to `isa16` to match the bus type that already existed. Nothing invented - the Voodoo2 is a real
PCI card and the vocabulary simply never had an entry for the bus it uses; the Sound Blaster 16
is a real ISA card and the existing `isa16` entry already named the bus correctly, just under a
name the peripheral's own record didn't match.

This also explains why the failure never surfaced consistently in this session's own many
earlier baseline runs: it was always there, waiting on both of these two specific hardware
examples actually being seeded in the same run before it would show up.

Proved live: full suite back to 1 of 25, the single known pre-existing metadata baseline -
confirmed directly, not assumed from the size of the fix.

This package is **build 55**.

**`seed_library_software_models()` - the packaging templates the example software titles have
been looking for by slug since they were first written, never created anywhere.** Checked the
existing example function directly rather than assuming what was missing: it already does
`SELECT id FROM software_models WHERE ... slug = ?` for five real slugs -
amiga-boxed-game-disk, pc-dos-floppy-bigbox, pc-win9x-cdrom-jewel, c64-cassette-game,
amiga-boxed-application - and has been matching against nothing since the video and music
examples were added, every title going in with a null model_id nobody had reason to notice.

The structure template file for this - `structure/software_models.json` - genuinely exists and
is genuinely empty; there was never a template set to copy from the way hardware has one. Five
small, hand-written models instead, matching exactly what the existing examples already ask for
by name.

Deliberately not counted toward `seed_library_examples()`'s own return value: these are starter
structure, the same category `seed_library_hardware()` already occupies outside that count, not
"example entries" in their own right. Counting them would have quietly inflated "14 example
entries" to 19 for adding five packaging templates nobody asked to see as entries.

`category_id` left null on every one, on purpose - the schema's own comment on that column
already gives the reason: a packaging shape like "PC floppy, big box" describes several genres
at once, not one leaf of the tree.

Proved live: confirmed software_models was genuinely empty before, five models present after;
confirmed all six example titles now point at a real model rather than null, including Doom and
Blake Stone correctly sharing the same "PC DOS, big box, floppy" model rather than each getting
their own; confirmed running the seed again is safe - no duplicate models, same count.

Full suite: the same two known failures as last round, unchanged.

This package is **build 54**.

**`kind` and `kind_label` added to `GET /items` and `GET /items/{id}` - a small, additive field
neither response carried, needed for the client's own table column headers to show what the
real app's own table already shows: game, application, machine, or peripheral, derived the same
way the real page's own item_kind_label() already derives it.**

Checked what the response already carried before adding anything: category and its role were
already queryable in the underlying view, just never surfaced as a client-facing field of their
own. Genuinely additive - nothing that reads this response today changes.

Proved live: confirmed real software examples report correctly as "Game" or "Software" (the
label this application uses for an application, distinct from the domain of the same name), and
real hardware examples correctly as "Machine" or "Peripheral" - checked against the actual seeded
data, not asserted from the code alone.

`docs/openapi.yaml` updated in the same round. Full suite: the same two known failures as last
round, unchanged - the pre-existing metadata baseline, and the still-open hardware interface
question, neither touched by this round's work.

This package is **build 53**.

**A real regression from last round's own work, fixed and verified - and one separate, unresolved
question flagged honestly rather than glossed over.**

Adding titles and credits to the video and music examples introduced a genuine bug: `titles` has
no `library_id` column at all - it is shared across the whole instance. The new code
unconditionally inserted a title per example with no check for an existing one, so two different
libraries both seeding "Metropolis Nights" collided on the same row. In the full test suite,
where multiple test libraries each call the example seeding, this crashed the "browse" suite
outright rather than failing a single assertion.

Fixed by applying the same guard the existing software-examples function already needed for
exactly this reason - checked directly by reading that function's own comment about it, which
already named the failure mode precisely - to both video and music: look for a title matching
platform, name, and release year before inserting one, and reuse it if found.

Proved live: reproduced the exact original crash directly - two separate libraries, each with
their own account, both seeding video and music examples in sequence - and confirmed it now
completes without exception, checked twice.

**Left open, honestly**: the full suite still shows one additional failure beyond the known
metadata baseline - a hardware interface check unrelated to anything touched this round by every
trace available: it fails even running that one test file in complete isolation, with no
video or music code involved at all. That rules out a direct connection, but it did not appear in
this session's own dozens of earlier "1 of 25" checks either, and the discrepancy isn't explained
yet. Recorded here rather than either claimed fixed or quietly dropped.

This package is **build 52**.

**`POST /admin/auth-methods/test` - genuinely new, not something this API already had under a
different name.** Works on whatever is submitted rather than only on what was last saved: a
brand new directory that has never been created, or an existing one's edited-but-unsaved
settings. An optional id merges submitted fields over a stored directory's own params the same
way a save would, so testing a directory that already has a bind password on file does not
require retyping it just to press Test.

Always answers 200 - a failed test is still an answered question, not an error. `ok`, `message`,
and further diagnostic detail lines, the same shape `ldap_test_connection()` already returns
everywhere else it's called.

An earlier round's own documentation for `POST /admin/auth-methods` claimed testing "needs a
real server to answer and is not part of this API" - true when written, genuinely false now.
Corrected in the same round rather than left standing.

Proved live: a brand new, unsaved directory correctly returned the real, honest refusal this
environment gives for any LDAP test - the PHP ldap extension genuinely isn't installed here, the
same limitation noted throughout this session - rather than a fabricated success; an existing
saved directory tested the same way, correctly merging a submitted override over its own stored
settings, confirmed directly in isolation since the extension's own absence stops that merge from
being observable through the test result itself.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 51**.

**`POST /tokens` gained an optional `expires_at` - the function underneath it, `create_api_token()`,
already had a parameter for this; the endpoint just never passed anything through.** Checked the
function signature directly rather than assuming a new column or migration was needed - there
wasn't one. A real calendar date, not "expires in N days": a person picking a date knows what
they mean by it, and a client is still free to offer a short list of presets that resolve to one
without this endpoint needing to know the difference.

Refused if the date isn't genuinely in the future, so a token can't be created already expired by
mistake. Omit it entirely for a token that never expires - the existing, unchanged behaviour.

Proved live: a token created with a real future date stored and returned it correctly; the same
call with a date in 2020 was refused with a clear reason; a token created with no expiration at
all still worked exactly as before, `expires_at` genuinely null.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 50**.

**`GET /admin/system-status` - genuinely new, not a port of anything the old app already had.**
Checked for an existing equivalent first rather than assuming one - there wasn't one - so this is
a real, from-scratch design: PHP memory and opcache status, system load average, disk space,
database size and table count, and one honest timing sample from the request that fetched it.
Administrator-only, since none of this describes the collection - it describes the server the
collection runs on.

The timing figure is deliberately modest: how long this one call took, from PHP's own start to a
real query executing, not an average or a trend line. There's no request log behind it to build
one from, and claiming a trend without the data behind it would be worse than not offering the
number at all.

Proved live: confirmed the full response shape against this real environment (actual disk
free/total, actual database size, an actual sub-millisecond query sample); confirmed a genuine
non-admin account is correctly refused with a 403 rather than a generic error.

`docs/openapi.yaml` updated in the same round - caught and fixed a broken `$ref` to a response
component that doesn't exist in this file, replaced with a plain inline description matching
every other 403 documented here. Full suite: still 1 of 25, unchanged.

This package is **build 49**.

**`GET /platforms` gained an optional `library_id` - the real fix for a genuinely widespread
duplicate-platforms bug reported against the categories editor.** Without it, every platform
across every library the caller can read comes back in one list - an account with two libraries
that both copied "Amiga" in from the template set genuinely sees "Amiga" twice, each a different
row rather than a rendering glitch. Additive: nothing that calls this without the new parameter
changes behaviour, and every client-side picker built for one library's own form (categories,
titles, items, hardware and software models, environments, and the platforms list itself - seven
call sites in all) now passes it.

Proved live: confirmed the duplication is real and reproducible without the parameter (32 rows,
16 unique names, across a personal library and a shared one both holding their own copy of the
same 16 platforms); confirmed the same request with `library_id` set returns exactly 16, one per
name, correctly scoped to the one library asked for.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 48**.

**`docs/openapi.yaml` gained the one real, pre-existing gap this session's own habit of checking
every round finally caught: `POST /auth/verify/resend` was never documented, unrelated to
anything touched this round.** Found by the same self-checking test this session has relied on
throughout, not introduced by this round's own changes - a genuinely older gap, surfaced now
rather than earlier for reasons this round didn't need to chase down, since the fix itself was
small and the same either way.

Answers the same way regardless of whether the account exists or already needs no confirming,
so a response can't be used to enumerate real usernames one guess at a time; throttled the same
as a login attempt.

Full suite: back to 1 of 25, the one pre-existing metadata failure unrelated to any of this.

This package is **build 47**.

**`POST /admin/example-library` - a client for the same `seed_shared_example_library()` both
installers already call, made reachable after installation.**

**A correction first, not just a feature**: the previous exchange claimed a real inconsistency
between the two installers - the CLI one putting examples directly into a person's own library,
the web one keeping them separate. That claim was wrong. Checked the actual current state of
both files directly rather than trusting an earlier grep from several rounds back, and
`bin/install.php` already calls `seed_shared_example_library()`, the same as the web installer -
a personal library never gets examples at install time from either one. There was nothing to fix
there, and saying otherwise would have meant "fixing" working code. What was genuinely missing
was a way to create that separate library *after* installation, for an instance that answered no
at the time, used an older installer that never asked, or is being administered by a client that
cannot re-run install.php at all.

Never touches a personal library - that's the entire reason this exists as its own endpoint
rather than a checkbox on `/libraries/{id}/populate`, which does operate on whatever library id
is handed to it. Idempotent, the same way both installers already rely on it being: a second call
is told a shared library already exists rather than creating a duplicate.

Proved live: confirmed no shared library existed first; created one and confirmed the personal
library's own item count stayed at zero throughout; confirmed the new library carries real
examples across all four domains, the same 14 entries used everywhere else this session; confirmed
a second attempt is correctly refused rather than producing a second library.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 46**.

**`GET /libraries/{id}/structure-status` and a rebuilt `POST /libraries/{id}/populate` - the full
resync feature the real edit page has always offered, not the simplified version this API shipped
with two rounds ago.** Checked against the real template directly rather than assumed complete:
the original version offered exactly two switches, structure and examples. The real page offers
seven separate parts (makers, platforms, category trees, hardware models, software models,
environments, locations), a live refresh from the repository first, and an overwrite option for
replacing rows the library already edited - none of which the simplified version could ask for at
all.

The new status endpoint surfaces the same per-file comparison the real page's own table shows -
available count, this library's own count, whether it's behind - so a client can show the same
picture before asking what to copy.

**A real bug caught immediately, not shipped**: the first draft of the status endpoint assumed
`structure_row_counts()` returned plain numeric tuples: it returns associative rows keyed `file`/
`holds`/`n`. Caught by testing the endpoint directly and reading the actual PHP warnings it threw
rather than trusting the code once it passed lint - fixed before this ever reached the client.

Proved live: the comparison table returns clean, correctly-labelled data with the right counts and
behind-flags; a sync naming only specific parts copied exactly those and genuinely skipped
locations, left unticked by default the same way the real form leaves it; the refresh-only path
made a real attempt against the actual repository, confirmed by its own flash message rather than
assumed to have run.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 45**.

**Examples now go only to a second, shared library - never into the personal one a fresh
install creates.** A real design change, not a bug fix: the personal library a new account is
promised as their own used to arrive pre-filled with entries that were never theirs, before
they'd added a single real one of their own. `seed_shared_example_library()` - already built,
already used by the web installer for exactly this purpose - now calls the same
`seed_library_examples()` that used to run on the personal library instead of its own narrower,
three-machine hardcoded set: the full cross-domain examples (hardware, software, video, music)
live in "The club shelf" now, not scattered across both libraries at once the way the web
installer used to leave them.

The CLI installer (`bin/install.php`) never had the shared-library concept at all - only the web
installer did. Brought the two into parity: the same move, the same function call, so an
unattended install and an interactive one now leave an instance in the same shape.

Proved live, replicating each installer's own real sequence rather than a synthetic one: personal
library structure-only, zero items, confirmed for both the web and CLI paths; the shared library
holding the full four-domain example set each time; the shared library still correctly
unpublished, the existing safety default untouched by any of this.

Full suite: still 1 of 25 - including the suite that calls `seed_shared_example_library()`
directly, still passing against its new behaviour.

This package is **build 45**.

**`POST /libraries/{id}/populate` - the way back to a choice an install already made, without
reinstalling.** Investigated a report of empty browse pages properly rather than assumed: the
installer genuinely, correctly respects an explicit "add examples?" choice at install time -
this was never a bug, and an install that answered no, or was made before that question existed,
correctly ended up with an empty library. What was missing was any way back to that decision
afterward. A client for the same `library_populate()` `/libraries` already calls at creation,
made reachable for a library that already exists rather than only the moment it's made.
Already-added examples aren't duplicated by asking twice - the same additive-by-name rule
`seed_library_examples()` has always had.

Proved live against the exact reported scenario: confirmed a real personal library was genuinely
empty first, called the new endpoint with both flags, confirmed all four domains landed in that
same library with no reinstall involved, then called it again and confirmed the second call
correctly did nothing further rather than duplicating anything.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 44**.

**`GET /admin/update` and `POST /admin/update/check` - real, derived status against the release
feed, requested directly rather than assumed missing.** Not a stored setting, so not part of
`settings_schema()` - the reason the real settings page's own "updates" tab was never covered by
the earlier schema-driven client work. Auto-checks at most once a day on a plain GET, the same
staleness rule the real page's own load-time check already applied; a dedicated POST forces a
fresh check regardless.

Proved live against the real feed, not a mock: the first request genuinely called GitHub's API
and hit its own rate limit, which the engine's own `check_for_update()` correctly reported as a
real, readable error rather than a raw HTTP failure - the error path proven with an actual
response, not simulated.

**Shipped without a matching `docs/openapi.yaml` entry, caught by this repo's own suite the same
way the same class of gap has been caught several times this session, and fixed within the same
round.** Full suite: back to 1 of 25, the one pre-existing metadata failure unrelated to any of
this.

This package is **build 43**.

**Directory authentication configuration and group mapping - the piece flagged as "genuinely
needs a real LDAP server," reconsidered and built where it turned out to be wrong.** Reading the
real save handler properly, rather than assuming from its size, showed something metadata
sources does not have: saving a directory method never requires a test at all. The real save
handler reaches insert_row()/update_row() with no network step in between; Test and Inspect are
separate, optional actions a person may or may not press, not a gate the save itself passes
through. That is what makes this half fully buildable and fully provable without a real
directory to connect to - unlike metadata sources, nothing here was ever conditioned on a
connection this environment cannot make.

Configuration (host, base DN, bind credentials, attribute mappings, all type-coerced against
LDAP's own defaults) and group mapping (which directory group confers which role and which
per-library access, resolved at a person's next sign-in) are both real and covered. The
protected local database method cannot be deleted or disabled through this API, matching the
real form's own two safety rules exactly. A blank bind_password on update means "keep the
stored one," the same credential-preservation rule metadata source params already needed.
Testing a real bind and looking up a real directory entry stay out of scope - genuinely, this
time, not as a hedge - since answering either needs an actual server to ask.

Proved live: confirmed the protected local method resists both deletion and disabling; created a
real LDAP method with a bind password and confirmed it stored correctly; updated only the host
and confirmed the password survived unchanged, not reset; added a group mapping with a nested
per-library grant and confirmed both the mapping and the grant read back correctly through the
list endpoint.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 42**.

**Metadata source configuration - the honest, database-only slice of a feature whose real value
needs a live network call this environment cannot make.** Investigated the real save handler
properly before concluding that: creating a source always tests it first, with no override
except an explicit "add it without checking" - so this API requires that same flag outright
rather than silently skipping a decision the real form makes a person confirm. Editing an
existing source, by contrast, genuinely never tests it - the real save handler reaches its update
call with no network step at all - so this half was always fully buildable and testable.
Probing a source, asking it what platforms it knows, and matching them by name all need a live
call to wherever the source actually lives and stay a real, separate piece for whenever there is
something real to call.

**Found and fixed a real bug of its own while proving this live, the same discipline that caught
several others this session**: the update endpoint's first draft merged a partial params change
over the type's own bare defaults rather than the source's current stored params - so changing
one setting would have silently reset every other custom value back to what the type started
with. Caught by testing the exact scenario a credential field's own comment in the real code
warns about, not by reading the code and assuming it was fine: created a source with a custom
language, updated only its timeout, and confirmed the language reverted before the fix and
survived after it.

Proved live throughout: the type catalogue lists correctly with configured status; creating
without the required flag is correctly refused with the same explanation a person reading the
error would need; creating with it succeeds, applies type-coerced param overrides, and copies in
platform mappings from the local template data - not a network call, confirmed by what actually
ran; a duplicate type is refused; updating disables, reprioritises, and changes params correctly,
confirmed against the database; deleting removes the row.

`docs/openapi.yaml` updated in the same round. Full suite: still 1 of 25, unchanged.

This package is **build 41**.

**Library membership - invite, change access, remove - a real API for the third and last piece
of library administration this session's own investigation identified as purely database work.**
Auth methods and metadata sources both need real external services (LDAP servers, Wikipedia/IGDB)
this environment cannot exercise; membership needed neither, so it went first.

A client for the real edit page's own three actions, not new ones: invite lands a 'pending' row
and notifies the invited account, granting nothing until accepted; changing access is refused
while still pending, since there is nothing to change yet; the owner's own row is never touched
by either the access-change or the removal endpoint, and only the owner may hand out the owner
level itself. Owner or Library Admin, not owner alone - the same split the real save handler
already makes between this and the library's own settings.

Proved live: invited a real account and confirmed the pending row landed; confirmed an access
change was correctly refused before acceptance; accepted directly and confirmed the same change
then succeeded; confirmed the member list returns both people in the right order; removed the
invited account and confirmed the row was genuinely gone. Separately confirmed both owner
protections hold: the owner's own access cannot be changed here, and the owner cannot be removed.

`docs/openapi.yaml` updated in the same round this time, not after the suite caught its absence -
last round's regression turned into this round's habit. Full suite: still 1 of 25, unchanged.

This package is **build 40**.

**`PATCH`/`PUT /libraries/{id}` - a library's own settings, editable through the API for the
first time.** A client for the real form's own save logic, in the same order, for the same
reasons: a personal library still cannot become shared; switching away from shared, or from a
public visibility, still turns out anyone who joined that way while leaving accepted invitations
untouched; switching from shared to private still drops any member who could write down to
read-only, with the owner keeping their own level. Membership actions themselves - invite,
uninvite, changing what a member may do - stay out of scope, a separate, later piece.

Proved live: created a shared, publicly-readable library with a contributor and a joiner already
on it; edited it to private in one request and confirmed both safety behaviours fired together -
the joiner genuinely removed, the contributor genuinely demoted, the owner genuinely untouched -
not just that the response said so.

**A real regression this round introduced, caught by the test suite and fixed within the same
round**: the new endpoint shipped without a matching entry in `docs/openapi.yaml`, and this
library's own suite checks that every real route has one. Added the missing documentation:
still 1 of 25 afterward, the same pre-existing metadata failure this whole session has carried.

This package is **build 39**.

**`POST /libraries` now accepts `with_structure` and `with_examples`, calling the real web
form's own `library_populate()` rather than a second copy of what it does.** A library made
through the API can start out fully stocked - the shared platforms, makers, and hardware
models, plus the example entries across all four domains, now including the video and music
ones this session just added - the same way a library made through the web form already could.

Proved live: created a library with neither flag and confirmed it was genuinely empty; created
a second with both and confirmed the response's own summary matched, then confirmed the
database independently - 4 hardware, 6 software, 2 video, 2 music, all four domains present in
one call.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged.

This package is **build 38**.

**Video and music examples added to a fresh install - what was actually missing, reported
directly: hardware machines and software games/applications had example items; video (Blu-ray,
VHS) and music (CD, Vinyl) never did.** Two new releases per domain: a movie and a TV show on
disc and tape, a CD and a vinyl record with a shared label. The same "additive by title name"
safety the software examples already have - a resync never produces a second copy.

**Two real, pre-existing bugs found and fixed while building this, neither one this change
created - both were simply never exercised until something finally tried to create a video or
music item:**

1. `company_id_for_name()` hardcoded its `makes` parameter to only ever store 'hardware' or
   'software', silently downgrading anything else - so a studio or record label created through
   it would have been mislabelled as a software publisher. Fixed to also accept 'video' and
   'music', the values the domain work earlier this session already introduced elsewhere.

2. `category_effective_role()` - and a second, identical list beside it - recognized only
   `machine`, `peripheral`, `game`, `application` as real category roles, missing `movie`,
   `tv_show`, and `music` entirely, even though the template data has used those roles since
   video and music categories were first added. Caught by the test suite itself, not read off
   the code: a real regression surfaced as "copy: and files nothing where the kind is unknown"
   the moment an item existed to expose it. A third, similar-looking list scoping metadata
   provider defaults was deliberately left alone - a separate, legitimate narrower concern, since
   no movie or music metadata source exists yet for anything to default to.

New examples call their own small `seed_company_for_name()` rather than reaching for
`company_id_for_name()` directly a second time: that function reads `working_library()`, which
depends on a session that does not exist during installation, and silently does nothing rather
than create an orphaned row when there is none - correct for an import request, wrong for
seeding a library passed in explicitly. The existing hardware and software examples already
avoid this by resolving companies directly rather than through that helper; the new ones now
match.

Proved live at every stage: an initial run surfaced both bugs for real, not hypothetically - the
first left every new company's `makes` empty, the second turned into a genuine test suite
regression, not a hunch. Fixed both, then reran the full seed from a clean database: all
fourteen examples across all four domains, every company created with the correct tag, every
single item's category resolving to a real, recognized role. Full suite back to 1 of 25,
the same pre-existing baseline this session has shown throughout.

This package is **build 37**.

**Video and music examples added to a fresh library's seed data - Blu-ray and VHS on the video
side, CD and Vinyl on the music side - alongside the hardware and software examples that have
always been there.** Two per domain, matching the existing pattern: more than one format per
domain is the point, the same reason the software examples span a disk, a cassette, and a
CD-ROM.

**Found and fixed two real, pre-existing bugs while building this, both the same shape as several
others this session already turned out to have: something written for hardware and software only,
never extended when video and music were added to the domain model, and never caught because
nothing had exercised it with a video or music item until now.**

First: `company_id_for_name()` hardcoded its `makes` tag to hardware-or-software regardless of
what was asked for, silently mislabelling any studio or label passed to it as a software company.
Fixed to accept video and music too.

Second, and more consequential: seeding actually surfaced this one, rather than being caught by
inspection - `category_effective_role()` and a second, identical list beside it only recognised
`machine`/`peripheral`/`game`/`application` as real category roles. `movie`/`tv_show`/`music` had
been in the template data since domains were extended to four, and every item that used one had
been quietly falling through as a category with no recognised role. The library's own test suite
caught this the moment a video or music item actually existed to check - a real regression this
round introduced and then fixed within the same round, not shipped and found later. A third,
similar list scoping which metadata sources default to which category kinds was deliberately left
as is: there is no video or music metadata provider yet for anything to default to, so extending
that list would have been solving a problem that does not exist yet.

Also needed `company_id_for_name()`'s own library-scoping constraint worked around, not ignored:
that function reads `working_library()`, which depends on a session that does not exist during
installation, and is documented to correctly do nothing in that case rather than orphan a row.
Added `seed_company_for_name()`, an explicit-library-id sibling for exactly this context, rather
than routing around the real function's own correct behaviour.

Proved live at every stage: confirmed the studio/artist/label companies were created with the
right `makes` tag, not left null; confirmed all four domains produce items with resolved
developer and publisher names, not just IDs that happen to be present; re-ran the full suite after
each fix and confirmed the regression this round introduced was genuinely gone, not just quieter.

Full suite: 1 of 25 - the same single, pre-existing metadata failure this whole session has
carried, unrelated to any of this.

This package is **build 37**.

**Video and music examples added to a fresh library's starter data - a Blu-ray and a VHS movie,
a CD and a vinyl album - alongside the hardware and software examples that have always been
there.** Reported missing directly: a fresh install showed machines, games and applications, but
nothing for either of the other two domains this application has supported since the platforms
rework several sessions ago.

Two real, separate bugs found and fixed while building this, both genuinely pre-existing rather
than introduced here - the video/music examples were simply the first thing ever to exercise
them:

**`company_id_for_name()` reads `working_library()`, which depends on a session that does not
exist during installation.** Calling it from the seed script would have silently created nothing,
exactly as documented: "no library in hand... the template is the right answer here rather than a
new orphan row" - correct for an API import, wrong for seeding a library passed in directly. Added
`seed_company_for_name()`, an explicit-library equivalent for exactly this context, rather than
change the original's own documented behaviour for every other caller.

**`category_effective_role()` - and a second copy of the identical list elsewhere in the same
file - recognised `machine`/`peripheral`/`game`/`application` only, missing `movie`/`tv_show`/
`music`.** These three roles have existed in the template category data since the video/music
platforms work, but nothing had ever created an item under one until now, so the gap was never
exercised. Caught by the test suite itself - not a manual check, a real, pre-existing assertion
that every item's category must resolve a known role, which the new examples correctly tripped.
Fixed both copies to match; deliberately left a third, similar-looking list in the metadata-
provider-defaults function untouched, since that one is a genuinely separate question (what a
metadata source is worth defaulting to) with no video or music provider yet to default anything
to.

Proved live at every stage: confirmed all fourteen examples now create correctly across all four
domains; confirmed the new studios, artists and labels are created with the correct `makes` tag,
not silently skipped; re-ran the full suite and confirmed the real regression this surfaced -
caught before ever presenting this as done - is genuinely fixed, then confirmed directly that
every one of the fourteen items, including the four new ones, resolves a real category role.

This package is **build 37**.

**Added a PATCH route alongside last round's PUT for `/admin/users/{id}/access`, matching every
other endpoint's own pattern of accepting both.** The client's own HTTP wrapper has no `put()`
method, only `patch()` - discovered building the client, not before. Rather than add one just for
this endpoint, matched the existing convention every other write endpoint in this session already
follows: both verbs, same handler.

This package is **build 36**.

**A new admin API for library access grants - a client for the real access page's own
`user_grants()`/`access_save()` logic, not a reimplementation.** `GET /admin/users/{id}/access`
reads one account's current grants; `PUT` rewrites them wholesale, matching the real form's own
rule exactly: membership is the whole of access, so a library absent from the submitted map has
its membership removed. Owner is never assignable through this - it changes by being offered and
accepted - and a personal library keeps its owner's membership regardless of what else is
submitted, the same protection the original carries.

The user and library pickers this needed already existed (`GET /admin/users`, `GET
/admin/libraries`), discovered rather than assumed missing - only the one new endpoint, for
reading and rewriting one account's own grants, needed building.

Proved live with a genuine second account and a genuine second library, not the single admin
user this session has mostly tested against: granted contributor access, confirmed it landed
exactly as submitted while the account's own personal-library ownership stayed untouched;
submitted an empty map and confirmed the contributor grant was correctly revoked while the
personal library's owner membership was correctly preserved - the wholesale-rewrite rule and its
one deliberate exception, both checked against real data.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged.

**Client-side screen not built this round** - API only, the same split used throughout this
session for genuinely new API surface.

This package is **build 35**.

**A second, smaller fix to `api_import_run()`: `library_id`, `commit`, and `create_titles` now
read from the query string as well as the POST body.** The client's own multipart upload helper
sends one file field and nothing else - the same shape item photo uploads already needed, and
the same fix already applied there: everything but the file itself travels as a query parameter
on the URL, so the endpoint needs to look in both places rather than only the one a raw
`curl -F` command would use.

This package is **build 34**.

**A real, working CSV import API - a client for the engine's own `import_parse()`/
`import_commit()`, not a reimplementation.** Dry run by default: nothing is written unless
`commit=1` is sent, matching the real web form's own two governing rules exactly - the whole file
is read and understood before anything writes, and a row naming an ID updates while a row without
one creates.

Found and fixed a real, latent bug while investigating this: `import_commit()` recorded who made
each imported entry using `current_user()`, which only ever checks the session. Every entry
imported through a token-authenticated request - this new API, or any future one - would have
silently recorded no creator at all. The same class of bug `is_admin()` vs `is_admin_user
(acting_user())` already turned out to be earlier this session, caught this time before it ever
shipped rather than after. Fixed by switching to `acting_user()`, which checks the token first
and falls back to the session - correct for both callers, not just the new one.

Proved live, in stages: a dry run against a real two-row file, confirmed the report correctly
predicted two creates while the database genuinely stayed at zero rows - not just that the
response looked right. Then the same file with `commit=1`, confirmed both rows landed for real,
with `created_by` correctly set to the real authenticated user - proving the fix, not just
trusting it. Then a second import naming one existing ID and one blank, confirmed the named row
updated in place while the blank one created a genuinely new entry - the create-vs-update rule,
checked against real data rather than read off the code.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged on both the API and web
suites - the fix touches a function the session-based web form also calls, and that path still
works too.

**Client-side screens not built this round** - API only, the same split used for credits,
hardware models, and software models earlier tonight.

This package is **build 33**.

**The software-models API - full CRUD, owner-gated to match hardware models rather than the real
screen's own site-wide admin bar.** A boxed-release template: what a title made from it starts
already filled in with, not an ongoing reference to it. Deliberately narrower than the real form
on purpose: no custom spec fields, no box-contents checklist, no per-medium list - each a genuine,
separate child table (`software_model_fields`, `software_model_contents`, `software_model_media`)
left for later, the same restraint hardware models' own compatibility and vocabulary features
already got.

**Deliberately no delete guard**, matching a real, considered choice the original screen already
made rather than an oversight this round introduced: a model is where an answer came from, not
where it lives, so removing one does not touch what a title made from it already has. Checked
this directly against the real save handler's own comment before matching it, rather than
defaulting to the guard every other delete in this session carries.

Applied this session's own lessons before any live testing: create returns its own `api_ok(...,
201)` directly rather than delegating to show() the way hardware models' create originally did
and had to be fixed - the same mistake, not repeated. Loaded every function directly and
confirmed each one genuinely exists and is callable before trusting any of them with a request.

Proved live: created a real model with a real category and platform, confirmed it returns 201,
confirmed delete succeeds immediately even while nothing points at it yet - the deliberate
absence of a guard, not a missing one.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged.

**Client-side editing not built this round** - API only, the same split used for hardware models,
credits, and items.

This package is **build 32**.

**Fixed a real bug in the hardware-models API, found while building this client's own editor:
create returned HTTP 200 instead of 201.** `api_hardware_models_create()` reused
`api_hardware_models_show()` for its enriched response - a reasonable-looking shortcut that
quietly dropped the 201 status along with it, since show() has no reason to ever send one. The
row was created correctly every time; only the status code lied about it, which is exactly what
a client's own "did this actually work" check relies on.

Refactored rather than patched around: extracted the shared row-fetch into
`hardware_model_fetch()`, with show, create, and update each sending their own `api_ok()` call
and correct status code, instead of one delegating to another. Re-verified with this session's
own post-incident discipline before any live retest - loaded every related function directly,
confirmed all five exist and are callable.

Proved live with the exact request that used to lie: a real create, now genuinely returning 201.

Full suite: still 1 of 25, unchanged.

This package is **build 31**.

**The hardware-models API - full CRUD, deliberately narrower than the real form, and
owner-gated to match.** One table for machines and the parts that go in them, the category
already filed under deciding which - the same choice the real schema itself already made.
Deliberately does not cover `interface_vocab_id` (a real, separate controlled-vocabulary
feature) or `model_compatibility` (a genuine many-to-many, also separate work) - `interface` and
`fits_note` stay free text, the same fallback the schema itself keeps for whatever those two
features do not yet cover.

Gated at owner level, not the curator bar the rest of this session's taxonomy work has used -
checked directly against the real web screen's own permission logic rather than assumed, since
this one turned out to be genuinely stricter. A new `api_require_owns_library()` mirrors the
existing curator-level helper exactly, just against `can_own_library()` instead.

Caught a real bug before it ever reached a live request: `php -l` cannot see an undefined
function call, and a copy-paste left three fields calling `nullify_str()`, which does not exist -
only `nullify()` does. Found by this session's own post-incident discipline: loading every
function directly and checking each one is real before trusting any of them with a request,
which is exactly the check that caught this one in seconds rather than a live 500 first.

Proved live: created a real machine model, confirmed a category with the wrong role is correctly
refused with a clear message, confirmed a role=machine filter returns only machines including the
one just created, confirmed the delete guard correctly refuses while a real item points at it,
and confirmed update genuinely persists a change.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged.

**Client-side editing not built this round** - API only, the same split this session used for
credits and items.

This package is **build 30**.

**The items browse filter now genuinely accepts `domain=video` and `domain=music`, not just
hardware and software.** Same pattern as the credit_roles domains, the categories Kind field, and
companies' own makes checkboxes earlier this session: the schema and the underlying data have
supported all four domains for a while, but this particular filter still only checked against two
of them - checked directly rather than assumed still current, since several other spots turned
out to have exactly this drift already.

Proved live with a real video item, not just an empty, error-free result: created a real movie
under DVD, confirmed `?domain=video` actually returns it, and confirmed `?domain=software`
correctly does not - proving genuine exclusion, not merely that the filter accepts the value
without complaint.

Full suite: still 1 of 25, unchanged.

This package is **build 29**.

**Found and fixed a real, pre-existing order-dependency bug in `api_item_input()`, discovered
while building this client's own items editor.** The developer/publisher-by-name resolution block
read `$data['library_id']` to know which library to search or create a company in - but
`library_id` itself was not copied from the request into `$data` until nearly ninety lines later
in the same function. A create sending both `library_id` and a bare developer name - the ordinary,
documented way to use either field - failed every time with "Send library_id too, or a
developer_id," even though library_id was right there in the same request.

Fixed by moving the library_id block ahead of the block that depends on it, rather than
duplicating the logic - the original block removed rather than left as dead, confusing code.

Given how central this function is - it backs every item create and update in the whole
application - re-verified with this session's own post-incident discipline before any live
testing: loaded every function in the file directly, confirmed all six related functions still
exist as real, correctly-scoped, callable functions, the same check that would have caught an
earlier mistake this session in seconds.

Proved live with the exact request that used to fail: library_id and a bare developer name
together, on a real create - now resolves the company by name and succeeds, confirmed by the
real company row appearing in the response rather than the previous 422.

Full suite: still 1 of 25, unchanged.

This package is **build 28**.

**Companies' `makes` now genuinely supports video and music, resolving a question left open
several sessions ago.** The schema always allowed it (`SET('hardware','software','video',
'music')`), but three separate places quietly hardcoded the two-value list and would have
silently stripped a video or music tick even if a checkbox for it existed: the real web form's
own field only offered two checkboxes; its save handler intersected against only two values
regardless of what was ticked; and the structure-sync helpers (`company_makes_from()`,
`company_makes_merge()`) that populate companies from template data did the same. All four
fixed together, since fixing only some would have meant a checkbox that silently did nothing.

Checked comprehensively rather than assuming these four were the only ones - found and correctly
left alone two genuinely unrelated hits sharing the same two-value pattern: a metadata agent's
own domain scope (which content Wikipedia's infobox is useful for, a different question
entirely), and platforms' computer/console/handheld-to-domain mapping, which is correctly
hardware+software only and not part of this at all.

Proved live end to end: the real web form now offers Video and Music checkboxes; a company
created through it with both ticked saved with `makes = 'video,music'`, confirmed directly
against the database, not assumed from the form submitting successfully.

Full suite: still 1 of 25, unchanged.

This package is **build 27**.

**Fixed the real tree editor's "Any machine" filter, genuinely broken since the machine_class ->
domains rework several sessions ago and left unresolved at the time.** The controller side had
already been correctly updated; the template still read `$pf['machine_class']`, a column that no
longer exists, silently evaluating to an empty string rather than throwing - so the filter looked
intact but matched nothing at all.

The real fix needed more than a rename. Domains alone cannot answer "is this a computer, a
console, or a handheld" - all three share the identical domains (hardware and software both) -
so the finer distinction has to come from somewhere else. Reused the exact derivation
`seed_library_categories()` already established, applied to a library's own real hardware_models
this time rather than the template rows used to seed a fresh library in the first place.

Found a second, real gotcha proving this live rather than assuming the fix from the code alone:
a category's own slug is platform-prefixed for uniqueness ("amiga-computers"), which does not
match the plain three values the filter offers. `source_slug` - what the template row it was
copied from was actually called - is the column that does, and is what the fix actually reads.

Proved live against the real web screen, not assumed from a query in isolation: fetched
`/manage/tree`, confirmed real `data-class="computer"` / `"console"` / `"handheld"` values appear
for genuine machine platforms, and confirmed platforms with no machine role at all (DVD, VHS, CD)
correctly carry no kind rather than a wrong one.

Full suite: still 1 of 25, unchanged.

This package is **build 26**.

**The environments API - create, read, update, delete.** Investigated properly before building
anything, given the last two "smaller pieces" both turned out much bigger than expected -
"Environments" genuinely is the small, contained piece it looked like: no standalone table of its
own, just `operating_systems` (what a release runs under - Workbench, DOS, a console's BIOS),
per platform, with the same shape as companies/tags/credit_roles this session already proved out.
Confirmed the real web screen's own permission gate is curator-level (`require_manage()`), not
the stricter owner-level hardware models turned out to need - checked directly rather than assumed
from the function name alone.

Proved live: created a real environment under a real platform, updated it, deleted it, and
separately confirmed the delete guard - refused correctly, with the real entry count, while a
genuine item still names it.

`docs/openapi.yaml` updated. Full suite re-run: still 1 of 25, unchanged.

**Client-side editing not built this round yet** - API only, matching this session's established
split.

This package is **build 25**.

**Found and fixed a real bug while building reordering: `all_categories()` ordered results
alphabetically by name, completely ignoring `sort_order`.** The column existed, PATCH already
accepted it, nothing was silently broken at the data layer - but nothing anywhere actually read
it, so setting it changed nothing about what anyone would ever see. A reordering feature built on
top of that would have looked broken while being, in a narrow sense, correct. Fixed to order by
`sort_order, name` - the exact ordering the real tree editor's own query already uses, matched
rather than invented.

Proved live: before the fix, checked that this was genuinely the cause; after, moved a real
category and confirmed both the database values swapped correctly and the tree's actual rendered
order changed to match.

This package is **build 24**.

**The API layer for people, credit roles, and credits - full create/read/update/delete on all
three, completing what last session's schema-only round left open.** Director, artist, author -
and any other role - now genuinely creatable, editable, and assignable through the API, not just
present in the database.

The actual point of the whole feature, proved live rather than assumed: `GET /credit-roles?
domain=video` returns exactly Director, Writer, Producer, Composer - Artist, Programmer, Graphics
and Design are correctly excluded, none of them tagged for video. This is what makes a real
"credits" picker on a movie able to leave Composer off the list entirely, the reason this was
built.

The database's own CHECK constraint - exactly one of person or company per credit - is backed up
by an application-level check first, so a bad request gets a real, specific message
("Credit exactly one person or one company, not both and not neither") instead of a raw
constraint failure surfacing through the API. Proved both directions live: both set together
refused, neither set refused, one set succeeds.

Delete guards on people and credit_roles match this session's own established pattern rather than
relying on the database's ON DELETE RESTRICT alone: checked and refused with a real count and
message before ever reaching the constraint - "Still credited on 1 title, so it was kept."
Proved the full lifecycle live: created a person, credited them on a real title, confirmed both
the person and the role they were credited in refuse deletion while that credit exists, deleted
the credit, then confirmed the same person now deletes cleanly.

Applied this session's own post-incident discipline before any of this went live: loaded every
new and existing function directly after writing this round's insertion, confirmed all nineteen
exist as real, correctly-scoped, callable functions - the same check that would have caught an
earlier mistake this session in seconds rather than the hour it actually took.

`docs/openapi.yaml` updated with all three new resources. Full suite re-run afterward: still 1 of
25, the same pre-existing, unrelated issue as every check this session.

**Still open**: no client-side screens yet for managing people or credit_roles, and no credits
section on the titles form itself - the API can do everything now; nothing in the client can use
it yet.

This package is **build 23**.

**In progress: the foundation for people and credits - director, artist, author, and any other
role, as real relations rather than free text.** Three new tables: `people` (a real entity,
separate from companies - a director is not an organization and forcing one into `companies`'
own hardware/software/video/music `makes` set and founding-year field was a category error worth
avoiding); `credit_roles` (a short, curated, per-library-editable list rather than a fixed enum
or open text - fixed would mean a migration every time a real role turned up unpredicted, open
text would mean nothing to filter a picker by); `credits` (title + role + exactly one of person
or company, enforced by a real CHECK constraint, not just application-level discipline).

Reused `domains SET('hardware','software','video','music')` on `credit_roles` - the same shape
this session already proved out for platforms and companies, not a fourth version of the same
idea. A role can genuinely span more than one domain - Producer means roughly the same thing on
a film and an album - without needing to be two separate rows to say so.

**Done and thoroughly verified**: schema for all three tables; a real migration
(`db/migrations/002_people_and_credits.sql`) built and proven against a genuine pre-migration
database state, not just a fresh install - applied cleanly, then re-run a second time to confirm
it is safe to repeat; the CHECK constraint tested with real inserts, not just checked to exist -
confirmed it genuinely refuses a credit with both a person and a company set, refuses one with
neither, and accepts one with exactly one. A starter set of eight credit roles
(`structure/credit_roles.json`: Director, Writer, Producer, Composer, Artist, Programmer,
Graphics, Design) wired into `structure_sync()` the same way platforms and companies already are,
and into `seed_library_hardware()`'s existing copy-into-library mechanism - proved live, not
assumed: synced the templates, seeded a real library, confirmed all eight copied across with
their domains intact. Full suite re-run after all of this: still 1 of 25, the same pre-existing,
unrelated issue as every check this session - nothing here has regressed.

**Still open, not yet built**: the API layer for people, credit_roles, and credits (no
create/read/update/delete for any of the three yet); the client-side editors for people and
credit_roles, matching the pattern companies and tags already have; and the actual point of the
whole feature - a credits section on the titles form, with a role picker filtered to the title's
own domain, so adding a movie offers Director and not Composer. The schema and seed data are
real and tested; there is no way to use any of it yet.

This package is **build 22**, reflecting real, tested foundation - not a usable feature yet.

**In progress: replaced platforms.machine_class with platforms.domains, a direct SET of the
sections a platform participates in - the same shape companies.makes already used.**
machine_class only ever existed to look up a fixed class-to-sections table (computer/console/
handheld -> hardware+software, video-format -> video, audio-format -> music); a platform now
states that directly rather than through an indirect class name.

Done and verified so far: `db/schema.sql` updated; a real migration
(`db/migrations/001_platform_domains.sql`) for existing installs - adds domains, backfills it
from the old machine_class values, drops machine_class, safe to re-run; all 16 template platforms
in `structure/platforms.json` converted from `class` to `domains`, none dropped or mismapped; a
new `platform_domains_from()` helper mirroring the proven `company_makes_from()` pattern;
`seed_library_categories()` substantially rewritten so building a platform's category tree reads
its own `domains` directly for section/branch placement, while keeping a smaller internal kind
lookup (computer/console/handheld) for the one thing domains alone genuinely cannot express - a
template category scoped to just one of those three, which domains has no way to distinguish.
Full suite re-run after all of this: still 1 of 25, the same pre-existing, unrelated issue as
every check this session - nothing here has regressed.

**Still open, not yet done**: `templates/taxonomy/tree.php`'s "Any machine" filter still reads
the old column name and needs to move to the finer kind distinction instead of domains directly,
since that filter was never about domains - it only ever offered computer/console/handheld, never
video or audio format, so it needs what step 3's internal kind-derivation already computes, not
the raw domains value. The migration itself (`php bin/migrate.php up`) has not yet been run and
proven against a real pre-migration database - only tested by seeding a fresh one, which never
exercises the ALTER/backfill/DROP path a real upgrade needs. Platforms' own API and client still
don't expose `domains` as a settable field at all - creating a platform through /platforms still
cannot mark it as a video or audio format, which was the actual, original ask this whole change
grew out of.

This package is **build 21**, reflecting real, tested progress - but not a finished feature.
Deploying now gets you a working, unregressed instance with a correctly modeled `domains` column;
it does not yet get you the ability to create a new video/audio-format platform through the UI.

**The Kind feature - deferred earlier this session as separate, higher-stakes work - is now
built.** `PATCH /categories/{id}` accepts an optional `role`; when sent, it switches the branch's
kind and, for a hardware/software-flavoured one, cascades the matching section across the
branch's entire subtree - the real web form's own role/section-switch, not a re-derivation of it.
A root refuses outright, matching what the real form does. `other` leaves the section as it is,
the same "nothing directly says nothing about which side of the shop" reasoning the original
carries.

Scoped by direct request to match the real app exactly: five kinds - other, machine, peripheral,
game, application - the same five the web form's rename has ever offered, not the fuller set the
schema and the sections table separately allow. Checking this before building anything turned up
something worth knowing on its own: video and music sections hold real, substantial seeded data
- 18 and 10 categories respectively in a fresh library - but nothing anywhere in the real web
app's own interface, in any screen, has ever offered a way to create or reassign a branch into
either one. That gap was already there; this round matches it rather than closing it, since
closing it was explicitly not what was asked for.

Proved live with a genuine multi-level subtree, not a single row: switched Peripherals - with
three real children and one grandchild beneath it - from hardware to a software-flavoured kind,
and confirmed via direct query that all five rows in that subtree moved together. Confirmed `other`
correctly leaves an existing hardware row's section untouched. Confirmed a root and an invalid
kind value are both refused with the real, specific messages.

`docs/openapi.yaml` updated to document `role` on the categories PATCH.

This package is **build 18**.

**New: the categories API - create, rename, move, delete - the last piece of the taxonomy
family this session set out to complete.** Curator-or-better on the branch's own library,
matched exactly to `require_tree_access()`. Deliberately narrower than the real tree editor on
purpose: no drag-and-drop reordering, no copy-subtree, and rename does not carry the real
screen's role/section-switch cascade - that rewrites `section_id` across an entire subtree and is
real, separate, higher-stakes work worth its own round, not folded into this one by habit.

Move reuses the real screen's own loop-prevention and subtree section-cascade rather than
re-deriving either. Delete carries all three of the real screen's guards, none skipped: a root,
or the library's last software-filing branch, refuses outright
(`category_protected_reason()`); a branch still holding entries refuses; a branch still
classifying hardware models refuses, since that foreign key is `ON DELETE SET NULL` and would
otherwise silently orphan them with nothing in the interface showing it happened.

**This one had real trouble getting here, and it is worth an honest account of what actually
happened, not just the clean result.**

A str_replace edit while inserting the new functions accidentally deleted the
`function api_companies_index(): void` line itself, leaving a bare `{` at file scope where a
function signature should have been. PHP treats a lone brace block like that as code that runs
immediately when the file loads, not as a function body - so every request, regardless of route,
hit an auth check meant to run only inside that one function. Every single thing this server
does stopped working, `/status.json` included. Found by direct, methodical elimination rather
than guessing: ruled out the database, ruled out routing, isolated the failure to file *loading*
rather than request *handling* by `require`-ing the file directly with no HTTP request at all,
narrowed it to the one file, then read the raw lines around the last new function until the
missing signature was visible. Fixed, and confirmed fixed the same way - not just that the
server answered again, but that every function added across this whole session still exists as
a real, callable, correctly-scoped function, checked by name, one at a time.

**A second, genuine, pre-existing bug found while testing the fix, not caused by it**: this
session's admin bypass in the new curator checks used `is_admin()`, which reads `current_user()`
- purely session-based, with no bearer-token awareness at all. A token-authenticated admin
request was silently treated as a non-admin one. It went unnoticed through companies, tags, and
platforms because in every test that mattered there, the *other* half of the `OR` condition
(`can_structure_library()`/`can_own_library()`, both genuinely token-aware) already granted
access on its own for a real, valid library - the gap only became visible testing a template row
with no library at all, the one case where nothing but the broken admin check could have
mattered. Fixed everywhere it appeared - five sites across companies, tags, platforms, and
categories - replaced with `is_admin_user(acting_user())`, the same token-aware pattern
`can_edit_platform()` already uses and its own comment already warns about this exact trap.

**A third, smaller issue, caught by the full suite rather than missed**: three rounds of removing
companies, tags, then platforms from a shared generic route's alternation, one at a time, left it
as `/(libraries)` - a regex that still looks like an alternation but no longer has more than one
option in it. `tests/copy.php`'s "every route is documented" check only knows how to expand a
real `|`-separated alternation, and correctly flagged this as neither that nor a plain path.
Investigating properly turned up something more interesting than a cosmetic fix: the real,
dedicated `POST /api/v1/libraries` route was already registered earlier and always won; the
generic path was not just unreachable, the function itself has always explicitly refused
`'libraries'` as a type. Removed the route entirely rather than repair something with no valid
reachable case.

`docs/openapi.yaml` updated with all five new operations and a new `Category` schema. Full suite
re-run after every one of these three fixes, not just the last: 1 of 25, the same pre-existing,
unrelated issue as every check this session.

This package is **build 14**.

**New: the platforms API - the last piece of the taxonomy family, and the one deliberately left
for last.** Owner-or-better on the library, not merely curator - matched exactly to
`can_edit_platform()`, not approximated. A platform is the root a whole branch of the filing tree
hangs from, and the real web screen already treats it as a step above ordinary curation.

**Replaced a hardcoded, depth-limited category-cleanup query with a real, general one already
sitting in the codebase.** `platforms_manage_save()`'s delete branch checks and removes a
platform's category branch down exactly two levels, via nested subqueries - a category tree can
go deeper than that. Reused `category_subtree_ids()` instead, a proper, path-based, any-depth
function already used elsewhere in this codebase, rather than carrying a depth limit into the API
that the original itself only carries by not having been rewritten yet.

Worth being precise about what this actually protects against, since an early read of the risk
overstated it: items always carry both `platform_id` and `category_id` together, so the platform-
wide item count checked first already blocks deletion in the overwhelming majority of real cases,
regardless of category depth. The deeper, per-branch check - what this session's fix actually
changed - is defense against the two counts drifting apart on already-inconsistent data, the same
gap the original code's own comment acknowledges ("the two could drift") rather than something
this session found freshly broken. A real improvement, correctly scoped as one.

Also carries `platform_ensure_root()` on create (the branch a new machine needs to file anything
under) and the same category-branch cleanup on delete, both reused from the real controller rather
than re-derived.

Proved live: owner succeeds, curator-only is correctly refused (a stricter bar than companies'
own curator-level check, matched deliberately rather than reused by habit), update works, a
duplicate name in the same library is refused, an occupied platform's delete is refused with the
real item count, and an empty platform's delete removes its category branch along with it -
checked directly against the database, not assumed from a status code.

`docs/openapi.yaml`'s existing `/platforms` `POST` documentation was stale from an older, more
generic implementation - documented `manufacturer` and `sort_order`, neither of which the real
save logic has ever accepted, and never mentioned the required `library_id` at all. Rewritten to
match what this session's implementation actually does, alongside the new PATCH/PUT/DELETE.

Full suite re-run afterward: still 1 of 25, the same pre-existing, unrelated issue as every check
this session.

**Client-side editing for platforms is not built this round** - the same API-first split every
other taxonomy type in this family has followed.

This package is **build 12**.

**New: `tags` API - create, update, delete.** Found something important before writing any new
code: a pre-existing, generic `api_taxonomy_create()` already handled tag *creation* (and
platforms, categories, companies too) - but its own comment claiming "companies, tags need only
write access" directly contradicts what the real web screen's `taxonomy_save()` actually
enforces, which is `require_manage()` - curator-or-better - unconditionally, before any
type-specific branch even runs. That mismatch was already live for companies until this
session's earlier fix; it was still live for tags until now.

No `library_id` exists on tags at all - genuinely instance-wide, unlike companies. Checked here
as "curates at least one library" (`accessible_library_ids($user, ACCESS_CURATOR)` non-empty),
the closest real equivalent to what the web side checks against whichever library happens to be
the session's current one.

**A real nuance surfaced while testing, worth being honest about rather than quietly smoothing
over**: every account gets its own personal library automatically on creation, owned outright -
so "curates at least one library" is satisfied by nearly any real account, including a brand
new one, through that personal library alone. This is not a bug this session introduced; the
real web screen has the same basic looseness, since `require_manage()` checks whatever library
happens to be current in the session, which for many accounts will *be* their own personal one.
Tags are low-stakes - free-form labels - so this was left as the closest honest equivalent to the
real, already-imperfect original, not force-fit into a stricter rule that would make the API
disagree with what the web screen actually does today.

Registered ahead of the older generic route, the same shadowing pattern `api_companies_create()`
already established - `companies` and `tags` removed from that route's type alternation
entirely now that both have their own, correctly-permissioned handlers, so a future reader is not
misled into thinking the generic path still serves them.

Proved live: a contributor with only contributor-level access on a real shared library still
succeeds via their own personal library (the nuance above, not a bug); rename and delete both
work; delete is correctly refused - with the exact right entry count and grammar - while a real
item still carries the tag.

`docs/openapi.yaml` updated. Full suite re-run afterward: still 1 of 25, unchanged.

**Client-side tags editing is not built this round** - matching how `companies`' API landed as
its own complete piece before client editing followed a separate session.

This package is **build 10**.

**New: the companies API, built from scratch - full CRUD, not just the read side that already
existed.** Turned out companies have no dedicated management screen in the real app at all - they
route through a generic taxonomy handler shared with platforms and tags
(`taxonomy_index()`/`taxonomy_save()`, dispatched via a catch-all `/manage/([a-z]+)` route), which
this API reimplements the companies branch of rather than guessing at a shape.

**A genuinely different permission tier from titles and locations**: companies are gated by
`require_manage()` on the real web screen - curator-or-better on the library, not just "can write
something somewhere." Found the real per-library check already sitting in the codebase
(`can_structure_library($libraryId)`, what `can_manage_library()` itself delegates to) and reused
it rather than inventing a parallel one. Proved the distinction live: a genuine contributor-only
account is refused with the exact right message; a curator or admin succeeds.

`makes` (the hardware/software SET column) and `library_id` were both missing from
`company_to_api()`'s response entirely - added, since an editable company needs to show its own
current value back.

Delete carries the same live-vs-trash distinction the web screen's delete already has: refused
while a live entry still points at this, with a different message when only a deleted entry does
(deleted rows keep their foreign keys) - proved with a real item attached, not just the empty-row
case.

Deliberately narrower than the web screen on purpose: no logo upload yet, the same restraint
titles' own form already applied to features the API has nowhere to receive.

`docs/openapi.yaml` updated with all four new operations. Full suite re-run afterward: still 1 of
25, the same pre-existing, unrelated issue as every check this session.

**Client-side editing for companies is the natural next piece** - this round covers the API only,
matching how titles' API landed before its own client editing did.

**`debug` and `debug_status` are now real answer-file options**, not just something you edit into
`config.local.php` by hand after the fact. `bin/install.php --example` now shows both, with the
same documentation this changelog already carries; `bin/install.php --answers your.rsp` writes
whichever values you set straight into the real config, verified live end to end - a real `.rsp`
with `debug_status = 1`, through a real install, landing correctly in the written config, `/status/
debug` answering with real data immediately afterward, no manual edit in between.

**`/status/debug` now shows real, useful detail once switched on** - not just build and version,
but migration status, schema status, the three PHP settings that actually explain a failed photo
upload (`memory_limit`, `upload_max_filesize`, `post_max_size`), and which metadata sources are
configured (never their credentials - the same restraint `admin/status` already applies).

The database-independence this endpoint was built around from the start still holds with the
larger response: proved live that with the database genuinely unreachable, the new fields
(migrations, schema, metadata providers) are cleanly omitted rather than crashing the whole
response, while build, version, and PHP settings - none of which need a database - still answer
correctly, and the endpoint still reports `503`/"unavailable" honestly rather than pretending
everything is fine.

This package is **build 2**.

**New: `/status/debug`, a third tier past `/status` and `admin/status`.** Off by default, gated
by its own switch - `debug_status` in `config.local.php`, separate from the existing `debug` flag
on purpose, since "show me a PHP stack trace" and "tell me the build number" are different
questions a person might want answered independently of each other. When it is off, the address
does not just refuse - it 404s, the same shape as a path nothing has ever mapped, so a stranger
probing this instance cannot tell the difference between "not built" and "turned off."

Answers what the other two tiers withhold on purpose - not more health data, a different
question: which build is this, and when did it land here. Build number comes from a plain file,
`BUILD`, at the project root - incremented by hand once per package, since there is no CI here to
do it automatically yet. `deployed_at` is free: `config.local.php` gets rewritten by `install.php`
on every deploy this project does today, a full reinstall rather than a patch, so that file's own
mtime is an honest answer with nothing new to maintain.

Proved all four real combinations live, not just the toggle-on happy path: switch off with a
healthy database (404), switch on with a healthy database (real data), switch on with the
database genuinely unreachable (still answers, correctly reports "unavailable"), and - the
combination worth catching before it shipped, not after - switch off *and* the database
unreachable at the same time, confirming the off-switch's 404 does not accidentally depend on
`not_found()`'s normal rendering path, which needs the same database connection this switch has
nothing to do with.

This package is **build 1** - the first to actually carry this mechanism. Every `retrohive.tar.gz`
after this one increments `BUILD` by one before packaging.

**New: the locations API, built from scratch.** Unlike titles, this had zero endpoints before
tonight - the web manage screen has always worked directly against the database through a
single multiplexed `locations_save()` action (one POST, an `action` field deciding create,
update or delete). The API gets real REST verbs instead - GET, POST, PATCH/PUT, DELETE -
matching every other resource, while reusing the exact same model-layer functions the web
controller already calls (`location_would_loop()`, `location_name_taken()`,
`location_subtree_ids()`) rather than re-implementing the business rules a second time.

Proved every real rule live, not just the happy path: a root and a nested child both create
correctly with the right materialised path and depth; a duplicate name at the same level is
refused with the exact message the web form gives; trying to make a location its own ancestor
is refused; an empty location deletes cleanly; a location with a real item filed in it refuses
deletion with the exact singular/plural grammar the original `sprintf()` already handled
("1 entry is filed..." vs "2 entries are filed...").

`docs/openapi.yaml` updated with both new paths and a new `Location` schema. Full suite re-run
afterward: still 1 of 25, the same pre-existing, unrelated issue as every check tonight.

**New: `GET /api/v1/admin/status`** - the detail `/status`/`/status.json` deliberately withhold,
now available to an authenticated administrator instead of a stranger. Real version number, PHP
version, migration and schema status, and which metadata sources are configured - never their
stored credentials (the `params` column), only whether each is on and when it last answered.

Composed from `update_status()`, a real function that already computed the version/migration/
schema answer and had no caller anywhere in this codebase before this one - not re-derived.

Verified all three real cases live, not just the happy path: no token refuses with 401, a
genuine non-admin account refuses with 403 specifically (not just "not logged in"), and a real
administrator gets the full response. `docs/openapi.yaml` updated to match, and the full suite
re-run afterward to confirm nothing regressed.

**New: `/status` and `/status.json`** - a public, unauthenticated status page and its JSON
equivalent, sitting between `/healthz` (machine-only, bare "ok"/"unavailable") and the full
admin panel (authenticated, everything). Deliberately matches `/healthz`'s own stated security
reasoning rather than quietly relaxing it: no version number, no table counts, no library or
user data - operational status, database connectivity, and a timestamp, nothing a public,
unauthenticated visitor shouldn't see.

Built to survive the exact failure it exists to report: neither route goes through the normal
`render()`/`layout.php` path, because that layout calls `working_library()`,
`unread_notification_count()` and a raw footer query - all of which need the same database
connection this page is meant to report on. A status page that cannot load while the database
is down fails at the one moment it has a job to do. Proved this live, not just reasoned about
it - pointed the config at a nonexistent database and confirmed both routes still render
correctly, reporting "Unavailable" / `503` rather than a fatal error.

**Fixed a real installer bug**: `bin/install.php` and `bin/diagnose-join.php` still required
`src/templates.php`, which was renamed to `src/structure.php` weeks ago as part of the
starter-data -> structure rename. Every other caller of that file was updated at the time;
these two were missed because the require path is built by string concatenation
(`'templates' . '.php'`), not written out literally, so a text search for the filename never
found them. A fresh install now fails immediately after writing `config.local.php` - late
enough to look like a database problem, which is what made this one hide as long as it did.
Found via a real, full `bin/install.php --answers ...` run reaching the "Done." line
end-to-end, not just a syntax check.

**New: Video and Music sections, alongside Hardware and Software.** Physical media
collections - VHS, LaserDisc, DVD, Blu-ray, Vinyl, Cassette, CD - are now first-class,
not bolted on. The redesign that made this possible:

- `categories.domain` (an ENUM of exactly two values) is now `categories.section_id`,
  a real foreign key to a new `sections` table. A future section - Books, Board Games,
  whatever comes next - is an INSERT, not a migration.
- `platforms` stays one shared table across every section, exactly as it already was
  shared between hardware and software. VHS/DVD/Vinyl/CD are platform rows with a new
  `machine_class` of `video-format`/`audio-format`, reusing the same mechanism that
  already let Mega Drive and Saturn be platforms without being computers.
- `titles`/`software_models` - the "one canonical work, many owned copies" mechanism
  already proven for games - are reused as-is for movies, TV shows, and music. No new
  tables needed there.
- Deliberately *not* split further: Games/Applications stay one section (Software),
  matching how Movies/TV Shows stay one section (Video) rather than each becoming its
  own top-level concept - `role` already carries that distinction one level down.
- Item photos needed no changes at all - `item_images` was always keyed purely on
  `item_id`, with zero domain/section coupling in its own schema.

**Every write-path across the whole codebase updated to match** - roughly 30 real
sites across `src/`, found by two full sweeps with different search patterns (PHP
array-key access, then raw SQL column references), since the first sweep alone missed
real, crash-causing bugs including `category_tree()` (the actual taxonomy editor
screen, silently returning nothing for every user) and `seed_library_categories()`
(the mechanism that builds a platform's entire category tree, rewritten to be generic
across all sections rather than hardcoded to two).

**One genuine architectural bug found and fixed along the way**: the Music section's
one content category shared its slug with the section's own internal slug, causing
the copy-into-library mechanism to mistake the organisational branch for the content
category already existing, and silently skip copying it. Fixed by giving the content
category its own distinct slug.

Full test suite: 1 of 25 suites reporting failures, identical to the state before this
redesign began - the one remaining failure is a pre-existing, unrelated platform-name-
matching limitation, confirmed via the pristine backup to predate this session entirely.

**The 8-of-25 test suite failures from the structure-data trim are fixed — down to 1.** Every
failure traced back to a real, specific missing dependency, found by tracing the actual PHP call
stack from each fatal error rather than guessing, then restored from the pristine pre-trim backup
(never re-inflating past what was actually needed): platforms (`mega-drive`, `saturn`, `pc`,
`cd32`, `cdtv`, `dreamcast`, `game-gear`), categories (genres under Games and Applications,
Console/Handheld/Storage/Displays branches), companies (7 software studios, 2 hardware
manufacturers), and three hardware models (`Amiga 500`, a Mega Drive, a Game Gear, a PC, a
CD32) with their own slot vocabulary.

Two real, pre-existing test bugs found and fixed along the way, unrelated to the trim: a test
comparing "the first library by id" assumed it would already hold seeded categories, when it was
actually testdb.sh's own unseeded administrator account (`ensure_first_library()` no longer
copies structure data on its own - a shelf starts empty now, deliberately); and a stale reference
to `template_last_error` from an earlier round's `structure_last_error` rename.

Several assertions were checking the *scale* of the pre-trim dataset (`>= 50 categories`,
`>= 20 genres`, `> 300 hardware_vocab` entries) rather than correctness. Rather than re-inflate
the data to satisfy them - which would undo the trim itself - their thresholds were updated to
reflect the new, deliberately minimal baseline, with comments explaining why.

**One failure remains, deliberately not fixed**: `metadata.php`'s "C64 matched" test. Confirmed
against the pristine backup that this predates the trim entirely - the platform-name-matching
algorithm strips manufacturer prefixes like "Commodore" but has no abbreviation handling, so
"C64" never matches TheGamesDB's "Commodore 64". Fixing it is a real behavior change to
`metadata_suggest_platform_map()`, not a data restoration, and was left out of scope.

Every fix in this pass was proven against a live database before moving to the next - the suite
was run after each individual change, not just once at the end.

**The GitLab repository itself is now `retrohive`**, reversing the deliberate exception from the
entry below. Every reference across all five repositories updated to match: this repo's own local
directory, `retrohive-tools/projects.json` (the single source of truth `publish-all.sh` reads),
its `--tag`/`--label` logic (which decided whether to tag the server by comparing against the
literal string `"retrohive"` — found and fixed before it could silently mis-tag a release), the
test suite's sibling-directory auto-detection in `bin/testdb.sh`, and the example database
name/username in `src/config.local.php.example`.

**Operational step this leaves on the real server, not automated here**: the existing checkout at
`/srv/www/vhosts/retrohive.noh.nu` still has its git `origin` pointed at the old
`retrohive.git` URL. The next full `refresh-retrohive.sh` run self-heals this — it does a
`rm -Rf` and fresh clone from the new URL — but a plain `git pull` against the existing checkout,
run before that, will fail against a remote that still thinks it's named `retrohive`. Run the
full refresh script once, not a bare pull, the first time after this change.

**Found while investigating this, unrelated to today's specific request**: `retrohive-tools/tests/copy.php`
was still asserting the update-check URL contained `norrorthoarders/retrohive/releases/latest`,
even though the real source already said `retrohive` — a stale assertion left over from an
earlier round's GitHub-org rename, silently wrong until this pass caught it.

Verified live: ran `bin/testdb.sh` with `RV_APP_ROOT` unset, relying entirely on the fixed
auto-detection to find the renamed directory, then the full suite the same way. Same pre-existing
8-of-25 baseline as every other round tonight.

**Every user-facing "RetroHive" is now "RetroHive"** — config defaults (`app_name`,
`smtp_from_name`, the SMTP from-address), the entire web and CLI installer, account and
notification emails, both User-Agent strings sent to external APIs, `docs/openapi.yaml`'s
title, and every code comment describing the product generically. Deliberately left alone: the
GitLab repository name (`retrohive`, matching the live deploy pipeline) and every internal code
identifier — table names, function names, the directory this repo lives in.

Verified live, not assumed: booted the app with no `app_name` override and confirmed the actual
rendered login page says "RetroHive". Full suite re-run afterward at the same pre-existing
8-of-25 baseline — nothing depended on the old string.

**Removed `db/seed-templates.sql`** — 2,832 lines of legacy SQL, confirmed genuinely dead before
deletion: no code path anywhere calls `run_sql_file()` on it, and `bin/testdb.sh`'s own comment
already called it "a smaller and older copy" of what `structure/*.json` now provides. Six
comments across `src/structure.php`, `public/install.php`, and four files in `retrohive-tools`
referenced it by name to explain real, still-valid reasoning about the code's behavior — each
reworded to describe the old file as history rather than imply it still exists to be read.
`db/seed.sql`'s own header made the same reference and used the pre-rename "starter data" phrase
throughout — a gap in the earlier rename sweep, which never checked `.sql` files. Fixed.

Verified against the real test suite before and after: the same 8-of-25 pre-existing baseline,
nothing newly broken by the removal.

**Renamed `starter-data/` to `structure/`**, matching a distinction that mattered: this data is
vocabulary an entry is filed against - what a company, category, platform or model *is* - not an
example of one. "Template" is reserved now for actual example entries, a feature that does not
exist yet; conflating the two was the source of real confusion. `src/templates.php` became
`src/structure.php`; every `template_*` function, database-persisted setting key, view variable,
and the installer's answer-file key all followed.

**Found and fixed while doing it, not before**: `src/metadata.php` had hardcoded paths to the old
directory that would have silently pointed at nothing; `public/index.php` - the actual front
controller, run on every request - still required the old filename; `src/installer.php`'s own
boot-check called a function that no longer existed; both installers still called the renamed
sync function under its old name. Each was caught by an exhaustive repo-wide sweep repeated after
every batch of fixes, not by a single pass - the sweep found something new five times in a row
before it finally came back empty, and only then was any of this trusted.

**Operational note**: the `.rsp` answer-file format changed. `[install] templates = remote` is
now `[install] structure = remote` - the deployed server's real response file at
`/srv/www/vhosts/retrohive-install.rsp` needs that one line updated before the next install run
that uses it.

**Verified live**, not just linted: `bin/testdb.sh` reports "structure data loaded" on a real
database, and the full 25-suite run shows the exact same pre-existing 8-suite gap as before this
rename (the earlier, unrelated data-trim work's open items) - nothing new broke.

**Renamed: "fits" → "compatible/compatibility"**, everywhere it named the structured
hardware-compatibility system rather than plain prose. `model_fits` → `model_compatibility`,
`item_fits` → `item_compatibility`, `fits_model_id` → `compatible_model_id`, `effective_fits()` →
`effective_compatibility()`, and matching renames through every function, HTML field, JS data
attribute, and the API's own error message — which used to tell a client *"does not list %s among
the machines it fits"*, leaking the old name into text a real person could read. Left alone
deliberately: `item_hardware.fits` and `hardware_models.fits_note`, both genuine free-text prose
fields where "fits" is just English, not a system name. Verified against a real database — the
renamed `model_compatibility` table and `model_compatibility_ids()` function both correctly find
the Amiga 2000 as compatible with BigRAM 2008, the same relationship proven working before the
rename.

**Deployment policy**

- **Migrations are deferred until the first public release.** `db/migrations/README.md` already
  said this — "empty, deliberately... until there is a version in somebody's hands there is no
  history worth carrying" — and the 26 files that had accumulated there were drift from that
  stated policy, not a considered change to it. Emptied back out, after verifying `db/schema.sql`
  still reflects every column and table those 26 files touched — checked column-by-column and
  table-by-table against the actual `ALTER TABLE`/`CREATE TABLE` target in each file, not assumed.
  Deployment is a full reinstall each time until release; `php bin/migrate.php up` still works and
  will matter again once upgrades-in-place are a real thing to support.

**Web**

- **Artwork and photographs are two sections**, on the form as well as the entry. They answer
  different questions — what the release looks like, and what your copy looks like — and listing
  them together in upload order put a scan of the box between two photographs of a shelf. The
  split is on `provenance`, which the metadata agents already set.
- **"Artwork"**, one word, replacing *Official box art* and *Stock photos*.

**Installer**

- **Metadata sources are tested before they are switched on**, by both installers. They used to
  be added unconditionally, so an instance could come up with a source that had moved, gone, or
  was refusing this network — and the first anybody knew was a lookup that half worked, months
  later, with no way to tell which source was at fault. Each one is probed with the same check
  the Test button uses, against the term the source itself declares. One that does not answer is
  **not added**, is named on the summary, and is written to the instance's metadata log — an
  unattended install has nobody reading the terminal.

All notable changes to RetroHive are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[semantic versioning](https://semver.org/).

## [0.5.0] — unreleased

First public release.

### Added

**Catalogue**

- Separate **hardware** and **software** catalogues: machines, peripherals, games and
  applications, each with their own fields.
- A **category tree per machine**. Every branch declares what it holds, and branches beneath it
  inherit that unless they say otherwise.
- **Machine and software models**: define an Amiga 500 or a boxed cartridge once, and every
  copy inherits its specification, contents and media.
- **What is fitted to what** — an accelerator in an A1200, a SIMM on the accelerator.
- Photographs with box, manual and media condition; loans; purchase and sale records; and
  arbitrary specification rows per entry.

**Libraries**

- Any number of libraries, private or shared, each with its own locations, companies,
  platforms, categories and models.
- Six access levels per library: **Library Viewer, Contributor, Editor, Curator, Admin,
  Owner** — from reading to owning, with membership by invitation.

**Installing**

- **Fixed: a command line install as root left files the web server could not read.** The
  wizard runs as the web server and never had the problem; a shell does not, so
  `src/config.local.php` came out `root:root` at 0640 and the site answered 503 with nothing in
  any log. `bin/install.php` now sets the owner of the configuration and of `public/uploads`
  when it is root, taking the account from the new `[server]` section or looking for `wwwrun`,
  `www-data`, `apache`, `nginx` and `http`.
- **`bin/install.php --interactive`** asks the questions instead of needing a file, checking
  each answer as it is given and not echoing passwords. `--save-answers` writes the result out
  afterwards, so a machine done by hand can install the next one unattended.
- **`bin/install.php`** installs from an answer file instead of seven pages of questions:
  `--example` prints one, `--dry-run` checks everything and writes nothing, and the exit status
  is 0 only if the install finished. It includes the web installer for its helpers rather than
  keeping a second copy of them to drift. Every complaint about the answers is reported at once.
- The answer file is now the **response file**: `.rsp` rather than `.ini`, and the drop zone
  reads *Response configuration*. Still INI in shape, and `.ini` is still accepted by the file
  picker.
- The web installer **writes an answer file** on its review step and again at the end, and
  **reads one** on its first,
  so the second machine is one page and a drop rather than seven pages of the same answers. The
  file is checked as it lands. A complete one — credentials included, database answering —
  skips the remaining five pages and installs on the spot; one with the credentials still blank
  fills the pages in instead; an unusable one is marked and the ordinary installation carries
  on underneath. `deploy = erase` stops to be confirmed unless the file also says
  `force_erase = 1`, in both installers: an answer file gets copied between machines, and the
  collection it destroys is whichever database it happens to name that day.
- **Fixed: `delete_installer` broke the command line installer.** Everything the two share —
  the requirement checks, the database work, the answer file — was in `public/install.php`, so
  deleting the wizard took half of `bin/install.php` with it and the next run died on a missing
  require. That half now lives in `src/installer.php`, which nothing deletes.
- `delete_installer` removes `public/install.php` when the install finishes, and `sign_in`
  lands the browser on the instance already signed in as the administrator it just made. Both
  off unless the answer file turns them on.
- A section written twice in an answer file is refused. `parse_ini_string()` keeps the last and
  discards the first without a word, which for `deploy` is the difference between rebuilding a
  database and leaving it alone.
  No username or password is written into it: those come out as `change-…-here`, and a file
  still carrying one is refused rather than installed with a database user by that name.
- The answer file is INI, parsed by `parse_ini_string()` and executed never — the wizard takes
  one by upload, and `require` on an uploaded file is remote code execution wearing a hat. One
  definition, in `public/install.php`, used by both installers.
- `--quiet` now says nothing at all when it works, with the reason on stderr and a non-zero
  status when it does not. `RETROHIVE_DB_PASS` and `RETROHIVE_ADMIN_PASS` override the two
  passwords so the answer file can be templated and hold no secret, and `--answers -` reads it
  from standard input so it need not exist on disk.

**Web**

- The image set a lookup fills is **Stock images** on both domains, in the form, the entry and
  the lookup review — it was Artwork in one place and Stock photos in another. `image_sections()`
  feeds the selects, so the name is now decided once.

**Audit, continued**

- **A pending registration now tells every admin**, in-app and by mail. `notify_admins()` was
  written and had no caller; a signup needing approval reached the security log and nothing else,
  so an admin who was not reading it that day found out when somebody asked why they still could
  not sign in. The link goes straight to `/manage/users`.
- **`item.lent_overdue` was a registered notification kind for a feature that no longer exists.**
  Lending was removed earlier tonight; this one entry was missed because nothing triggered it, so
  it never surfaced as broken — only as unused. Removed, and its slot in `notification_kinds()`
  taken by the new registration kind rather than left as a gap.
- **A test in `retrohive-tools` still referenced the removed kind** and only failed once the
  full suite ran after this change — a reminder that a single file's suite passing is not the
  same question as the whole tree agreeing with itself. Updated to exercise the same preference
  logic against `registration.pending` instead.

- **`rule_status()` was written and never called.** Both the form and the API still had their own
  inline `in_array(...) ? ... : 'owned'` for the status field it was built for. Both now call it,
  and `tests/fields.php` asserts they do — the same gap `rule_box_state()` had until this pass.
- **Fixed: `hardware_detail()` was written, documented, and never called.** It resolves "the
  entry's own value, or the model's if the entry has none" — its own doc comment says this exists
  to stop two pages disagreeing about which one wins. Nothing called it, so the entry page read
  `item_hardware` raw: any machine with a model set but nothing retyped onto the entry itself
  showed a **blank** model, interface, and fits field, when the model had the answer all along.
  Wired into the entry view's data and the Specification table. The edit form's pre-fill
  deliberately still reads the raw row — resolving there would silently write the model's value
  onto the entry as if someone had typed it.
- **Three functions in `installer.php` were dead**, superseded by a separately-evolved, actually
  wired implementation in `src/migrate.php` + `update.php`. Removed.
- **Four more removed**: `shared_library_ids` (a duplicate of a call made directly elsewhere),
  `log_count` (the one caller that would want it computes its own count instead),
  `metadata_debug_clear` (redundant with the reset `metadata_debug_on()` already does),
  `parts_fitting_model` (written for a model detail page that was never built — no route reaches
  one). `docs/TAXONOMY.md` referenced the last of these; corrected.
- **`notify_admins()` was found complete and unwired**; documented rather than deleted or
  silently wired in, then given its own pass: a `registration.pending` notification kind and a
  call beside the security-log line that already existed. An admin who signs up needing approval
  is told now, in-app and by mail, rather than only whoever next reads the log.
- **`store_logo()` was wrongly flagged as an unwired feature, and it was not one.** I checked
  whether that exact name was called, found it was not, and concluded company logos had no way in
  — without checking whether a *differently named* function already did the job. It does:
  `store_company_logo()` and `delete_company_logo()` are a complete, separately-written pair,
  fully wired through `taxonomy_save()` and a file input already sitting in the generic taxonomy
  edit form. Uploading a company logo has worked the whole time. `store_logo()` and its sibling
  `delete_logo()` — a generic pair for "companies or vendors", from before vendors merged into
  companies — were the genuinely dead ones, and are removed now that the working replacement is
  confirmed rather than assumed.
- **A first automated pass over-reported**: it flagged `metadata_search_amigahw`,
  `metadata_platforms_thegamesdb` and four others as dead. All are reached through
  `'metadata_search_' . $type` / `'metadata_platforms_' . $type` dispatch, not a literal call —
  checked individually against `metadata_provider_types()` before anything was touched. Two of
  the flagged names, `mobygames` and `csdb`, turned out to be **deliberately withdrawn features**
  with a test asserting they stay unused while their parsers remain reachable by name.

**API**

- **`src/rules.php`** — the rules an entry obeys, in one place, called by both the web form and
  the API. The same question had two answers before: `condition` was a validated enum on one side
  and free text on the other, and the rule that clearing "there is a box" also clears the box
  grade existed twice, in different words, with no reason to think they agreed.
- What is shared is the **rule**; what is not is the **policy on a bad value**. Each function
  returns null for "that is not one of these", and the form falls back to `unknown` while the API
  answers 422 — a person mid-page should not lose it to a select that cannot be wrong anyway, and
  a client that sent nonsense wants to know. Making those identical would have been a change to
  the web, dressed up as a refactor.

- The entry payload returns **`acquired_from`, `acquired_note`, `sold_to`, `sold_note` and
  `sold_currency`**. All five became writable last round and none was returned, so a client could
  set who a thing came from and never read it back.

- **Fixed: compatibility was read from one of the two places it is declared.** A model may name
  the machines it fits, and a single card may name them itself through `item_fits` — the
  *Compatible hardware* checkboxes on the web form. The check read only the model's list, so a
  peripheral whose compatibility had been recorded by hand looked like one that had said nothing:
  the answer came out right for the wrong reason, until somebody set a model, at which point it
  came out wrong. It calls `effective_fits()` now, which already knows the precedence.
- **Fixed: a machine with no model was refused by every peripheral that declared what it fits.**
  The check compared the machine's `model_id` to the peripheral's list and, finding NULL, read it
  as 0 and refused. Every machine in a fresh catalogue has no model — so the better a peripheral
  was catalogued, the more certainly it was rejected. Two silences, both meaning "cannot tell":
  a peripheral naming nothing goes anywhere, and a machine with no model cannot be checked
  against a list of models at all.
- **A maker or publisher can be sent by name.** `developer` and `publisher` accept a string and
  match it case-insensitively, by name then by slug, creating the company only when nothing
  matches. The app used to refuse — "add it under Companies on the web" — which is a phone
  telling somebody to go and find a computer. A near-match is **named in the log**: a source
  answering "Team17 Software Limited" to a library holding "Team17" is describing one firm, and
  no rule here can be sure of that, since the same rule would merge Sega and Sega Europe.

- **Fixed: the API has never handled a location.** Not by id, not by path — so "Where it is kept"
  on the phone was typed, sent and silently dropped. `location_path` is accepted now, matched on
  the breadcrumb somebody reads rather than on `locations.path`, which looks like the answer and
  is not: that column holds an id path (`/1/7/`) for subtree queries. Matching against it would
  have found nothing a client ever sends, with a test cheerfully saying the field was handled.
- **Provenance is writable**: `acquired_from`, `acquired_note`, `sold_to`, `sold_note`,
  `sold_currency` and `location_position`. The web has written these since it existed and the API
  accepted none of them, so an entry created from a phone could record what it cost and not who
  it came from.

- **Lending is gone from the platform.** It was half-removed already — `status_options()` had
  dropped `lent` but the columns, the enum value, the dashboard panels, the CSV columns and the
  API fields all stayed, so a client could set a status the web would not offer. Migration 0026
  finishes it: entries marked lent become owned, and **what was recorded is appended to the
  notes** rather than dropped, because somebody who wrote down who had a thing deserves to still
  be able to read it. The `lent`/`returned` event kinds stay in `item_events` for rows already
  written — deleting somebody's history is not what removing a feature means.

- **Fixed: `can_write_library()` never existed.** I invented the name; artwork import, fitting
  and unfitting all returned 500 with *Call to undefined function*. They use `can_write_item()`,
  which is also the stricter and more correct check.
- **The rules for what may be installed in what**, enforced on the server and offered through
  `/items/{id}/links/candidates`: only hardware, only peripherals, only into machines, and only
  where the peripheral either names this machine among those it fits or names none, with
  platforms agreeing.
- `/meta` reports **`app_version`**, the server's own — distinct from the API version and from
  any client's.

- **`GET /models`** — the canonical models an entry can be filed under. `items.model_id` has been
  writable for a while with no way to discover an id to put in it, which makes a writable field a
  field nobody can use. Narrowed by `category_id` the way the web's picker narrows it: a model
  belongs to a branch, and a list of every model on an instance is not a picker but a haystack.

- **The rest of `item_hardware`**: `interface`, `provides`, `fits`, `recapped_on`, `serviced_on`,
  `manufactured_year`, and the **specification rows**. Those are a JSON column of
  `{label, value}` rather than columns, because an Amiga has a chipset and a PC has a bus and
  neither list is finite. The API decodes it before sending, so a client is not parsing JSON out
  of a JSON field.

- **`/items/{id}/links`** — what is fitted to an entry and what it is fitted to, in both
  directions, plus fitting and unfitting. `item_links` is the catalogue's one genuinely
  relational idea and the API had nothing at all for it, so a phone could see *Installed
  peripherals* on the web and not know the relationship existed. `direction` decides which way
  round, because otherwise a client would have to know which of two entries is the parent before
  it could say they are related. Loops are refused through the same `item_link_would_loop()` the
  web calls.

- **Fixed: a library made through the API was invisible to whoever made it.** `owner_id` says
  whose a library is; `library_members` decides who may *see* it, and `accessible_library_ids()`
  reads the second. Neither create route wrote that row, so the library existed, appeared under
  library management — which asks the server for everything — and was missing from the caller's
  own list and every picker built from it. The web has always written both.

- `working_state` is writable and returned with the rest of the `hardware` object — the web calls
  it **Does it work**, and it is the first thing anybody asks about a machine.

- `POST` **`/libraries`** — make a library of your own, which any signed-in account may do. The
  admin route needed an administrator, so the API was stricter than the web for the same action:
  `library_create()` on the web checks only that somebody is signed in. `POST /admin/libraries`
  stays for administering an instance.

- `POST` **`/items/{id}/images/import`** — fetch a picture from a metadata source and attach it.
  The web has had this since metadata lookup existed; the API never did, so a phone could find
  the box art and not keep it. The server does the fetching, because it already knows how to
  check what came back is an image, resize it, and notice the same picture twice. Artwork lands
  as `official` provenance, never among somebody's own photographs.

- **The fields a client could read and not write.** `condition_grade`, `has_box`,
  `condition_box`, `condition_manual`, `condition_media` and `model_id` on the entry itself, and
  `model`, `board_revision`, `firmware`, `serial_number` and `modifications` from `item_hardware`
  — none of which the API accepted, so a phone could show a serial number and not correct one.
  `modifications` is the one that mattered most: with only `notes` writable, a client had to put
  modifications in the notes, which is the confusion migration 0014 exists to end.
- The detailed view returns a **`hardware`** object, null on software and on entries nobody has
  filled in. It is a query against `item_hardware` rather than a column read, so it happens on
  the single-entry view only — a list of two hundred does not need two hundred round trips for
  fields no list shows.
- Clearing **`has_box`** clears the box grade with it, as the web form does. Grading a box that
  is not there is meaningless.

- `meta.errors` on a metadata search is **always an object**. PHP encodes an empty associative
  array as `[]` and a populated one as `{...}`, so the field changed shape depending on whether
  any source had failed — disabling a single provider was enough to break a client that decoded
  the other one.

- `POST` **`/admin/users`**, so accounts can be made from a phone. Through the same
  `create_user()` the installer uses, which gives the account its personal library on the way
  past — the one shelf everybody is promised.

- `POST` and `DELETE` **`/profile/avatar`**, so a picture can be set from a phone. Multipart into
  `store_user_avatar()`, the same path the web form takes — one place decides what a valid
  picture is and what it is resized to.

- **`/admin/libraries`** — list, create, change, delete. The list is every library, not the ones
  the caller may read: an administrator needs it complete, since a library nobody can see is one
  nobody can fix. Deleting is refused for a library that still holds anything, and for the last
  one — an instance with none has nowhere to put the next thing somebody adds. Renaming moves
  the slug with it.

- `GET` **`/admin/users`** and `PATCH` **`/admin/users/{id}`**, so account management can leave
  the browser. Two refusals rather than warnings: removing the last active administrator, and
  changing your own role — undoing that would need the role just given up.

- **A 401 says which of five things went wrong.** No header at all, a token nobody has heard of,
  a revoked one, an expired one, an account since disabled — all produced "Send a valid bearer
  token in the Authorization header", which is true of every one of them and useful for none. It
  sent people to check a header that was fine. The no-header case now names the proxy in front
  as a candidate, because a header that leaves the client and does not arrive is the hardest of
  these to reason about from either end.

- **Every API refusal is now in the log.** Nothing the API did reached the log page before: no
  sign-ins, no refusals, nothing — so an operator watching the log while being told "the app
  will not save" saw an empty screen. Refusals about who you are go in the security stream, the
  rest in the server stream, with the method, the path, the status and the fields complained
  about.
- **A token issued to a device is recorded** as `api.token.issued`, named after the device, so
  "which phone was that" has an answer.

- `GET` **`/admin/logs`** with the filters the web viewer offers, plus the per-channel counts
  and the events that have actually happened, so a client draws the same tabs without four
  requests. `GET` and `POST` **`/admin/maintenance`**: every check is run to answer the list,
  because the reason to press a repair is that its check found something, and the check is run
  again afterwards so the answer says what is left.

- `docs/openapi.yaml` describes `/notifications`, `/notifications/read` and `/metadata/search`,
  which it had never mentioned. The suite now compares the routes in `public/index.php` against
  the spec and fails on anything missing — or written twice, which YAML resolves by keeping the
  last and saying nothing.

- The API suite covers the settings endpoints: every field kind, the bounds, the all-or-nothing
  rule on a batch, and that a secret never comes back. 27 assertions to 71.

- `GET`/`PATCH` **`/profile`** and **`/profile/notifications`**: your details, your password, and
  what you want to be told about.
- `GET`/`PATCH` **`/admin/settings`**: the instance settings, described rather than dumped — each
  field carries its kind, its choices and its limits, so a native client can draw the form
  without knowing the settings in advance, and a setting added later appears in an app nobody
  rebuilt. Secrets report only whether they are set.

**Instance settings**

- The paragraph above the log streams is gone. The tabs say Security and Server; explaining what
  those mean above a screen that shows them was furniture.

- The structure table **moved to the library screen**, where it answers the question people
  have. It counted the template set against the files — one answer for the whole instance — and
  now counts what a library holds against what there is to copy, beside the button that copies
  it. A row is marked only when the library has fewer; the filing tree is built once per
  platform, so its branch counts are legitimately larger. Instance settings keeps the address to
  fetch from, which is genuinely instance-wide, and the button that fetches.

- **Structure data** is one table: what this instance holds of each kind against how many the
  files held when they were last fetched, marked where they disagree. Every sync records both
  numbers and writes the local ones into the server log, so "when did the peripherals go from 4
  to 21" has an answer. An install syncs, so the record exists from the first day.
- **Force update**, beside Save, resyncs ignoring what is already present. An ordinary fetch
  skips a slug it recognises, so a correction to a row that shipped wrong could never arrive.
  Neither touches a library.
- The log **Test** panel is gone; **Write test log** sits beside Save in Logging, so it saves
  and then writes rather than testing what was stored last time somebody pressed Save.

**Fixed**

- **Deleting a machine left its branch behind.** `categories.platform_id` is `ON DELETE SET
  NULL`, so removing a platform left its root standing: the filing tree went on showing the
  machine's name with nothing behind it, nothing filed under it could say what it ran on, and
  resyncing the library did not repair it — the resync matches on slug, saw the branch and
  called the machine already built. The branch now goes with the machine, and a resync relinks
  a root that lost its platform some other way.

- A maintenance job reporting **what PHP will accept**: `post_max_size`, `upload_max_filesize`,
  `memory_limit`, which `php.ini` is actually loaded and under which SAPI. It flags an
  `upload_max_filesize` above `post_max_size` — which can never be reached, because the smaller
  number caps the whole request — and limits too low for a photograph of a boxed machine. The
  installer checked this once and is then deleted, which left no way to ask a running instance.

- **A command line install switched on no metadata sources.** The wizard has always enabled the
  ones needing no account; `bin/install.php` never did, so an instance built from a response
  file came up with nothing to look titles up with and no sign it was meant to have any. Both
  now share `installer_enable_metadata_sources()`. `metadata_sources` in the response file says
  whether to, and the wizard asks on its settings step — ticked, which is what it has always
  done without asking.

- A maintenance job for **specification names whose machine is gone**. Deleting a library takes
  its platforms and leaves the vocabulary behind pointing at rows that no longer exist —
  `ON DELETE SET NULL` on the category side, nothing at all on this one. Nothing read them and
  nothing counted them, and they accumulated: 4,552 on a database that had been used for a
  while.
- The maintenance API sent an **empty message for every job**. `maintenance_result()` calls it
  `note` and the endpoint read `message`, so the native screen showed a count and no sentence.

- **Specification names read 1158 against 589 on a freshly installed instance**, in red, with
  nothing wrong. `seed_library_hardware()` copies the interface vocabulary for a library's own
  platforms — a library with platforms and not the words for what plugs into them cannot
  describe a card — so the table grows by roughly the file's size with every library made. The
  count now takes the template rows only, and holds still as libraries are added.

- The **peripheral model count** on the settings screen read 0 while twenty-one were filed. It
  tested `role = 'peripheral'` on the model's own branch, and the tree declares that kind on the
  branch that means it — Expansions — with everything under it inheriting. A model is either a
  machine or a part, so it is counted as the counterpart of the machine line.
- Choosing a company on a **model or hardware entry** narrows the platform list only when the
  thing is a machine. A machine's maker built the platform; a peripheral's usually did not — a
  Phase 5 accelerator goes in a Commodore machine — and narrowing there removed the Amiga from
  the list and reset the platform on a model that had one.

**Metadata**

- Lookup against **OpenRetro, TheGamesDB, IGDB, the Amiga Hardware Database, the Big Book of
  Amiga Hardware, TheRetroWeb, Wikipedia, Wikimedia Commons and Wikidata**.
- Which sources answer for which branch is decided in the category tree and inherited
  downward.
- Nothing is written without review: every field and every image is offered and applied only
  when ticked.
- **Save and look up** on the entry forms, offered when the branch being filed into has a
  source switched on.

**Accounts and access**

- Local accounts, or sign-in through **LDAP / Active Directory** with group-to-role mapping.
- Registration modes: closed, public, by secret address, or by invitation — with optional
  email confirmation or administrator approval.
- API tokens for mobile and third-party clients.

**Running it**

- Browser installer with requirement checks, or a command-line install.
- Structure data for 63 machines, fetched from GitHub or the shipped copies. An instance
  running against template files older than itself still arrives working: what is a judgement
  rather than data lives in the code, and the tree is repaired on both sides if the fetched
  copy declares nothing.
- Maintenance jobs for the things that drift: orphaned photographs, photograph rows whose file
  is gone, branches with no machine, machines with no branch, blurbs left in notes.
- Syslog or file logging, SMTP with a proven-delivery check, and a `/healthz` endpoint for a
  load balancer.

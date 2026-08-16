-- "What goes in it" is gone; specifications say the same thing.
--
-- `model_slots` held a counted list of connectors per hardware model - five
-- Zorro, four ISA - alongside a Specifications field that said the same in
-- prose. Two ways to record one fact, and the structured one could not be
-- edited from any screen: the only way to change it was editing
-- hardware_machines.json and re-syncing.
--
-- The counted form would have been worth keeping if anything used it - "which of
-- my cards fit this machine" needs a controlled vocabulary and a count, and
-- prose cannot answer it. Nothing did. It was seeded, copied between libraries,
-- checked by a maintenance job, and displayed; never read by a decision. A
-- second way to say something, editable from nowhere, is complexity without a
-- return.
--
-- `hardware_vocab` stays. It carries sockets, form factors and features as well,
-- and `hardware_models.interface_vocab_id` uses it to say what a card plugs
-- into - which is a different question and one that is answered.

DROP TABLE IF EXISTS model_slots;

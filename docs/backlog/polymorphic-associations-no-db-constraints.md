# Polymorphic associations have no DB-level constraints

`Transfer.giver/taker`, `Membership.member`, `ExternalIdentifier.owner` are all polymorphic with
no FK constraints at the DB level. Direct SQL inserts (migrations, scripts, psql) can create
orphaned references that AR will never catch.

This is a Rails limitation (polymorphic FKs are non-trivial), but it means any bulk operation that
bypasses AR is a data integrity risk.

**Mitigation:** document this explicitly; add a periodic integrity check job that scans for
orphaned polymorphic references.

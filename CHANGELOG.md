# Changelog

## Unreleased

### Changed

- [TD-1618] Use TdCache.ConceptCache instead of TdPerms.BusinessConceptCache
 
### Removed

- Changes to business concept link count & rule count are now reindexed by bg

## [2.19.0] 2019-05-14

### Fixed

- [TD-1774] Newline is missing in logger format

### Changed

- [TD-1660] Will only update business concept link_count on add_relation/delete_relation event if "target_type" is "data_field"
- Update to phoenix 1.4, ecto 3.0, exq 0.13, redix 0.8.2

## [2.16.0] 2019-04-01

### Added

- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to override format

## [2.7.0] 2018-01-17

### Changed

- Modified the identifiers of those events creating or deleting links

### Changed

- Completed notification engine for create_comment events

## [2.6.3] 2018-11-22

### Changed

- Completed notification engine for create_comment events

## [2.6.2] 2018-11-12

### Changed

- Subscrition event processor get email from cache by full_name
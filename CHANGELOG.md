# Changelog

## [Unreleased]

### Changed

- [TD-2508] Update to Elixir 1.10

## [3.8.0] 2019-10-14

### Changed

- [TD-1987] Change text in table header of Rule Notification email

## [3.5.1] 2019-09-03

### Fixed

- [TD-2081] Event stream consumer did not respect redis_host and port config options

## [3.5.0] 2019-09-02

### Added

- [TD-1907] Notification under failed rule results 

## [3.2.0] 2019-07-24

### Changed

- [TD-2002] Update td-cache and delete permissions list from config

## [3.1.0] 2019-07-08

### Changed

- [TD-1618] Cache improvements (use td-cache instead of td-perms)
- [TD-1924] Use Jason instead of Poison for JSON encoding/decoding

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

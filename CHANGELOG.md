# Changelog

## [4.7.0] 2020-11-03

### Added

- [TD-2952] As a user with permission to execute rules I want to run implementations manually
  from the implementations screen for Kubernetes Cluster.

## [4.5.0] 2020-10-05

### Changed

- [TD-2939] Limit simultaneous sending of emails

## [4.2.0] 2020-08-17

### Changed

- [TD-2810] `tls` as environment variable
- [TD-2532] User-Rule Subscriptions

## [4.1.0] 2020-07-23

### Fixed

- [TD-2846] Subscriptions with notifications could not be deleted

## [4.0.0] 2020-07-01

### Added

- [TD-2637] Audit events are now read from the Redis stream `audit:events`

### Changed

- [TD-2637] Renamed events:
  - event `create_comment` is now `comment_created`
  - event `add_relation` is now `relation_created`
  - event `delete_relation` is now `relation_deleted`
  - event `concept_sent_for_approval` is now `concept_submitted`
  - resource type `business_concept` renamed to `concept` for events from
    service `td_lm`

### Removed

- [TD-2637] Removed routes:
  - `POST /api/audits`
  - `DELETE /api/events/:id`
  - `PATCH /api/events/:id`
  - `PUT /api/events/:id`

## [3.20.0] 2020-04-20

### Added

- [TD-2500] Support bulk subscription for all users with a role on existing
  business concepts. For example, to subscribe data owners to comment
  notifications on their business concepts:
  ```
  PATCH /api/subscriptions
  {
    "subscriptions": {
      "role": "data_owner",
      "event": "comment_created",
      "resource_type": "business_concept",
      "periodicity": "daily"
    }
  }
  ```

### Changed

- [TD-2508] Update to Elixir 1.10

## [3.8.0] 2019-10-14

### Changed

- [TD-1987] Change text in table header of Rule Notification email

## [3.5.1] 2019-09-03

### Fixed

- [TD-2081] Event stream consumer did not respect redis_host and port config
  options

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

- [TD-1660] Will only update business concept link_count on
  add_relation/delete_relation event if "target_type" is "data_field"
- Update to phoenix 1.4, ecto 3.0, exq 0.13, redix 0.8.2

## [2.16.0] 2019-04-01

### Added

- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to
  override format

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
